resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  associate_public_ip_address = true
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public-a.id
  disable_api_termination     = true
  key_name                    = aws_key_pair.wsi.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.admin.name

  tags = {
    Name = "wsi-bastion"
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

resource "aws_eip" "bastion" {
  domain   = "vpc"
  instance = aws_instance.bastion.id

  tags = {
    Name = "wsi-eip-bastion"
  }
}

resource "aws_security_group" "bastion" {
  name        = "wsi-bastion-sg"
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

resource "aws_key_pair" "wsi" {
  key_name   = "wsi"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_iam_role" "admin" {
  name = "wsi-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "admin" {
  name = aws_iam_role.admin.name
  role = aws_iam_role.admin.name
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.private-a.id
  key_name                    = aws_key_pair.wsi.key_name
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  user_data_base64 = base64encode(data.template_file.user_data.rendered)

  tags = {
    Name = "wsi-app"
  }
}

data "template_file" "user_data" {
  template = file("user_data.sh")

  vars = {
    bucket_name = aws_s3_bucket.app.id
    opensearch_url = aws_opensearch_domain.main.endpoint
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
    security_groups = [aws_security_group.bastion.id]
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