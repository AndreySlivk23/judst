#Finance and Tax Tribunal (First Tier)
locals {
  ftt = "ftt" 
  ftt_url = "financeandtax"
  ftt_folder = "finance_and_tax"
  ftt_db_name = "ftt" 
  ftt_db_login_name = "ftt-app"
  ftt_source_db_name = "ftt"
  ftt_rds_url               = "${aws_db_instance.rdsdb.address}"      
  ftt_rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
  ftt_rds_port              = "1433"
  ftt_rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
  ftt_source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
  ftt_source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
  ftt_source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
}

######################## DMS #############################################

module "ftt_dms" {
  source                      = "./modules/dms"
  replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
  replication_task_id         = "${local.ftt}-migration-task"
  #target_db_instance          = 0
  target_endpoint_id          = "${local.ftt}-target"
  target_database_name        = local.ftt_db_name
  target_server_name          = local.ftt_rds_url
  target_username             = local.ftt_rds_user
  target_password             = local.ftt_rds_password
  source_endpoint_id          = "${local.ftt}-source"
  source_database_name        = local.ftt_source_db_name
  source_server_name          = local.ftt_source_db_url
  source_username             = local.ftt_source_db_user
  source_password             = local.ftt_source_db_password
 
}

############################################################################

resource "random_password" "ftt_new_password" {
  length  = 16
  special = false 
}

resource "null_resource" "ftt_setup_db" {
 
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "ifconfig -a; chmod +x ./setup-mssql.sh; ./setup-mssql.sh"

    environment = {
      DB_URL = local.ftt_rds_url   
      USER_NAME = local.ftt_rds_user
      PASSWORD = local.ftt_rds_password
      NEW_DB_NAME = local.ftt_db_name
      NEW_USER_NAME = local.ftt_db_login_name
      NEW_PASSWORD = random_password.ftt_new_password.result
      APP_FOLDER = local.ftt_folder
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

 resource "aws_secretsmanager_secret" "ftt_db_credentials" {
  name = "${local.ftt}-db-credentials"
}

resource "aws_secretsmanager_secret_version" "ftt_db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.ftt_db_credentials.id
  secret_string = <<EOF
{
  "username": "${local.ftt_db_login_name}",
  "password": "${random_password.ftt_new_password.result}",  
  "host": "${local.ftt_rds_url}",  
  "database_name": "${local.ftt_db_name}"
}
EOF
}

####################### DNS #########################################

// ACM Public Certificate
resource "aws_acm_certificate" "ftt_external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["${local.ftt_url}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "ftt_external" {
  certificate_arn         = aws_acm_certificate.ftt_external.arn
  validation_record_fqdns = [local.ftt_domain_name_main[0], local.ftt_domain_name_sub[0]]
}

// Route53 DNS records for certificate validation
resource "aws_route53_record" "ftt_external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.ftt_domain_name_main[0]
  records         = local.ftt_domain_record_main
  ttl             = 60
  type            = local.ftt_domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "ftt_external_validation_subdomain" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.ftt_domain_name_sub[0]
  records         = local.ftt_domain_record_sub
  ttl             = 60
  type            = local.ftt_domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

// Route53 DNS record for directing traffic to the service
resource "aws_route53_record" "ftt_external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${local.ftt_url}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.ftt_lb.dns_name
    zone_id                = aws_lb.ftt_lb.zone_id
    evaluate_target_health = true
  }
}

// PRODUCTION DNS CONFIGURATION

// ACM Public Certificate
# resource "aws_acm_certificate" "ftt_external_prod" {
#   count = local.is-production ? 1 : 0

#   domain_name       = "${local.ftt}.service.justice.gov.uk"
#   validation_method = "DNS"
#   lifecycle {
#     crftte_before_destroy = true
#   }
# }

# resource "aws_acm_certificate_validation" "ftt_external_prod" {
#   count = local.is-production ? 1 : 0

#   certificate_arn         = aws_acm_certificate.ftt_external_prod[0].arn
#   validation_record_fqdns = [aws_route53_record.ftt_external_validation_prod[0].fqdn]
#   timeouts {
#     crftte = "10m"
#   }
# }

// Route53 DNS record for certificate validation
# resource "aws_route53_record" "ftt_external_validation_prod" {
#   count    = local.is-production ? 1 : 0
#   provider = aws.core-network-services

#   allow_overwrite = true
#   name            = tolist(aws_acm_certificate.ftt_external_prod[0].domain_validation_options)[0].resource_record_name
#   records         = [tolist(aws_acm_certificate.ftt_external_prod[0].domain_validation_options)[0].resource_record_value]
#   type            = tolist(aws_acm_certificate.ftt_external_prod[0].domain_validation_options)[0].resource_record_type
#   zone_id         = data.aws_route53_zone.application_zone.zone_id
#   ttl             = 60
# }

// Route53 DNS record for directing traffic to the service
# resource "aws_route53_record" "ftt_external_prod" {
#   count    = local.is-production ? 1 : 0
#   provider = aws.core-network-services

#   zone_id = data.aws_route53_zone.application_zone.zone_id
#   name    = "${local.ftt}.service.justice.gov.uk"
#   type    = "A"

#   alias {
#     name                   = aws_lb.ftt_lb.dns_name
#     zone_id                = aws_lb.ftt_lb.zone_id
#     evaluate_target_health = true
#   }
# }

