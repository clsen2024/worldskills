resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.private-a.id
  disable_api_termination     = true
  key_name                    = aws_key_pair.wsi.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  user_data_base64 = base64encode(data.template_file.user_data.rendered)

  tags = {
    Name = "gm-bastion"
  }
}

data "template_file" "user_data" {
  template = file("user_data.sh")

  vars = {
    bucket_name = aws_s3_bucket.app.id
  }
}

resource "aws_instance" "scripts" {
  ami                         = data.aws_ami.al2023.id
  associate_public_ip_address = true
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public-a.id
  disable_api_termination     = true
  key_name                    = aws_key_pair.wsi.key_name
  vpc_security_group_ids      = [aws_security_group.scripts.id]
  iam_instance_profile        = aws_iam_instance_profile.scripts.name

  tags = {
    Name = "gm-scripts"
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

resource "aws_security_group" "bastion" {
  name        = "gm-bastion-sg"
  description = "Security Group for Bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 5000
    to_port          = 5000
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

resource "aws_security_group" "scripts" {
  name        = "gm-scripts-sg"
  description = "Security Group for Scripts"
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

resource "aws_key_pair" "wsi" {
  key_name   = "wsi"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_iam_role" "bastion" {
  name               = "gm-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_role" "scripts" {
  name               = "gm-scripts-role"
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

resource "aws_iam_role_policy_attachment" "bastion" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion.arn
}

resource "aws_iam_policy" "bastion" {
  name        = "StorageAccessPolicy"
  path        = "/"
  description = "EC2 Storage Access Policy"

  policy = data.aws_iam_policy_document.bastion.json
}

data "aws_iam_policy_document" "bastion" {
  statement {
    effect    = "Allow"
    resources = [aws_dynamodb_table.main.arn]
    actions   = ["dynamodb:PutItem"]
  }

  statement {
    effect    = "Allow"
    resources = ["${aws_s3_bucket.main.arn}/*"]
    actions   = ["s3:PutObject"]
  }

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

resource "aws_iam_role_policy_attachment" "scripts" {
  role       = aws_iam_role.scripts.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "bastion" {
  name = aws_iam_role.bastion.name
  role = aws_iam_role.bastion.name
}

resource "aws_iam_instance_profile" "scripts" {
  name = aws_iam_role.scripts.name
  role = aws_iam_role.scripts.name
}

resource "aws_alb" "main" {
  name            = "gm-alb"
  security_groups = [aws_security_group.alb.id]
  internal = true
  subnets         = [aws_subnet.private-a.id, aws_subnet.private-b.id]

  tags = {
    Name = "gm-alb"
  }
}

resource "aws_security_group" "alb" {
  name        = "gm-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
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
    target_group_arn = aws_alb_target_group.main.arn
  }
}

resource "aws_alb_target_group" "main" {
  name                 = "gm-tg"
  port                 = "5000"
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 60

  tags = {
    Name = "gm-tg"
  }
}

resource "aws_alb_target_group_attachment" "main" {
  target_group_arn = aws_alb_target_group.main.arn
  target_id        = aws_instance.bastion.id
  port             = 5000
}