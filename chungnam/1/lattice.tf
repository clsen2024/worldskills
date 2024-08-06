resource "aws_vpclattice_service_network" "main" {
  name      = "wsc2024-lattice-svc-net"
  auth_type = "NONE"
}

resource "aws_vpclattice_service" "main" {
  name      = "wsc2024-lattice-svc"
  auth_type = "NONE"
}

resource "aws_vpclattice_listener" "main" {
  name               = "wsc2024-lattice-listener"
  protocol           = "HTTP"
  service_identifier = aws_vpclattice_service.main.id
  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.main.id
      }
    }
  }
}

resource "aws_vpclattice_target_group" "main" {
  name = "wsc2024-lattice-tg"
  type = "IP"

  config {
    vpc_identifier = aws_vpc.prod.id

    ip_address_type  = "IPV4"
    port             = 80
    protocol         = "HTTP"
    protocol_version = "HTTP1"

    health_check {
      path = "/healthcheck"
    }
  }
}

resource "aws_vpclattice_service_network_service_association" "main" {
  service_identifier         = aws_vpclattice_service.main.id
  service_network_identifier = aws_vpclattice_service_network.main.id
}

resource "aws_vpclattice_service_network_vpc_association" "main" {
  vpc_identifier             = aws_vpc.ma.id
  service_network_identifier = aws_vpclattice_service_network.main.id
  security_group_ids         = [aws_security_group.lattice.id]
}

resource "aws_security_group" "lattice" {
  name        = "wsc2024-lattice-sg"
  description = "Security group for Lattice"
  vpc_id      = aws_vpc.ma.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_network_interface" "alb" {
  filter {
    name   = "description"
    values = ["ELB ${aws_alb.main.arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [aws_subnet.prod-load-a.id]
  }
}

resource "aws_vpclattice_target_group_attachment" "alb" {
  target_group_identifier = aws_vpclattice_target_group.main.id

  target {
    id   = data.aws_network_interface.alb.private_ip
    port = 80
  }
}