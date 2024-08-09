# ap-northeast-2
resource "aws_instance" "ap-bastion" {
  ami                         = data.aws_ami.ap-al2023.id
  associate_public_ip_address = true
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.ap-public-a.id
  disable_api_termination     = true
  key_name                    = data.aws_key_pair.ap-wsi.key_name
  vpc_security_group_ids      = [aws_security_group.ap-bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.admin.name
  user_data                   = file("./user_data.sh")

  tags = {
    Name = "hrdkorea-bastion"
  }
}

data "aws_ami" "ap-al2023" {
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

resource "aws_security_group" "ap-bastion" {
  name        = "hrdkorea-bastion-sg"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.ap.id

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

data "aws_key_pair" "ap-wsi" {
  key_name = "wsi"
}

# us-east-1
resource "aws_instance" "us-bastion" {
  provider = aws.us-east-1

  ami                         = data.aws_ami.us-al2023.id
  associate_public_ip_address = true
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.us-public-a.id
  disable_api_termination     = true
  key_name                    = data.aws_key_pair.us-wsi.key_name
  vpc_security_group_ids      = [aws_security_group.us-bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.admin.name
  user_data                   = file("./user_data.sh")

  tags = {
    Name = "hrdkorea-bastion"
  }
}

data "aws_ami" "us-al2023" {
  provider = aws.us-east-1

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

resource "aws_security_group" "us-bastion" {
  provider = aws.us-east-1

  name        = "hrdkorea-bastion-sg"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.us.id

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

data "aws_key_pair" "us-wsi" {
  provider = aws.us-east-1

  key_name = "wsi"
}

# global
resource "aws_iam_role" "admin" {
  name               = "hrdkorea-bastion-role"
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