# ap-northeast-2
resource "aws_vpc" "ap" {
  cidr_block           = "10.129.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "hrdkorea-vpc"
  }
}

resource "aws_subnet" "ap-public-a" {
  vpc_id                  = aws_vpc.ap.id
  cidr_block              = "10.129.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "hrdkorea-public-sn-a"
  }
}

resource "aws_subnet" "ap-public-b" {
  vpc_id                  = aws_vpc.ap.id
  cidr_block              = "10.129.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2b"

  tags = {
    Name = "hrdkorea-public-sn-b"
  }
}

resource "aws_subnet" "ap-private-a" {
  vpc_id            = aws_vpc.ap.id
  cidr_block        = "10.129.11.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "hrdkorea-private-sn-a"
  }
}

resource "aws_subnet" "ap-private-b" {
  vpc_id            = aws_vpc.ap.id
  cidr_block        = "10.129.12.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "hrdkorea-private-sn-b"
  }
}

resource "aws_subnet" "ap-protect-a" {
  vpc_id            = aws_vpc.ap.id
  cidr_block        = "10.129.21.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "hrdkorea-protect-sn-a"
  }
}

resource "aws_subnet" "ap-protect-b" {
  vpc_id            = aws_vpc.ap.id
  cidr_block        = "10.129.22.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "hrdkorea-protect-sn-b"
  }
}

resource "aws_internet_gateway" "ap" {
  vpc_id = aws_vpc.ap.id

  tags = {
    Name = "hrdkorea-igw"
  }
}

resource "aws_eip" "ap-eip-a" {
  domain = "vpc"

  tags = {
    Name = "hrdkorea-eip-a"
  }
}

resource "aws_eip" "ap-eip-b" {
  domain = "vpc"

  tags = {
    Name = "hrdkorea-eip-b"
  }
}

resource "aws_nat_gateway" "ap-nat-a" {
  allocation_id = aws_eip.ap-eip-a.id
  subnet_id     = aws_subnet.ap-public-a.id

  tags = {
    Name = "hrdkorea-natgw-a"
  }

  depends_on = [aws_internet_gateway.ap]
}

resource "aws_nat_gateway" "ap-nat-b" {
  allocation_id = aws_eip.ap-eip-b.id
  subnet_id     = aws_subnet.ap-public-b.id

  tags = {
    Name = "hrdkorea-natgw-b"
  }

  depends_on = [aws_internet_gateway.ap]
}

resource "aws_route_table" "ap-public" {
  vpc_id = aws_vpc.ap.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ap.id
  }

  tags = {
    Name = "hrdkorea-public-rt"
  }
}

resource "aws_route_table" "ap-private-a" {
  vpc_id = aws_vpc.ap.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ap-nat-a.id
  }

  tags = {
    Name = "hrdkorea-private-a-rt"
  }
}

resource "aws_route_table" "ap-private-b" {
  vpc_id = aws_vpc.ap.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ap-nat-b.id
  }

  tags = {
    Name = "hrdkorea-private-b-rt"
  }
}

resource "aws_route_table" "ap-protect" {
  vpc_id = aws_vpc.ap.id

  tags = {
    Name = "hrdkorea-protect-rt"
  }
}

resource "aws_route_table_association" "ap-public-a-join" {
  subnet_id      = aws_subnet.ap-public-a.id
  route_table_id = aws_route_table.ap-public.id
}

resource "aws_route_table_association" "ap-public-b-join" {
  subnet_id      = aws_subnet.ap-public-b.id
  route_table_id = aws_route_table.ap-public.id
}

resource "aws_route_table_association" "ap-private-a-join" {
  subnet_id      = aws_subnet.ap-private-a.id
  route_table_id = aws_route_table.ap-private-a.id
}

resource "aws_route_table_association" "ap-private-b-join" {
  subnet_id      = aws_subnet.ap-private-b.id
  route_table_id = aws_route_table.ap-private-b.id
}

resource "aws_route_table_association" "ap-protect-a-join" {
  subnet_id      = aws_subnet.ap-protect-a.id
  route_table_id = aws_route_table.ap-protect.id
}

resource "aws_route_table_association" "ap-protect-b-join" {
  subnet_id      = aws_subnet.ap-protect-b.id
  route_table_id = aws_route_table.ap-protect.id
}

# us-east-1
resource "aws_vpc" "us" {
  provider = aws.us-east-1

  cidr_block           = "10.129.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "hrdkorea-vpc"
  }
}

