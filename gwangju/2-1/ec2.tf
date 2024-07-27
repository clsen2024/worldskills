resource "aws_instance" "vpc1" {
  ami                     = data.aws_ami.al2023.id
  instance_type           = "t3.small"
  subnet_id               = aws_subnet.vpc1-a.id
  disable_api_termination = true
  vpc_security_group_ids  = [aws_security_group.vpc1.id]
  iam_instance_profile    = aws_iam_instance_profile.admin.name

  tags = {
    Name = "gwangju-VPC1-Instance"
  }
}

resource "aws_instance" "vpc2" {
  ami                     = data.aws_ami.al2023.id
  instance_type           = "t3.small"
  subnet_id               = aws_subnet.vpc2-a.id
  disable_api_termination = true
  vpc_security_group_ids  = [aws_security_group.vpc2.id]
  iam_instance_profile    = aws_iam_instance_profile.admin.name

  tags = {
    Name = "gwangju-VPC2-Instance"
  }
}

resource "aws_instance" "egress" {
  ami                     = data.aws_ami.al2023.id
  instance_type           = "t3.small"
  subnet_id               = aws_subnet.egress-private-b.id
  disable_api_termination = true
  vpc_security_group_ids  = [aws_security_group.egress.id]
  iam_instance_profile    = aws_iam_instance_profile.admin.name

  tags = {
    Name = "gwangju-EgressVPC-Instance"
  }
}

resource "aws_security_group" "vpc1" {
  name        = "gwangju-VPC1-Instance-sg"
  description = "Gwangju VPC1 Instance Security Group"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc2" {
  name        = "gwangju-VPC2-Instance-sg"
  description = "Gwangju VPC2 Instance Security Group"
  vpc_id      = aws_vpc.vpc2.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "egress" {
  name        = "gwangju-EgressVPC-Instance-sg"
  description = "Gwangju EgressVPC Instance Security Group"
  vpc_id      = aws_vpc.egress.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_iam_role" "admin" {
  name               = "gwangju-VPC-Instance-role"
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
