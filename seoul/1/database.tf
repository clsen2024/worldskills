resource "aws_db_instance" "main" {
  identifier                      = "wsi-rds-mysql"
  db_name                         = "wsi"
  engine                          = "mysql"
  engine_version                  = "8.0.35"
  instance_class                  = "db.m5.xlarge"
  port                            = 3310
  username                        = "admin"
  manage_master_user_password     = true
  multi_az                        = true
  db_subnet_group_name            = aws_db_subnet_group.main.name
  allocated_storage               = 10
  backup_retention_period         = 7
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  storage_encrypted               = true
  vpc_security_group_ids          = [aws_security_group.rds.id]
  apply_immediately               = true
  skip_final_snapshot             = true
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

  point_in_time_recovery {
    enabled = true
  }
}