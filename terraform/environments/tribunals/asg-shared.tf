locals {
  app_name                  = "tribunals-shared"
  instance_role_name        = join("-", [local.app_name, "ec2-instance-role"])
  instance_profile_name     = join("-", [local.app_name, "ec2-instance-profile"])
  ec2_instance_policy       = join("-", [local.app_name, "ec2-instance-policy"])
  tags_common               = local.tags
}

# Create an IAM policy for the custom permissions required by the EC2 hosting instance
resource "aws_iam_policy" "ec2_instance_policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = local.ec2_instance_policy
  tags = merge(
  local.tags_common,
  {
    Name = local.ec2_instance_policy
  }
  )
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DetachVolume",
                "ec2:AttachVolume",
                "ec2:DescribeVolumes",
                "ec2:DescribeTags",
                "ec2:DescribeInstances",
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState",
                "ecs:Submit*",
                "ecs:TagResource",
                "ecr:*",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup",
                "logs:DescribeLogStreams",
                "s3:ListBucket",
                "s3:*Object*",
                "kms:Decrypt",
                "kms:Encrypt",
                "kms:GenerateDataKey",
                "kms:ReEncrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey",
                "xray:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ecs:TagResource",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ecs:CreateAction": [
                        "CreateCluster",
                        "RegisterContainerInstance"
                    ]
                }
            }
        }
    ]
}
EOF
}

# Create the IAM role to which the custom and predefined policies will be attached
# The role will be added to the ec2 instance profile which is added to the launch template
resource "aws_iam_role" "ec2_instance_role" {
  name = local.instance_role_name
  tags = merge(
  local.tags,
  {
    Name = local.instance_role_name
  }
  )
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# Attach the custom policy and predefined policies to the role
resource "aws_iam_role_policy_attachment" "ec2_policy_instance_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2_policy_ssm_core" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_policy_cloudwatch" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create the Instance profile for the role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = local.instance_profile_name
  role = aws_iam_role.ec2_instance_role.name
  tags = merge(
  local.tags_common,
  {
    Name = local.instance_profile_name
  }
  )
}

# Create the Launch Template and assign the instance profile
resource "aws_launch_template" "tribunals-all-lt" {
  name_prefix   = "tribunals-all"
  image_id      = "ami-0d20b6fc5007adcb3"
  instance_type = "m5.large"
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 80
      volume_type = "gp2"
    }
  }
  ebs_optimized = true

  network_interfaces {
    device_index                = 0
    security_groups             = [aws_security_group.cluster_ec2.id]#[aws_security_group.tribunals_lb_sc.id]
    subnet_id                   = data.aws_subnet.public_subnets_a.id
    delete_on_termination       = true
  }

  user_data = filebase64("ec2-shared-user-data.sh")
}

# Finally, create the Auto scaling group for the launch template
resource "aws_autoscaling_group" "tribunals-all-asg" {
  #vpc_zone_identifier = sort(data.aws_subnets.shared-private.ids)
  vpc_zone_identifier = [data.aws_subnet.private_subnets_a.id]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  name               = local.app_name

  launch_template {
    id      = "${aws_launch_template.tribunals-all-lt.id}"
    version = "$Latest"
  }
}

###########################################################################


# EC2 Security Group
# Controls access to the EC2 instances

resource "aws_security_group" "cluster_ec2" {
  #checkov:skip=CKV_AWS_23
  name        = "tribunals-cluster-ec2-security-group"
  description = "controls access to the cluster ec2 instance"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "Cluster EC2 ingress rule"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [module.ecs_loadbalancer.tribunals_lb_sc_id]
  }

  ingress {
    protocol    = "tcp"
    description = "Allow traffic from bastion"
    from_port   = 0
    to_port     = 0
    security_groups = [
      module.bastion_linux.bastion_security_group
    ]
  }

  egress {
    description = "Cluster EC2 loadbalancer egress rule"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  tags = merge(
    local.tags_common,
    {
      Name = "tribunals-cluster-ec2-security-group"
    }
  )
}