####################### ECS #########################################

resource "aws_ecs_cluster" "ftt_cluster" {
  name = "${local.ftt}_app_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "fttFamily_logs" {
  name = "/ecs/${local.ftt}Family"
}

resource "aws_ecs_task_definition" "ftt_task_definition" {
  family                   = "${local.ftt}Family"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ftt_execution.arn
  task_role_arn            = aws_iam_role.ftt_task.arn
  cpu                      = 1024
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name      = "${local.ftt}-container"
      image     = "mcr.microsoft.com/dotnet/framework/aspnet:4.8"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "${aws_cloudwatch_log_group.fttFamily_logs.name}"
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        {
          name  = "RDS_HOSTNAME"
          value = "${local.ftt_rds_url}"
        },
        {
          name  = "RDS_PORT"
          value = "${local.ftt_rds_port}"
        },
        {
          name  = "RDS_USERNAME"
          value = "${local.ftt_rds_user}"
        },
        {
          name  = "RDS_PASSWORD"
          value = "${local.ftt_rds_password}"
        },
        {
          name  = "DB_NAME"
          value = "${local.ftt_db_name}"
        },
        {
          name  = "supportEmail"
          value = "${local.application_data.accounts[local.environment].support_email}"
        },
        {
          name  = "supportTeam"
          value = "${local.application_data.accounts[local.environment].support_team}"
        },
        {
          name  = "CurServer"
          value = "${local.application_data.accounts[local.environment].curserver}"
        }#,
        # {
        #   name  = "ida:ClientId"
        #   value = "${local.application_data.accounts[local.environment].client_id}"
        # }
      ]
    }
  ])
  runtime_platform {
    operating_system_family = "WINDOWS_SERVER_2019_CORE"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "ftt_ecs_service" {
  depends_on = [
    aws_lb_listener.ftt_lb
  ]

  name                              = local.ftt
  cluster                           = aws_ecs_cluster.ftt_cluster.id
  task_definition                   = aws_ecs_task_definition.ftt_task_definition.arn
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  desired_count                     = 1
  health_check_grace_period_seconds = 90

  network_configuration {
    subnets          = data.aws_subnets.shared-public.ids
    security_groups  = [aws_security_group.ftt_ecs_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ftt_target_group.arn
    container_name   = "${local.ftt}-container"
    container_port   = 80
  }

  deployment_controller {
    type = "ECS"
  }
}

resource "aws_iam_role" "ftt_execution" {
  name = "execution-${local.ftt}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "execution-${local.ftt}"
    },
  )
}

resource "aws_iam_role_policy" "ftt_execution" {
  name = "execution-${local.ftt}"
  role = aws_iam_role.ftt_execution.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
           "Action": [
              "ecr:*",
              "logs:CrftteLogStream",
              "logs:PutLogEvents",
              "secretsmanager:GetSecretValue"
           ],
           "Resource": "*",
           "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "ftt_task" {
  name = "task-${local.ftt}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "task-${local.ftt}"
    },
  )
}

resource "aws_iam_role_policy" "ftt_task" {
  name = "task-${local.ftt}"
  role = aws_iam_role.ftt_task.id

  policy = <<-EOF
  {
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
        "Action": [
          "logs:CrftteLogStream",
          "logs:PutLogEvents",
          "ecr:*",
          "iam:*",
          "ec2:*"
        ],
       "Resource": "*"
     }
   ]
  }
  EOF
}

resource "aws_security_group" "ftt_ecs_service" {
  name_prefix = "ecs-service-sg-"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    description     = "Allow traffic on port 80 from load balancer"
    security_groups = [aws_security_group.ftt_lb_sc.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "ftt-ecr-repo" {
  name         = "${local.ftt}-ecr-repo"
  force_delete = true
}

####################### LOAD BALANCER #########################################
resource "aws_security_group" "ftt_lb_sc" {
  name        = "${local.ftt} load balancer security group"
  description = "control access to the ${local.ftt} load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTPS for the MOJ VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.application_data.accounts[local.environment].moj_ip]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic for port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outbound traffic for port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "ftt_lb" {
  name                       = "${local.ftt}-load-balancer"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.ftt_lb_sc.id]
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = false
  internal                   = false
  depends_on                 = [aws_security_group.ftt_lb_sc]
}

resource "aws_lb_target_group" "ftt_target_group" {
  name                 = "${local.ftt}-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    healthy_threshold   = "3"
    interval            = "15"
    protocol            = "HTTP"
    port                = "80"
    unhealthy_threshold = "3"
    matcher             = "200-302"
    timeout             = "5"
  }

}

resource "aws_lb_listener" "ftt_lb" {
  depends_on = [
    aws_acm_certificate.ftt_external
  ]
  certificate_arn   = aws_acm_certificate.ftt_external.arn
  #certificate_arn   = local.is-production ? aws_acm_certificate.ftt_external_prod[0].arn : aws_acm_certificate.ftt_external.arn
  load_balancer_arn = aws_lb.ftt_lb.arn
  port              = local.application_data.accounts[local.environment].server_port_2
  protocol          = local.application_data.accounts[local.environment].lb_listener_protocol_2
  ssl_policy        = local.application_data.accounts[local.environment].lb_listener_protocol_2 == "HTTP" ? "" : "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ftt_target_group.arn
  }
}
