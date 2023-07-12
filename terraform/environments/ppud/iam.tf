
##########################################
# IAM Policy, Role, Profile for SSM and S3
##########################################

# IAM EC2 Policy with Assume Role 

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

/*
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:root"]
   }
 }
}

*/

# Create EC2 IAM Role
resource "aws_iam_role" "ec2_iam_role" {
  name               = "ec2-iam-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}


/*
 resource "aws_iam_role" "ec2_iam_role" {
  name = "ec2_iam_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": [
            "arn:aws:iam::${local.environment_management.account_ids["ppud-production"]}:root"
          ]
        },
        "Action": "sts:AssumeRole"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "type": "Service"
          "identifiers": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

*/

# Create EC2 IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_iam_role.name
}

# Attach Policies to Instance Role
resource "aws_iam_policy_attachment" "ec2_attach1" {
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy_attachment" "ec2_attach2" {
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_policy_attachment" "ec2_attach3" {
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_policy_attachment" "linux-patching" {
  count      = local.is-production == true ? 1 : 0
  depends_on = [aws_iam_policy.linux-patching]
  name       = "ec2-iam-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = aws_iam_policy.linux-patching[0].arn
}

resource "aws_iam_policy_attachment" "production-s3-access" {
  count      = local.is-production == false ? 1 : 0
  depends_on = [aws_iam_policy.production-s3-access]
  name       = "dev-s3-access-attachment"
  roles      = [aws_iam_role.ec2_iam_role.id]
  policy_arn = aws_iam_policy.production-s3-access[0].arn
}


#####################################
# IAM Policy for Prodcution S3 access
#####################################

resource "aws_iam_policy" "production-s3-access" {
  count      = local.is-production == false ? 1 : 0
  name        = "production-s3-access"
  path        = "/"
  description = "production-s3-access"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "s3:ListBucket",
    "Effect": "Allow",
    "Resource": [
       "arn:aws:s3:::moj-powershell-scripts",
       "arn:aws:s3:::moj-powershell-scripts/*",
       "arn:aws:s3:::moj-release-management",
       "arn:aws:s3:::moj-release-management/*"
    ]
  }]
})
}

#################################
# IAM Role for SSM Patch Manager
#################################

resource "aws_iam_role" "patching_role" {
  name = "maintenance_window_task_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ssm.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach necessary policies to the Patching role
resource "aws_iam_role_policy_attachment" "maintenance_window_task_policy_attachment" {
  role       = aws_iam_role.patching_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}


####################################################
# IAM Policy for Private Subnet Linux host patching
###################################################

resource "aws_iam_policy" "linux-patching" {
  count      = local.is-production == true ? 1 : 0
  name        = "linux-patching"
  path        = "/"
  description = "linux-patching"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": [
                "arn:aws:s3:::aws-windows-downloads-eu-west-2/*",
                "arn:aws:s3:::amazon-ssm-eu-west-2/*",
                "arn:aws:s3:::amazon-ssm-packages-eu-west-2/*",
                "arn:aws:s3:::eu-west-2-birdwatcher-prod/*",
                "arn:aws:s3:::aws-ssm-document-attachments-eu-west-2/*",
                "arn:aws:s3:::patch-baseline-snapshot-eu-west-2/*",
                "arn:aws:s3:::aws-ssm-eu-west-2/*",
                "arn:aws:s3:::aws-patchmanager-macos-eu-west-2/*"
            ]
        }
    ]
 })
}