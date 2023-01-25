# This creates a network load balancer listening on port 80 with a target of the internal ALB.

resource "aws_lb" "ingress-network-lb" {
  name                       = "${local.application_name}-${local.environment}-nlb"
  internal                   = true
  load_balancer_type         = "network"
  subnets                    = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  enable_deletion_protection = true
  tags = {
    Name = "${local.application_name}-${local.environment}-ingress-network-lb"
  }
}

resource "aws_lb_listener" "lz-ingress" {
  load_balancer_arn = aws_lb.ingress-network-lb.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb-target.arn
  }
  tags = {
    Name = "${local.application_name}-${local.environment}-lz-ingress"
  }
}

resource "aws_lb_target_group" "nlb-target" {
  name        = "${local.application_name}-${local.environment}-nlb-tg"
  target_type = "alb"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.shared.id
  tags = {
    Name = "${local.application_name}-${local.environment}-nlb-tg"
  }
}


resource "aws_lb_target_group_attachment" "nlb-target-attachment" {
  target_group_arn = aws_lb_target_group.nlb-target.arn
  target_id        = module.alb.load_balancer.id
}


