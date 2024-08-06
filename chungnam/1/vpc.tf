resource "aws_vpc" "ma" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "wsc2024-ma-vpc"
  }
}

resource "aws_subnet" "ma-mgmt-a" {
  vpc_id                  = aws_vpc.ma.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "wsc2024-ma-mgmt-sn-a"
  }
}

resource "aws_subnet" "ma-mgmt-b" {
  vpc_id                  = aws_vpc.ma.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "wsc2024-ma-mgmt-sn-b"
  }
}

resource "aws_internet_gateway" "ma-igw" {
  vpc_id = aws_vpc.ma.id

  tags = {
    Name = "wsc2024-ma-igw"
  }
}

resource "aws_route_table" "ma-mgmt-rt" {
  vpc_id = aws_vpc.ma.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ma-igw.id
  }

  route {
    cidr_block         = aws_vpc.prod.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  route {
    cidr_block         = aws_vpc.storage.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "wsc2024-ma-mgmt-rt"
  }
}

resource "aws_route_table_association" "ma-mgmt-a-join" {
  subnet_id      = aws_subnet.ma-mgmt-a.id
  route_table_id = aws_route_table.ma-mgmt-rt.id
}

resource "aws_route_table_association" "ma-mgmt-b-join" {
  subnet_id      = aws_subnet.ma-mgmt-b.id
  route_table_id = aws_route_table.ma-mgmt-rt.id
}

resource "aws_vpc" "prod" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "wsc2024-prod-vpc"
  }
}

resource "aws_subnet" "prod-load-a" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = "172.16.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "wsc2024-prod-load-sn-a"
  }
}

resource "aws_subnet" "prod-load-b" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = "172.16.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "wsc2024-prod-load-sn-b"
  }
}

resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "wsc2024-prod-igw"
  }
}

resource "aws_route_table" "prod-load-rt" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-igw.id
  }

  route {
    cidr_block         = aws_vpc.ma.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  route {
    cidr_block         = aws_vpc.storage.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "wsc2024-prod-load-rt"
  }
}

resource "aws_route_table_association" "prod-load-a-join" {
  subnet_id      = aws_subnet.prod-load-a.id
  route_table_id = aws_route_table.prod-load-rt.id
}

resource "aws_route_table_association" "prod-load-b-join" {
  subnet_id      = aws_subnet.prod-load-b.id
  route_table_id = aws_route_table.prod-load-rt.id
}

resource "aws_subnet" "prod-app-a" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "172.16.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "wsc2024-prod-app-sn-a"
  }
}

resource "aws_subnet" "prod-app-b" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "172.16.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "wsc2024-prod-app-sn-b"
  }
}

resource "aws_eip" "prod-eip-a" {
  domain = "vpc"

  tags = {
    Name = "wsc2024-prod-eip-a"
  }
}

resource "aws_eip" "prod-eip-b" {
  domain = "vpc"

  tags = {
    Name = "wsc2024-prod-eip-b"
  }
}

resource "aws_nat_gateway" "prod-nat-a" {
  allocation_id = aws_eip.prod-eip-a.id
  subnet_id     = aws_subnet.prod-load-a.id

  tags = {
    Name = "wsc2024-prod-natgw-a"
  }

  depends_on = [aws_internet_gateway.prod-igw]
}

resource "aws_nat_gateway" "prod-nat-b" {
  allocation_id = aws_eip.prod-eip-b.id
  subnet_id     = aws_subnet.prod-load-b.id

  tags = {
    Name = "wsc2024-prod-natgw-b"
  }

  depends_on = [aws_internet_gateway.prod-igw]
}

resource "aws_route_table" "prod-app-a-rt" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.prod-nat-a.id
  }

  route {
    cidr_block         = aws_vpc.ma.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  route {
    cidr_block         = aws_vpc.storage.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "wsc2024-prod-app-rt-a"
  }
}

resource "aws_route_table" "prod-app-b-rt" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.prod-nat-b.id
  }

  route {
    cidr_block         = aws_vpc.ma.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  route {
    cidr_block         = aws_vpc.storage.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "wsc2024-prod-app-rt-b"
  }
}

resource "aws_route_table_association" "prod-app-a-join" {
  subnet_id      = aws_subnet.prod-app-a.id
  route_table_id = aws_route_table.prod-app-a-rt.id
}

resource "aws_route_table_association" "prod-app-b-join" {
  subnet_id      = aws_subnet.prod-app-b.id
  route_table_id = aws_route_table.prod-app-b-rt.id
}

resource "aws_vpc" "storage" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "wsc2024-storage-vpc"
  }
}

resource "aws_subnet" "storage-db-a" {
  vpc_id            = aws_vpc.storage.id
  cidr_block        = "192.168.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "wsc2024-storage-db-sn-a"
  }
}

resource "aws_subnet" "storage-db-b" {
  vpc_id            = aws_vpc.storage.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "wsc2024-storage-db-sn-b"
  }
}

resource "aws_route_table" "storage-db-a-rt" {
  vpc_id = aws_vpc.storage.id

  route {
    cidr_block         = aws_vpc.ma.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  route {
    cidr_block         = aws_vpc.prod.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "wsc2024-storage-db-rt-a"
  }
}

resource "aws_route_table_association" "storage-db-a-join" {
  subnet_id      = aws_subnet.storage-db-a.id
  route_table_id = aws_route_table.storage-db-a-rt.id
}

resource "aws_route_table" "storage-db-b-rt" {
  vpc_id = aws_vpc.storage.id

  route {
    cidr_block         = aws_vpc.ma.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  route {
    cidr_block         = aws_vpc.prod.cidr_block
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "wsc2024-storage-db-rt-b"
  }
}

resource "aws_route_table_association" "storage-db-b-join" {
  subnet_id      = aws_subnet.storage-db-b.id
  route_table_id = aws_route_table.storage-db-b-rt.id
}

resource "aws_vpc_endpoint" "ecr-dkr" {
  vpc_id              = aws_vpc.prod.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.prod-app-a.id, aws_subnet.prod-app-b.id]
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "ecr-dkr"
  }
}

resource "aws_security_group" "endpoint" {
  name        = "wsc2024-endpoint-sg"
  description = "ECR Endpoint Security Group"
  vpc_id      = aws_vpc.prod.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.prod.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.prod.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.prod-app-a-rt.id, aws_route_table.prod-app-b-rt.id]

  tags = {
    Name = "s3"
  }
}

resource "aws_flow_log" "ma" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.ma.id
}

resource "aws_cloudwatch_log_group" "flow_log" {
  name = "/aws/vpc/${aws_vpc.ma.tags["Name"]}"
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