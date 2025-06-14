locals {
  alb_ports_in = [443, 80]
}

resource "aws_security_group" "alb" {
  name   = "${var.app_name}-${var.env_name}-alg-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = toset(local.alb_ports_in)

    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_lb" "main" {
  name               = "${var.app_name}-${var.env_name}-alb"
  load_balancer_type = "application"
  idle_timeout       = 180

  subnets = var.public_subnet_ids

  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "main" {
  name   = "${var.app_name}-${var.env_name}-alb-main-tg"
  vpc_id = var.vpc_id

  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    port = var.target_health_check_port
    path = var.target_health_check_path
  }
}

resource "aws_lb_listener" "main" {
  port              = 80
  protocol          = "HTTP"
  load_balancer_arn = aws_lb.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.id
  }
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.main.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    query_string {
      value = "*"
    }
  }
}
