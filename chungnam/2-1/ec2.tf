resource "aws_instance" "wsc" {
  ami                         = data.aws_ami.al2023.id
  associate_public_ip_address = true
  instance_type               = "t3.small"
  disable_api_termination     = true
  vpc_security_group_ids      = [aws_security_group.wsc.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm.name

  tags = {
    Name = "wsc2024-instance"
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

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "wsc" {
  name        = "wsc2024-instance-sg"
  description = "Allow SSH traffic"
  vpc_id      = data.aws_vpc.default.id

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

resource "aws_iam_role" "ssm" {
  name               = "wsc2024-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = aws_iam_role.ssm.name
  role = aws_iam_role.ssm.name
}