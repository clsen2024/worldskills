resource "aws_rds_cluster" "main" {
  cluster_identifier              = "wsc2024-db-cluster"
  engine                          = "aurora-mysql"
  engine_version                  = "8.0.mysql_aurora.3.05.2"
  db_subnet_group_name            = aws_db_subnet_group.main.name
  master_username                 = "admin"
  master_password                 = "Skill53##"
  database_name                   = "wsc2024_db"
  vpc_security_group_ids          = [aws_security_group.rds.id]
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  backtrack_window                = 14400
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
  name       = "wsc2024-storage-db-subnets"
  subnet_ids = [aws_subnet.storage-db-a.id, aws_subnet.storage-db-b.id]
}

resource "aws_security_group" "rds" {
  name        = "wsc2024-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.storage.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.prod-app-a.cidr_block, aws_subnet.prod-app-b.cidr_block]
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
}