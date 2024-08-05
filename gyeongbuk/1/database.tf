resource "aws_rds_cluster" "main" {
  cluster_identifier              = "wsi-aurora-mysql"
  engine                          = "aurora-mysql"
  engine_version                  = "8.0.mysql_aurora.3.05.2"
  db_subnet_group_name            = aws_db_subnet_group.main.name
  master_username                 = "admin"
  master_password                 = "adminpass1234!"
  vpc_security_group_ids          = [aws_security_group.rds.id]
  port                            = 3310
  kms_key_id                      = aws_kms_key.main.arn
  storage_encrypted               = true
  enabled_cloudwatch_logs_exports = ["audit", "error"]
  skip_final_snapshot             = true
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "${aws_rds_cluster.main.cluster_identifier}-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
}

resource "aws_db_subnet_group" "main" {
  name       = "wsi-data-subnets"
  subnet_ids = [aws_subnet.data-a.id, aws_subnet.data-b.id]
}

resource "aws_security_group" "rds" {
  name        = "wsi-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3310
    to_port     = 3310
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_dynamodb_table" "main" {
  name         = "order"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.main.arn
  }
}