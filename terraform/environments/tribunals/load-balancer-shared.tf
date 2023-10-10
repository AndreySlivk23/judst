# resource "aws_security_group" "tribunals_lb_sc" {
#   name        = "load balancer security group"
#   description = "control access to the load balancer"
#   vpc_id      = data.aws_vpc.shared.id

#   ingress {
#     description = "allow access on HTTPS for the MOJ VPN"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [local.application_data.accounts[local.environment].moj_ip]
#   }

#   // Allow MGB dev access to port 443 of the LB
#   ingress {
#     from_port = 443
#     to_port   = 443
#     protocol  = "tcp"
#     cidr_blocks = [
#       "87.74.249.131/32"
#     ]
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

# resource "aws_security_group" "tribunals_lb_sc_pingdom" {
#   name        = "load balancer Pingdom security group"
#   description = "control Pingdom access to the load balancer"
#   vpc_id      = data.aws_vpc.shared.id

#   // Allow all European Pingdom IP addresses
#   ingress {
#     from_port = 443
#     to_port   = 443
#     protocol  = "tcp"
#     cidr_blocks = [
#       "178.255.152.2/32",
#       "185.180.12.65/32",
#       "185.152.65.167/32",
#       "82.103.139.165/32",
#       "82.103.136.16/32",
#       "196.244.191.18/32",
#       "151.106.52.134/32",
#       "185.136.156.82/32",
#       "169.51.2.18/32",
#       "46.20.45.18/32",
#       "89.163.146.247/32",
#       "89.163.242.206/32",
#       "52.59.46.112/32",
#       "52.59.147.246/32",
#       "52.57.132.90/32",
#       "82.103.145.126/32",
#       "85.195.116.134/32",
#       "178.162.206.244/32",
#       "5.172.196.188/32",
#       "185.70.76.23/32",
#       "37.252.231.50/32",
#       "52.209.34.226/32",
#       "52.209.186.226/32",
#       "52.210.232.124/32",
#       "52.48.244.35/32",
#       "23.92.127.2/32",
#       "159.122.168.9/32",
#       "94.75.211.73/32",
#       "94.75.211.74/32",
#       "185.246.208.82/32",
#       "185.93.3.65/32",
#       "108.181.70.3/32",
#       "94.247.174.83/32",
#       "185.39.146.215/32",
#       "185.39.146.214/32",
#       "178.255.153.2/32",
#       "23.106.37.99/32",
#       "212.78.83.16/32",
#       "212.78.83.12/32"
#     ]
#   }
# }

# //noinspection HILUnresolvedReference
# resource "aws_lb" "tribunals_lb" {
#   name                       = "tribunals-load-balancer"
#   load_balancer_type         = "application"
#   security_groups            = [aws_security_group.tribunals_lb_sc.id, aws_security_group.tribunals_lb_sc_pingdom.id]
#   subnets                    = data.aws_subnets.shared-public.ids
#   enable_deletion_protection = false
#   internal                   = false
#   depends_on                 = [aws_security_group.tribunals_lb_sc, aws_security_group.tribunals_lb_sc_pingdom]
# }

# resource "aws_lb_target_group" "tribunals_target_group" {
#   name                 = "tribunals-target-group"
#   port                 = 80
#   protocol             = "HTTP"
#   vpc_id               = data.aws_vpc.shared.id
#   target_type          = "ip"
#   deregistration_delay = 30

#   stickiness {
#     type = "lb_cookie"
#   }

#   health_check {
#     healthy_threshold   = "3"
#     interval            = "15"
#     protocol            = "HTTP"
#     port                = "80"
#     unhealthy_threshold = "3"
#     matcher             = "200-302"
#     timeout             = "5"
#   }

# }

# resource "aws_lb_listener" "tribunals_lb" {
#   depends_on = [
#     aws_acm_certificate.appeals_external
#   ]
#   certificate_arn   = aws_acm_certificate.appeals_external.arn
#   load_balancer_arn = aws_lb.tribunals_lb.arn
#   port              = local.application_data.accounts[local.environment].server_port_2
#   protocol          = local.application_data.accounts[local.environment].lb_listener_protocol_2
#   ssl_policy        = local.application_data.accounts[local.environment].lb_listener_protocol_2 == "HTTP" ? "" : "ELBSecurityPolicy-2016-08"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.tribunals_target_group.arn
#   }
# }
