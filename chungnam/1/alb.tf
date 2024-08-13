resource "aws_alb" "main" {
  name            = "wsc2024-alb"
  security_groups = [aws_security_group.alb.id]
  subnets         = [aws_subnet.prod-load-a.id, aws_subnet.prod-load-b.id]
}

resource "aws_security_group" "alb" {
  name        = "wsc2024-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.prod.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_security_group" "cluster" {
  id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "alb-allow-ip" {
  security_group_id            = data.aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_vpc_security_group_ingress_rule" "alb-allow-instance" {
  security_group_id            = data.aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 30000
  to_port                      = 32767
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = aws_alb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_alb_listener_rule" "customer" {
  listener_arn = aws_alb_listener.main.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.customer.arn
  }

  condition {
    path_pattern {
      values = ["/v1/customer"]
    }
  }
}

resource "aws_alb_target_group" "customer" {
  name                 = "wsc2024-customer-tg"
  port                 = "8080"
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.prod.id
  deregistration_delay = 60

  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener_rule" "product" {
  listener_arn = aws_alb_listener.main.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.product.arn
  }

  condition {
    path_pattern {
      values = ["/v1/product"]
    }
  }
}

resource "aws_alb_target_group" "product" {
  name                 = "wsc2024-product-tg"
  port                 = "8080"
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.prod.id
  deregistration_delay = 60

  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener_rule" "order" {
  listener_arn = aws_alb_listener.main.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.order.arn
  }

  condition {
    path_pattern {
      values = ["/v1/order"]
    }
  }
}

resource "aws_alb_target_group" "order" {
  name                 = "wsc2024-order-tg"
  port                 = "8080"
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.prod.id
  deregistration_delay = 60

  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener_rule" "healthcheck" {
  listener_arn = aws_alb_listener.main.arn
  priority     = 30

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_alb_target_group.customer.arn
      }
      target_group {
        arn = aws_alb_target_group.product.arn
      }
      target_group {
        arn = aws_alb_target_group.order.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/healthcheck"]
    }
  }
}