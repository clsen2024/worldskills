resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  associate_public_ip_address = true
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public-a.id
  disable_api_termination     = true
  key_name                    = data.aws_key_pair.wsi.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.admin.name

  tags = {
    Name = "gyeongbuk-1-bastion"
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "bastion" {
  name        = "gyeongbuk-1-bastion-sg"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 22
    to_port          = 22
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

data "aws_key_pair" "wsi" {
  key_name = "wsi"
}

resource "aws_iam_role" "admin" {
  name               = "gyeongbuk-1-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

data "aws_iam_policy_document" "ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "admin" {
  name = aws_iam_role.admin.name
  role = aws_iam_role.admin.name
}

resource "aws_launch_template" "ecs" {
  name                   = "ecs_instance"
  image_id               = data.aws_ami.ecs.id
  instance_type          = "t3.medium"
  user_data              = base64encode(data.template_file.user_data.rendered)
  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs.arn
  }

  monitoring {
    enabled = true
  }
}

resource "aws_security_group" "ec2" {
  name        = "ecs-instance-sg"
  description = "Security group for EC2 instances in ECS cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
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

data "template_file" "user_data" {
  template = file("user_data.sh")

  vars = {
    ecs_cluster_name = aws_ecs_cluster.main.name
  }
}

resource "aws_iam_role" "ecs" {
  name               = "ecs_instance_role"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs" {
  name = aws_iam_role.ecs.name
  role = aws_iam_role.ecs.name
}

resource "aws_autoscaling_group" "ecs" {
  name                = "ecs_instance_asg"
  max_size            = 2
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.private-a.id, aws_subnet.private-b.id]
  health_check_type   = "EC2"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Name"
    value               = "ecs_instance"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [tag]
  }
}