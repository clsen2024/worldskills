resource "aws_ec2_transit_gateway" "main" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name = "gwangju-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc1" {
  subnet_ids         = [aws_subnet.vpc1-a.id, aws_subnet.vpc1-b.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.vpc1.id

  tags = {
    Name = "gwangju-VPC1-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc2" {
  subnet_ids         = [aws_subnet.vpc2-a.id, aws_subnet.vpc2-b.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.vpc2.id

  tags = {
    Name = "gwangju-VPC2-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "egress" {
  subnet_ids         = [aws_subnet.egress-private-a.id, aws_subnet.egress-private-b.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.egress.id

  tags = {
    Name = "gwangju-EgressVPC-attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table" "vpc1" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "gwangju-VPC1-rtb"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "vpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpc1.id
}

resource "aws_ec2_transit_gateway_route" "vpc1-egress" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpc1.id
}

resource "aws_ec2_transit_gateway_route_table" "vpc2" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "gwangju-VPC2-rtb"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "vpc2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpc2.id
}

resource "aws_ec2_transit_gateway_route" "vpc2-egress" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpc2.id
}

resource "aws_ec2_transit_gateway_route" "vpc2-egress-block" {
  destination_cidr_block         = aws_vpc.egress.cidr_block
  blackhole                      = true
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpc2.id
}

resource "aws_ec2_transit_gateway_route_table" "egress" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "gwangju-EgressVPC-rtb"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "egress" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "egress-vpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "egress-vpc2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}