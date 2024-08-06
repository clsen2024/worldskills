resource "aws_ec2_transit_gateway" "main" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "wsc2024-vpc-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "ma" {
  subnet_ids         = [aws_subnet.ma-mgmt-a.id, aws_subnet.ma-mgmt-b.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.ma.id

  tags = {
    Name = "wsc2024-ma-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  subnet_ids         = [aws_subnet.prod-app-a.id, aws_subnet.prod-app-b.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.prod.id

  tags = {
    Name = "wsc2024-prod-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "storage" {
  subnet_ids         = [aws_subnet.storage-db-a.id, aws_subnet.storage-db-b.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.storage.id

  tags = {
    Name = "wsc2024-storage-tgw-attach"
  }
}

resource "aws_ec2_transit_gateway_route_table" "ma" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "wsc2024-ma-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "ma" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ma.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ma.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "ma-prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ma.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "ma-storage" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.storage.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ma.id
}

resource "aws_ec2_transit_gateway_route_table" "prod" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "wsc2024-prod-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "prod-ma" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ma.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "prod-storage" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.storage.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.prod.id
}

resource "aws_ec2_transit_gateway_route_table" "storage" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "wsc2024-storage-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "storage" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.storage.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.storage.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "storage-ma" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ma.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.storage.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "storage-prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.storage.id
}