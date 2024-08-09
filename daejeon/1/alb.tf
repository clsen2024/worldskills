# ap-northeast-2
resource "aws_alb" "ap" {
  name            = "hrdkorea-app-alb"
  security_groups = [aws_security_group.ap-alb.id]
  subnets         = [aws_subnet.ap-public-a.id, aws_subnet.ap-public-b.id]
}

resource "aws_security_group" "ap-alb" {
  name        = "hrdkorea-app-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.ap.id

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

data "aws_security_group" "ap-cluster" {
  id = aws_eks_cluster.ap.vpc_config[0].cluster_security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "ap-alb-allow-instance" {
  security_group_id            = data.aws_security_group.ap-cluster.id
  referenced_security_group_id = aws_security_group.ap-alb.id
  ip_protocol                  = "tcp"
  from_port                    = 30000
  to_port                      = 32767
}

resource "aws_alb_listener" "ap" {
  load_balancer_arn = aws_alb.ap.arn
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

resource "aws_alb_listener_rule" "ap-customer" {
  listener_arn = aws_alb_listener.ap.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ap-customer.arn
  }

  condition {
    path_pattern {
      values = ["/v1/customer"]
    }
  }
}

resource "aws_alb_target_group" "ap-customer" {
  name                 = "hrdkorea-customer-tg"
  port                 = "8080"
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.ap.id
  deregistration_delay = 60

  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener_rule" "ap-product" {
  listener_arn = aws_alb_listener.ap.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ap-product.arn
  }

  condition {
    path_pattern {
      values = ["/v1/product"]
    }
  }
}

resource "aws_alb_target_group" "ap-product" {
  name                 = "hrdkorea-product-tg"
  port                 = "8080"
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.ap.id
  deregistration_delay = 60

  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener_rule" "ap-order" {
  listener_arn = aws_alb_listener.ap.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ap-order.arn
  }

  condition {
    path_pattern {
      values = ["/v1/order"]
    }
  }
}

resource "aws_alb_target_group" "ap-order" {
  name                 = "hrdkorea-order-tg"
  port                 = "8080"
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.ap.id
  deregistration_delay = 60

  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener_rule" "ap-customer-health" {
  listener_arn = aws_alb_listener.ap.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ap-customer.arn
  }

  condition {
    path_pattern {
      values = ["/healthcheck"]
    }
  }

  condition {
    query_string {
      key   = "path"
      value = "customer"
    }
  }
}

resource "aws_alb_listener_rule" "ap-product-health" {
  listener_arn = aws_alb_listener.ap.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ap-product.arn
  }

  condition {
    path_pattern {
      values = ["/healthcheck"]
    }
  }

  condition {
    query_string {
      key   = "path"
      value = "product"
    }
  }
}

resource "aws_alb_listener_rule" "ap-order-health" {
  listener_arn = aws_alb_listener.ap.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ap-order.arn
  }

  condition {
    path_pattern {
      values = ["/healthcheck"]
    }
  }

  condition {
    query_string {
      key   = "path"
      value = "order"
    }
  }
}

# us-east-1
resource "aws_alb" "us" {
  provider = aws.us-east-1

  name            = "hrdkorea-app-alb"
  security_groups = [aws_security_group.us-alb.id]
  subnets         = [aws_subnet.us-public-a.id, aws_subnet.us-public-b.id]
}

resource "aws_security_group" "us-alb" {
  provider = aws.us-east-1

  name        = "hrdkorea-app-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.us.id

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

data "aws_security_group" "us-cluster" {
  provider = aws.us-east-1

  id = aws_eks_cluster.us.vpc_config[0].cluster_security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "us-alb-allow-instance" {
  provider = aws.us-east-1

  security_group_id            = data.aws_security_group.us-cluster.id
  referenced_security_group_id = aws_security_group.us-alb.id
  ip_protocol                  = "tcp"
  from_port                    = 30000
  to_port                      = 32767
}

resource "aws_alb_listener" "us" {
  provider = aws.us-east-1

  load_balancer_arn = aws_alb.us.arn
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

resource "aws_alb_listener_rule" "us-customer" {
  provider = aws.us-east-1

  listener_arn = aws_alb_listener.us.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.us-customer.arn
  }

  condition {
    path_pattern {
      values = ["/v1/customer"]
    }
  }
}

resource "aws_alb_target_group" "us-customer" {
  provider = aws.us-east-1

  name                 = "hrdkorea-customer-tg"
  port                 = "8080"
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.us.id
  deregistration_delay = 60

  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener_rule" "us-product" {
  provider = aws.us-east-1

  listener_arn = aws_alb_listener.us.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.us-product.arn
  }

  condition {
    path_pattern {
      values = ["/v1/product"]
    }
  }
}

resource "aws_alb_target_group" "us-product" {
  provider = aws.us-east-1

  name                 = "hrdkorea-product-tg"
  port                 = "8080"
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.us.id
  deregistration_delay = 60

  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener_rule" "us-order" {
  provider = aws.us-east-1

  listener_arn = aws_alb_listener.us.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.us-order.arn
  }

  condition {
    path_pattern {
      values = ["/v1/order"]
    }
  }
}

resource "aws_alb_target_group" "us-order" {
  provider = aws.us-east-1

  name                 = "hrdkorea-order-tg"
  port                 = "8080"
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.us.id
  deregistration_delay = 60

  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener_rule" "us-customer-health" {
  provider = aws.us-east-1

  listener_arn = aws_alb_listener.us.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.us-customer.arn
  }

  condition {
    path_pattern {
      values = ["/healthcheck"]
    }
  }

  condition {
    query_string {
      key   = "path"
      value = "customer"
    }
  }
}

resource "aws_alb_listener_rule" "us-product-health" {
  provider = aws.us-east-1

  listener_arn = aws_alb_listener.us.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.us-product.arn
  }

  condition {
    path_pattern {
      values = ["/healthcheck"]
    }
  }

  condition {
    query_string {
      key   = "path"
      value = "product"
    }
  }
}

resource "aws_alb_listener_rule" "us-order-health" {
  provider = aws.us-east-1

  listener_arn = aws_alb_listener.us.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.us-order.arn
  }

  condition {
    path_pattern {
      values = ["/healthcheck"]
    }
  }

  condition {
    query_string {
      key   = "path"
      value = "order"
    }
  }
}