resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "gm-vpc"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "gm-pub-sn-a"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "gm-pri-sn-a"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "gm-pri-sn-b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "gm-igw"
  }
}

resource "aws_eip" "eip-a" {
  domain = "vpc"

  tags = {
    Name = "gm-eip-a"
  }
}

resource "aws_nat_gateway" "nat-a" {
  allocation_id = aws_eip.eip-a.id
  subnet_id     = aws_subnet.public-a.id

  tags = {
    Name = "gm-natgw-a"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "gm-pub-rt"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-a.id
  }

  tags = {
    Name = "gm-pri-rt"
  }
}

resource "aws_route_table_association" "public-a-join" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public-rt.id
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

  tags = {
    Name = "s3"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-2.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private-rt.id]

  tags = {
    Name = "dynamodb"
  }
}

resource "aws_vpc_endpoint_policy" "dynamodb" {
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  policy          = data.aws_iam_policy_document.dynamodb.json
}

data "aws_iam_policy_document" "dynamodb" {
  statement {
    sid       = "AllowAll"
    effect    = "Allow"
    resources = [aws_dynamodb_table.main.arn]
    actions   = ["dynamodb:*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}