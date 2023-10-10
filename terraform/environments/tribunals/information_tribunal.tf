# #Information Rights Tribunal
# locals {
#   it = "it" 
#   it_url = "informationrights"
#   it_folder = "information_tribunal"
#   it_db_name = "it" 
#   it_db_login_name = "it-app"
#   it_source_db_name = "IT"
#   it_rds_url               = "${aws_db_instance.rdsdb.address}"      
#   it_rds_user              = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
#   it_rds_port              = "1433"
#   it_rds_password          = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
#   it_source_db_url         = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["host"]
#   it_source_db_user        = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["username"]
#   it_source_db_password    = jsondecode(data.aws_secretsmanager_secret_version.source_db_secret_current.secret_string)["password"]
#   it_user_data = base64encode(templatefile("user_data.sh", {
#     cluster_name = "${local.it}_app_cluster"
#   }))
#   it_task_definition = templatefile("task_definition.json", {
#     app_name            = "${local.it}"
#     #ecr_url             = "mcr.microsoft.com/dotnet/framework/aspnet:4.8"
#     #docker_image_tag    = "latest" 
#     #sentry_env          = local.environment
#     awslogs-group       = "${local.it}-ecs-log-group"
#     supportEmail        = "${local.application_data.accounts[local.environment].support_email}"
#     supportTeam         = "${local.application_data.accounts[local.environment].support_team}"
#     CurServer           = "${local.application_data.accounts[local.environment].curserver}"

#   })
#   it_ec2_ingress_rules = {   
#     "cluster_ec2_lb_ingress_2" = {
#       description     = "Cluster EC2 ingress rule 2"
#       from_port       = 0
#       to_port         = 0
#       protocol        = "-1"
#       cidr_blocks     = ["0.0.0.0/0"]
#       security_groups = []
#     }
#   }
#   it_ec2_egress_rules = {
#     "cluster_ec2_lb_egress" = {
#       description     = "Cluster EC2 loadbalancer egress rule"
#       from_port       = 0
#       to_port         = 0
#       protocol        = "-1"
#       cidr_blocks     = ["0.0.0.0/0"]
#       security_groups = []
#     }
#   }
# }

# ######################## DMS #############################################

# module "it_dms" {
#   source                      = "./modules/dms"
#   replication_instance_arn    = aws_dms_replication_instance.tribunals_replication_instance.replication_instance_arn
#   replication_task_id         = "${local.it}-migration-task"
#   #target_db_instance          = 0
#   target_endpoint_id          = "${local.it}-target"
#   target_database_name        = local.it_db_name
#   target_server_name          = local.it_rds_url
#   target_username             = local.it_rds_user
#   target_password             = local.it_rds_password
#   source_endpoint_id          = "${local.it}-source"
#   source_database_name        = local.it_source_db_name
#   source_server_name          = local.it_source_db_url
#   source_username             = local.it_source_db_user
#   source_password             = local.it_source_db_password
 
# }

# ############################################################################

# resource "random_password" "it_new_password" {
#   length  = 16
#   special = false 
# }

# resource "null_resource" "it_setup_db" {
 
#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command     = "ifconfig -a; chmod +x ./setup-mssql.sh; ./setup-mssql.sh"

#     environment = {
#       DB_URL = local.it_rds_url   
#       USER_NAME = local.it_rds_user
#       PASSWORD = local.it_rds_password
#       NEW_DB_NAME = local.it_db_name
#       NEW_USER_NAME = local.it_db_login_name
#       NEW_PASSWORD = random_password.it_new_password.result
#       APP_FOLDER = local.it_folder
#     }
#   }
#   triggers = {
#     always_run = "${timestamp()}"
#   }
# }

#  resource "aws_secretsmanager_secret" "it_db_credentials" {
#   name = "${local.it}-db-credentials"
# }

# resource "aws_secretsmanager_secret_version" "it_db_credentials_version" {
#   secret_id     = aws_secretsmanager_secret.it_db_credentials.id
#   secret_string = <<EOF
# {
#   "username": "${local.it_db_login_name}",
#   "password": "${random_password.it_new_password.result}",  
#   "host": "${local.it_rds_url}",  
#   "database_name": "${local.it_db_name}"
# }
# EOF
# }

# ####################### DNS #########################################

# // ACM Public Certificate
# resource "aws_acm_certificate" "it_external" {
#   domain_name       = "modernisation-platform.service.justice.gov.uk"
#   validation_method = "DNS"

#   subject_alternative_names = ["${local.it_url}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
#   tags = {
#     Environment = local.environment
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_acm_certificate_validation" "it_external" {
#   certificate_arn         = aws_acm_certificate.it_external.arn
#   validation_record_fqdns = [local.it_domain_name_main[0], local.it_domain_name_sub[0]]
# }

# // Route53 DNS records for certificate validation
# resource "aws_route53_record" "it_external_validation" {
#   provider = aws.core-network-services

#   allow_overwrite = true
#   name            = local.it_domain_name_main[0]
#   records         = local.it_domain_record_main
#   ttl             = 60
#   type            = local.it_domain_type_main[0]
#   zone_id         = data.aws_route53_zone.network-services.zone_id
# }

