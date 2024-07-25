resource "aws_ecs_cluster" "main" {
  name = "wsc2024-ecs-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "main" {
  family             = "wsc2024-td"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  execution_role_arn = aws_iam_role.task_exec.arn

  container_definitions = jsonencode([
    {
      name      = "wsc2024"
      image     = "${aws_ecr_repository.main.repository_url}:1"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
          "awslogs-region"        = "us-west-1",
          "awslogs-stream-prefix" = "ecs"
        }
      }
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8080/healthcheck || exit 1"
        ]
      }
    }
  ])

  cpu          = 512
  memory       = 1024

  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_iam_role" "task_exec" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.task.json
}

data "aws_iam_policy_document" "task" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "task_exec" {
  role       = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/wsc2024-td"
  retention_in_days = 0
}

resource "aws_ecs_service" "main" {
  name            = "wsc2024-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 2

  capacity_provider_strategy {
    base              = 1
    capacity_provider = "FARGATE"
    weight            = 100
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets = [aws_subnet.private-a.id, aws_subnet.private-b.id]
    security_groups = [ aws_security_group.ecs.id ]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.blue.arn
    container_name   = "wsc2024"
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition, load_balancer]
  }

  depends_on = [null_resource.ecr_push]
}

resource "aws_security_group" "ecs" {
  name        = "wsc2024-ecs-sg"
  description = "Security group for ECS Service"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_alb" "main" {
  name            = "wsc2024-alb"
  security_groups = [aws_security_group.alb.id]
  subnets         = [aws_subnet.public-a.id, aws_subnet.public-b.id]
}

resource "aws_security_group" "alb" {
  name        = "wsc2024-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

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

resource "aws_alb_listener" "alb_http" {
  load_balancer_arn = aws_alb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.blue.arn
  }
}

resource "aws_alb_target_group" "blue" {
  name                 = "wsc2024-blue-tg"
  port                 = "8080"
  protocol             = "HTTP"
  target_type = "ip"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 60
}

resource "aws_alb_target_group" "green" {
  name                 = "wsc2024-green-tg"
  port                 = "8080"
  protocol             = "HTTP"
  target_type = "ip"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 60
}