resource "aws_vpc" "main" {
  cidr_block           = "210.89.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "J-VPC"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "210.89.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "J-company-priv-sub-a"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "210.89.2.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "J-company-priv-sub-b"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "J-company-priv-rtb"
  }
}

resource "aws_route_table_association" "private-a-join" {
  subnet_id      = aws_subnet.private-a.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "private-b-join" {
  subnet_id      = aws_subnet.private-b.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private-rt.id]
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-2.sqs"
  vpc_endpoint_type = "Interface"
  subnet_ids = [aws_subnet.private-a.id, aws_subnet.private-b.id]
  security_group_ids = [aws_security_group.endpoint.id]
  private_dns_enabled = true
}

resource "aws_security_group" "endpoint" {
  name        = "J-company-endpoint-sg"
  description = "SQS Endpoint Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}