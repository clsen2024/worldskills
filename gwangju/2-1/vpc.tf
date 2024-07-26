resource "aws_vpc" "vpc1" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_hostnames = true

  tags = {
    Name = "gwangju-VPC1"
  }
}

resource "aws_subnet" "vpc1-a" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.0.0/25"
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "gwangju-VPC1-a"
  }
}

resource "aws_subnet" "vpc1-b" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.0.128/25"
  availability_zone       = "ap-northeast-2b"

  tags = {
    Name = "gwangju-VPC1-b"
  }
}

resource "aws_vpc" "vpc2" {
  cidr_block           = "10.0.1.0/24"
  enable_dns_hostnames = true

  tags = {
    Name = "gwangju-VPC2"
  }
}

resource "aws_subnet" "vpc2-a" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = "10.0.1.0/25"
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "gwangju-VPC2-a"
  }
}

resource "aws_subnet" "vpc2-b" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = "10.0.1.128/25"
  availability_zone       = "ap-northeast-2b"

  tags = {
    Name = "gwangju-VPC2-b"
  }
}

resource "aws_vpc" "egress" {
  cidr_block           = "10.0.2.0/24"
  enable_dns_hostnames = true

  tags = {
    Name = "gwangju-EgressVPC"
  }
}

resource "aws_subnet" "egress-public-a" {
  vpc_id                  = aws_vpc.vpc3.id
  cidr_block              = "10.0.2.0/26"
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "gwangju-EgressVPC-public-a"
  }
}

resource "aws_subnet" "egress-private-a" {
  vpc_id                  = aws_vpc.vpc3.id
  cidr_block              = "10.0.2.64/26"
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "gwangju-EgressVPC-private-a"
  }
}

resource "aws_subnet" "egress-private-b" {
  vpc_id                  = aws_vpc.vpc3.id
  cidr_block              = "10.0.2.128/25"
  availability_zone       = "ap-northeast-2b"

  tags = {
    Name = "gwangju-EgressVPC-private-b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.egress.id

  tags = {
    Name = "gwangju-EgressVPC-igw"
  }
}

resource "aws_eip" "eip-a" {
  domain = "vpc"

  tags = {
    Name = "gwangju-EgressVPC-eip-a"
  }
}

resource "aws_nat_gateway" "nat-a" {
  allocation_id = aws_eip.eip-a.id
  subnet_id     = aws_subnet.egress-public-a.id

  tags = {
    Name = "gwangju-EgressVPC-natgw-a"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "vpc1-rt" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "gwangju-VPC1-rtb"
  }
}

resource "aws_route_table" "vpc2-rt" {
  vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "gwangju-VPC2-rtb"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.egress.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "gwangju-EgressVPC-public-rtb"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.egress.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-a.id
  }

  tags = {
    Name = "gwangju-EgressVPC-private-rtb"
  }
}

resource "aws_route_table_association" "vpc1-a-join" {
  subnet_id      = aws_subnet.vpc1-a.id
  route_table_id = aws_route_table.vpc1-rt.id
}

resource "aws_route_table_association" "vpc1-b-join" {
  subnet_id      = aws_subnet.vpc1-b.id
  route_table_id = aws_route_table.vpc1-rt.id
}

resource "aws_route_table_association" "vpc2-a-join" {
  subnet_id      = aws_subnet.vpc2-a.id
  route_table_id = aws_route_table.vpc2-rt.id
}

resource "aws_route_table_association" "vpc2-b-join" {
  subnet_id      = aws_subnet.vpc2-b.id
  route_table_id = aws_route_table.vpc2-rt.id
}

resource "aws_route_table_association" "egress-public-a-join" {
  subnet_id      = aws_subnet.egress-public-a.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "egress-private-a-join" {
  subnet_id      = aws_subnet.egress-private-a.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_route_table_association" "egress-private-b-join" {
  subnet_id      = aws_subnet.egress-private-b.id
  route_table_id = aws_route_table.private-rt.id
}