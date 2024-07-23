resource "aws_vpc" "main" {
  cidr_block           = "10.150.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "wsi-vpc"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.150.10.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "wsi-public-a"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.150.11.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2b"

  tags = {
    Name = "wsi-public-b"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.150.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "wsi-app-a"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.150.1.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "wsi-app-b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "wsi-igw"
  }
}

resource "aws_eip" "eip-a" {
  domain = "vpc"

  tags = {
    Name = "wsi-eip-a"
  }
}

resource "aws_eip" "eip-b" {
  domain = "vpc"

  tags = {
    Name = "wsi-eip-b"
  }
}

resource "aws_nat_gateway" "nat-a" {
  allocation_id = aws_eip.eip-a.id
  subnet_id     = aws_subnet.public-a.id

  tags = {
    Name = "wsi-natgw-a"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat-b" {
  allocation_id = aws_eip.eip-b.id
  subnet_id     = aws_subnet.public-b.id

  tags = {
    Name = "wsi-natgw-b"
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
    Name = "wsi-public-rt"
  }
}

resource "aws_route_table" "private-a-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-a.id
  }

  tags = {
    Name = "wsi-app-a-rt"
  }
}

resource "aws_route_table" "private-b-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-b.id
  }

  tags = {
    Name = "wsi-app-b-rt"
  }
}

resource "aws_route_table_association" "public-a-join" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "public-b-join" {
  subnet_id      = aws_subnet.public-b.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "private-a-join" {
  subnet_id      = aws_subnet.private-a.id
  route_table_id = aws_route_table.private-a-rt.id
}

resource "aws_route_table_association" "private-b-join" {
  subnet_id      = aws_subnet.private-b.id
  route_table_id = aws_route_table.private-b-rt.id
}