# resource "aws_route53_record" "it_external_validation_subdomain" {
#   provider = aws.core-vpc

#   allow_overwrite = true
#   name            = local.it_domain_name_sub[0]
#   records         = local.it_domain_record_sub
#   ttl             = 60
#   type            = local.it_domain_type_sub[0]
#   zone_id         = data.aws_route53_zone.external.zone_id
# }

# // Route53 DNS record for directing traffic to the service
# resource "aws_route53_record" "it_external" {
#   provider = aws.core-vpc

#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = "${local.it_url}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"

#   alias {
#     name                   = aws_lb.it_lb.dns_name
#     zone_id                = aws_lb.it_lb.zone_id
#     evaluate_target_health = true
#   }
# }

# // PRODUCTION DNS CONFIGURATION

# // ACM Public Certificate
# # resource "aws_acm_certificate" "it_external_prod" {
# #   count = local.is-production ? 1 : 0

# #   domain_name       = "${local.it}.service.justice.gov.uk"
# #   validation_method = "DNS"
# #   lifecycle {
# #     create_before_destroy = true
# #   }
# # }

# # resource "aws_acm_certificate_validation" "it_external_prod" {
# #   count = local.is-production ? 1 : 0

# #   certificate_arn         = aws_acm_certificate.it_external_prod[0].arn
# #   validation_record_fqdns = [aws_route53_record.it_external_validation_prod[0].fqdn]
# #   timeouts {
# #     create = "10m"
# #   }
# # }

# // Route53 DNS record for certificate validation
# # resource "aws_route53_record" "it_external_validation_prod" {
# #   count    = local.is-production ? 1 : 0
# #   provider = aws.core-network-services

# #   allow_overwrite = true
# #   name            = tolist(aws_acm_certificate.it_external_prod[0].domain_validation_options)[0].resource_record_name
# #   records         = [tolist(aws_acm_certificate.it_external_prod[0].domain_validation_options)[0].resource_record_value]
# #   type            = tolist(aws_acm_certificate.it_external_prod[0].domain_validation_options)[0].resource_record_type
# #   zone_id         = data.aws_route53_zone.application_zone.zone_id
# #   ttl             = 60
# # }

# // Route53 DNS record for directing traffic to the service
# # resource "aws_route53_record" "it_external_prod" {
# #   count    = local.is-production ? 1 : 0
# #   provider = aws.core-network-services

# #   zone_id = data.aws_route53_zone.application_zone.zone_id
# #   name    = "${local.it}.service.justice.gov.uk"
# #   type    = "A"

# #   alias {
# #     name                   = aws_lb.it_lb.dns_name
# #     zone_id                = aws_lb.it_lb.zone_id
# #     evaluate_target_health = true
# #   }
# # }

# ####################### LOAD BALANCER #########################################
# resource "aws_security_group" "it_lb_sc" {
#   name        = "${local.it} load balancer security group"
#   description = "control access to the ${local.it} load balancer"
#   vpc_id      = data.aws_vpc.shared.id

#   ingress {
#     description = "allow access on HTTPS for the MOJ VPN"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [local.application_data.accounts[local.environment].moj_ip]
#   }

#   ingress {
#     from_port = 443
#     to_port   = 443
#     protocol  = "tcp"
#     cidr_blocks =  ["0.0.0.0/0"]
#   }

#   egress {
#     description = "allow all outbound traffic for port 80"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "allow all outbound traffic for port 443"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
  
# }

# resource "aws_lb" "it_lb" {
#   name                       = "${local.it}-load-balancer"
#   load_balancer_type         = "application"
#   security_groups            = [aws_security_group.it_lb_sc.id]
#   subnets                    = data.aws_subnets.shared-public.ids
#   enable_deletion_protection = false
#   internal                   = false
#   depends_on                 = [aws_security_group.it_lb_sc]
# }

# resource "aws_lb_target_group" "it_target_group" {
#   name                 = "${local.it}-target-group"
#   port                 = 80
#   protocol             = "HTTP"
#   vpc_id               = data.aws_vpc.shared.id
#   target_type          = "instance"
#   deregistration_delay = 30

#   stickiness {
#     type = "lb_cookie"
#   }

#   health_check {
#     healthy_threshold   = "2"
#     interval            = "120"
#     protocol            = "HTTP"
#     unhealthy_threshold = "2"
#     matcher             = "200-499"
#     timeout             = "10"
#   }

# }

# resource "aws_lb_listener" "it_lb" {
#   depends_on = [
#     aws_acm_certificate.it_external
#   ]
#   certificate_arn   = aws_acm_certificate.it_external.arn
#   #certificate_arn   = local.is-production ? aws_acm_certificate.it_external_prod[0].arn : aws_acm_certificate.it_external.arn
#   load_balancer_arn = aws_lb.it_lb.arn
#   port              = local.application_data.accounts[local.environment].server_port_2
#   protocol          = local.application_data.accounts[local.environment].lb_listener_protocol_2
#   ssl_policy        = local.application_data.accounts[local.environment].lb_listener_protocol_2 == "HTTP" ? "" : "ELBSecurityPolicy-2016-08"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.it_target_group.arn
#   }
# }

