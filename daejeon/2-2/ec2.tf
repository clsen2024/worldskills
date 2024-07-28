resource "aws_instance" "test" {
  ami                         = data.aws_ami.amazon-linux-2023.id
  associate_public_ip_address = true
  instance_type               = "t2.micro"

  tags = {
    Name = "wsi-app-ec2"
  }
}

data "aws_ami" "amazon-linux-2023" {
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