resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "wsi-vpc"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "wsi-public-a"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2b"

  tags = {
    Name = "wsi-public-b"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "wsi-app-a"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "wsi-app-b"
  }
}

resource "aws_subnet" "data-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.4.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "wsi-data-a"
  }
}

resource "aws_subnet" "data-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.5.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "wsi-data-b"
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
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-b.id
  }

  tags = {
    Name = "wsi-app-b-rt"
  }
}

resource "aws_route_table" "data-rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "wsi-data-rt"
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

resource "aws_route_table_association" "data-a-join" {
  subnet_id      = aws_subnet.data-a.id
  route_table_id = aws_route_table.data-rt.id
}

resource "aws_route_table_association" "data-b-join" {
  subnet_id      = aws_subnet.data-b.id
  route_table_id = aws_route_table.data-rt.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private-a-rt.id, aws_route_table.private-b-rt.id]

  tags = {
    Name = "s3"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-2.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private-a-rt.id, aws_route_table.private-b-rt.id]

  tags = {
    Name = "dynamodb"
  }
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "flow_log" {
  name = "/aws/vpc/${aws_vpc.main.tags["Name"]}"
}

data "aws_iam_policy_document" "flow_log_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_log" {
  name               = "VPCFlowLogsRole"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume.json
}

data "aws_iam_policy_document" "flow_log" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flow_log" {
  name   = "VPCFlowLogsPolicy"
  role   = aws_iam_role.flow_log.id
  policy = data.aws_iam_policy_document.flow_log.json
}