# ##### EFS #####
# # resource "aws_efs_file_system" "it_app_efs" {
# #   encrypted        = true
# #   kms_key_id       = data.aws_kms_key.ebs_shared.arn
# #   performance_mode = "generalPurpose"
# #   tags = merge(tomap({
# #     "Name"                 = "${local.it}-app-efs"
# #     "volume-attach-host"   = "app",
# #     "volume-attach-device" = "efs://",
# #     "volume-mount-path"    = "/opt/oem/backups"
# #   }), local.tags)
# # }

# # resource "aws_efs_mount_target" "it_app_efs" {
# #   file_system_id = aws_efs_file_system.it_app_efs.id
# #   subnet_id      = data.aws_subnet.data_subnets_a.id
# #   security_groups = [
# #     aws_security_group.it_app_efs_sg.id
# #   ]
# # }

# # resource "aws_security_group" "it_app_efs_sg" {
# #   name_prefix = "${local.it}-app-efs-sg-"
# #   description = "Allow inbound access from instances"
# #   vpc_id      = data.aws_vpc.shared.id

# #   tags = merge(tomap(
# #     { "Name" = "${local.it}-app-efs-sg" }
# #   ), local.tags)

# #   ingress {
# #     protocol    = "tcp"
# #     from_port   = 2049
# #     to_port     = 2049
# #     cidr_blocks = [data.aws_vpc.shared.cidr_block]
# #   }

# #   egress {
# #     protocol  = "-1"
# #     from_port = 0
# #     to_port   = 0
# #     cidr_blocks = [
# #       "0.0.0.0/0",
# #     ]
# #   }

# #   lifecycle {
# #     create_before_destroy = true
# #   }
# # }

# ####################### ECS #########################################

# module "it-ecs" {

#   source = "./modules/ecs"

#   subnet_set_name           = local.subnet_set_name
#   vpc_all                   = local.vpc_all
#   app_name                  = local.it
#   container_instance_type   = "windows"
#   ami_image_id              = local.application_data.accounts[local.environment].ami_image_id
#   instance_type             = local.application_data.accounts[local.environment].instance_type
#   user_data                 = local.it_user_data
#   key_name                  = ""
#   task_definition           = local.it_task_definition
#   ec2_desired_capacity      = local.application_data.accounts[local.environment].ec2_desired_capacity
#   ec2_max_size              = local.application_data.accounts[local.environment].ec2_max_size
#   ec2_min_size              = local.application_data.accounts[local.environment].ec2_min_size
#   task_definition_volume    = local.application_data.accounts[local.environment].task_definition_volume
#   network_mode              = local.application_data.accounts[local.environment].network_mode
#   server_port               = local.application_data.accounts[local.environment].server_port_1
#   app_count                 = local.application_data.accounts[local.environment].app_count
#   ec2_ingress_rules         = local.it_ec2_ingress_rules
#   ec2_egress_rules          = local.it_ec2_egress_rules
#   lb_tg_arn                 = aws_lb_target_group.it_target_group.arn
#   tags_common               = local.tags
#   appscaling_min_capacity   = local.application_data.accounts[local.environment].appscaling_min_capacity
#   appscaling_max_capacity   = local.application_data.accounts[local.environment].appscaling_max_capacity
#   ec2_scaling_cpu_threshold = local.application_data.accounts[local.environment].ec2_scaling_cpu_threshold
#   ec2_scaling_mem_threshold = local.application_data.accounts[local.environment].ec2_scaling_mem_threshold
#   ecs_scaling_cpu_threshold = local.application_data.accounts[local.environment].ecs_scaling_cpu_threshold
#   ecs_scaling_mem_threshold = local.application_data.accounts[local.environment].ecs_scaling_mem_threshold
#   //fsx_subnet_ids            = [data.aws_subnets.shared-public.ids[0]]
#   environment               = local.environment
#   //fsx_vpc_id                = data.aws_vpc.shared.id
#   lb_listener               = aws_lb_listener.it_lb
#   cluster_name              = aws_ecs_cluster.tribunals_cluster.name
# }

# resource "aws_ecr_repository" "it-ecr-repo" {
#   name         = "${local.it}-ecr-repo"
#   force_delete = true
# }

# # resource "aws_security_group" "it_ecs_service" {
# #   name_prefix = "ecs-service-sg-"
# #   vpc_id      = data.aws_vpc.shared.id

# #   ingress {
# #     from_port       = 80
# #     to_port         = 80
# #     protocol        = "tcp"
# #     description     = "Allow traffic on port 80 from load balancer"
# #     security_groups = [aws_security_group.it_lb_sc.id]
# #   }

# #   egress {
# #     from_port   = 0
# #     to_port     = 0
# #     protocol    = "-1"
# #     cidr_blocks = ["0.0.0.0/0"]
# #   }
# # }