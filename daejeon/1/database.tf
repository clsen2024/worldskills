resource "aws_rds_global_cluster" "main" {
  global_cluster_identifier = "hrdkorea-global-cluster"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.05.2"
  database_name             = "hrdkorea"
  storage_encrypted         = true
}

resource "aws_rds_cluster" "ap" {
  engine                    = aws_rds_global_cluster.main.engine
  engine_version            = aws_rds_global_cluster.main.engine_version
  global_cluster_identifier = aws_rds_global_cluster.main.id
  cluster_identifier        = "hrdkorea-rds-cluster-ap"
  master_username           = "hrdkorea_user"
  master_password           = "hrdkorea1234pass!"
  port                      = 3409
  vpc_security_group_ids    = [aws_security_group.ap-rds.id]
  db_subnet_group_name      = aws_db_subnet_group.ap.name
  storage_encrypted         = true
  skip_final_snapshot       = true
}

resource "aws_rds_cluster_instance" "ap" {
  engine             = aws_rds_global_cluster.main.engine
  engine_version     = aws_rds_global_cluster.main.engine_version
  identifier         = "hrdkorea-rds-instance"
  cluster_identifier = aws_rds_cluster.ap.id
  instance_class     = "db.r5.large"
}

resource "aws_db_subnet_group" "ap" {
  name       = "hrdkorea-data-sn-ap"
  subnet_ids = [aws_subnet.ap-protect-a.id, aws_subnet.ap-protect-b.id]
}

resource "aws_security_group" "ap-rds" {
  name        = "hrdkorea-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.ap.id

  ingress {
    from_port   = 3409
    to_port     = 3409
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.ap.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_rds_cluster" "us" {
  provider = aws.us-east-1

  engine                          = aws_rds_global_cluster.main.engine
  engine_version                  = aws_rds_global_cluster.main.engine_version
  global_cluster_identifier       = aws_rds_global_cluster.main.id
  cluster_identifier              = "hrdkorea-rds-cluster-us"
  replication_source_identifier   = aws_rds_cluster.ap.arn
  port                            = 3409
  vpc_security_group_ids          = [aws_security_group.us-rds.id]
  db_subnet_group_name            = aws_db_subnet_group.us.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.us.name
  storage_encrypted               = true
  kms_key_id                      = data.aws_kms_alias.default.target_key_arn
  enable_global_write_forwarding  = true
  skip_final_snapshot             = true

  depends_on = [
    aws_rds_cluster_instance.ap
  ]
}

resource "aws_rds_cluster_parameter_group" "us" {
  provider = aws.us-east-1

  name        = "hrdkorea-rds-us-pg"
  family      = "aurora-mysql8.0"
  description = "Hrdkorea RDS US Cluster Parameter Group"

  parameter {
    name  = "aurora_replica_read_consistency"
    value = "GLOBAL"
  }
}

resource "aws_rds_cluster_instance" "us" {
  provider = aws.us-east-1

  engine             = aws_rds_global_cluster.main.engine
  engine_version     = aws_rds_global_cluster.main.engine_version
  identifier         = "hrdkorea-rds-instance-us"
  cluster_identifier = aws_rds_cluster.us.id
  instance_class     = "db.r5.large"
}

resource "aws_db_subnet_group" "us" {
  provider = aws.us-east-1

  name       = "hrdkorea-data-sn-us"
  subnet_ids = [aws_subnet.us-protect-a.id, aws_subnet.us-protect-b.id]
}

resource "aws_security_group" "us-rds" {
  provider = aws.us-east-1

  name        = "hrdkorea-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.us.id

  ingress {
    from_port   = 3409
    to_port     = 3409
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.us.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_dynamodb_table" "ap" {
  name           = "order"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  stream_enabled = true

  attribute {
    name = "id"
    type = "S"
  }

  replica {
    region_name = "us-east-1"
  }
}