resource "aws_subnet" "us-public-a" {
  provider = aws.us-east-1

  vpc_id                  = aws_vpc.us.id
  cidr_block              = "10.129.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "hrdkorea-public-sn-a"
  }
}

resource "aws_subnet" "us-public-b" {
  provider = aws.us-east-1

  vpc_id                  = aws_vpc.us.id
  cidr_block              = "10.129.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "hrdkorea-public-sn-b"
  }
}

resource "aws_subnet" "us-private-a" {
  provider = aws.us-east-1

  vpc_id            = aws_vpc.us.id
  cidr_block        = "10.129.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "hrdkorea-private-sn-a"
  }
}

resource "aws_subnet" "us-private-b" {
  provider = aws.us-east-1

  vpc_id            = aws_vpc.us.id
  cidr_block        = "10.129.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "hrdkorea-private-sn-b"
  }
}

resource "aws_subnet" "us-protect-a" {
  provider = aws.us-east-1

  vpc_id            = aws_vpc.us.id
  cidr_block        = "10.129.21.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "hrdkorea-protect-sn-a"
  }
}

resource "aws_subnet" "us-protect-b" {
  provider = aws.us-east-1

  vpc_id            = aws_vpc.us.id
  cidr_block        = "10.129.22.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "hrdkorea-protect-sn-b"
  }
}

resource "aws_internet_gateway" "us" {
  provider = aws.us-east-1

  vpc_id = aws_vpc.us.id

  tags = {
    Name = "hrdkorea-igw"
  }
}

resource "aws_eip" "us-eip-a" {
  provider = aws.us-east-1

  domain = "vpc"

  tags = {
    Name = "hrdkorea-eip-a"
  }
}

resource "aws_eip" "us-eip-b" {
  provider = aws.us-east-1

  domain = "vpc"

  tags = {
    Name = "hrdkorea-eip-b"
  }
}

resource "aws_nat_gateway" "us-nat-a" {
  provider = aws.us-east-1

  allocation_id = aws_eip.us-eip-a.id
  subnet_id     = aws_subnet.us-public-a.id

  tags = {
    Name = "hrdkorea-natgw-a"
  }

  depends_on = [aws_internet_gateway.us]
}

resource "aws_nat_gateway" "us-nat-b" {
  provider = aws.us-east-1

  allocation_id = aws_eip.us-eip-b.id
  subnet_id     = aws_subnet.us-public-b.id

  tags = {
    Name = "hrdkorea-natgw-b"
  }

  depends_on = [aws_internet_gateway.us]
}

resource "aws_route_table" "us-public" {
  provider = aws.us-east-1

  vpc_id = aws_vpc.us.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.us.id
  }

  tags = {
    Name = "hrdkorea-public-rt"
  }
}

resource "aws_route_table" "us-private-a" {
  provider = aws.us-east-1

  vpc_id = aws_vpc.us.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.us-nat-a.id
  }

  tags = {
    Name = "hrdkorea-private-a-rt"
  }
}

resource "aws_route_table" "us-private-b" {
  provider = aws.us-east-1

  vpc_id = aws_vpc.us.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.us-nat-b.id
  }

  tags = {
    Name = "hrdkorea-private-b-rt"
  }
}

resource "aws_route_table" "us-protect" {
  provider = aws.us-east-1

  vpc_id = aws_vpc.us.id

  tags = {
    Name = "hrdkorea-protect-rt"
  }
}

resource "aws_route_table_association" "us-public-a-join" {
  provider = aws.us-east-1

  subnet_id      = aws_subnet.us-public-a.id
  route_table_id = aws_route_table.us-public.id
}

resource "aws_route_table_association" "us-public-b-join" {
  provider = aws.us-east-1

  subnet_id      = aws_subnet.us-public-b.id
  route_table_id = aws_route_table.us-public.id
}

resource "aws_route_table_association" "us-private-a-join" {
  provider = aws.us-east-1

  subnet_id      = aws_subnet.us-private-a.id
  route_table_id = aws_route_table.us-private-a.id
}

resource "aws_route_table_association" "us-private-b-join" {
  provider = aws.us-east-1

  subnet_id      = aws_subnet.us-private-b.id
  route_table_id = aws_route_table.us-private-b.id
}

resource "aws_route_table_association" "us-protect-a-join" {
  provider = aws.us-east-1

  subnet_id      = aws_subnet.us-protect-a.id
  route_table_id = aws_route_table.us-protect.id
}

resource "aws_route_table_association" "us-protect-b-join" {
  provider = aws.us-east-1

  subnet_id      = aws_subnet.us-protect-b.id
  route_table_id = aws_route_table.us-protect.id
}