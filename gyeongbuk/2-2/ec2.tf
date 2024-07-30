resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023-arm.id
  associate_public_ip_address = true
  instance_type               = "t4g.small"
  subnet_id                   = aws_subnet.public-a.id
  disable_api_termination     = true
  key_name                    = data.aws_key_pair.wsi.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.poweruser.name

  tags = {
    Name = "wsi-bastion"
  }
}

data "aws_ami" "al2023-64" {
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

data "aws_ami" "al2023-arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_eip" "bastion" {
  domain   = "vpc"
  instance = aws_instance.bastion.id

  tags = {
    Name = "wsi-eip-bastion"
  }
}

resource "aws_security_group" "bastion" {
  name        = "wsi-sg-bastion"
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

resource "aws_iam_role" "poweruser" {
  name               = "wsi-role-bastion"
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

resource "aws_iam_role_policy_attachment" "poweruser" {
  role       = aws_iam_role.poweruser.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_instance_profile" "poweruser" {
  name = aws_iam_role.poweruser.name
  role = aws_iam_role.poweruser.name
}

resource "aws_launch_template" "app" {
  name                   = "app_instance"
  image_id               = data.aws_ami.al2023-64.id
  instance_type          = "t3.medium"
  key_name               = data.aws_key_pair.wsi.key_name
  user_data              = base64encode(data.template_file.user_data.rendered)
  vpc_security_group_ids = [aws_security_group.app.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.app.arn
  }
}

data "template_file" "user_data" {
  template = file("user_data.sh")

  vars = {
    bucket_name = aws_s3_bucket.app.id
  }
}

resource "aws_security_group" "app" {
  name        = "app-instance-sg"
  description = "Security group for App"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
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

resource "aws_iam_role" "app" {
  name               = "app_instance_role"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

data "aws_iam_policy_document" "app" {
  statement {
    effect    = "Allow"
    resources = [aws_s3_bucket.app.arn]
    actions   = ["s3:ListBucket"]
  }

  statement {
    effect    = "Allow"
    resources = ["${aws_s3_bucket.app.arn}/*"]
    actions   = ["s3:GetObject"]
  }
}

resource "aws_iam_role_policy" "app" {
  name = "AppGetPolicy"
  role = aws_iam_role.app.id

  policy = data.aws_iam_policy_document.app.json
}

resource "aws_iam_instance_profile" "app" {
  name = aws_iam_role.app.name
  role = aws_iam_role.app.name
}

resource "aws_autoscaling_group" "app" {
  name                = "app_instance_asg"
  min_size            = 2
  max_size            = 7
  vpc_zone_identifier = [aws_subnet.private-a.id, aws_subnet.private-b.id]
  target_group_arns   = [aws_alb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Name"
    value               = "app_instance"
    propagate_at_launch = true
  }
}

resource "aws_alb" "app" {
  name            = "wsi-alb"
  security_groups = [aws_security_group.alb.id]
  subnets         = [aws_subnet.public-a.id, aws_subnet.public-b.id]
}

resource "aws_alb_target_group" "app" {
  name                 = "wsi-tg"
  port                 = 5000
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 60

  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener" "alb_http" {
  load_balancer_arn = aws_alb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app.arn
  }
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
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