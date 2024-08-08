resource "aws_rds_cluster" "main" {
  cluster_identifier     = "skills-aurora-mysql"
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.05.2"
  database_name          = "skills"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  master_username        = "admin"
  master_password        = "adminpass1234!"
  vpc_security_group_ids = [aws_security_group.rds.id]
  storage_encrypted      = true
  skip_final_snapshot    = true

  serverlessv2_scaling_configuration {
    max_capacity = 8.0
    min_capacity = 2.0
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "${aws_rds_cluster.main.cluster_identifier}-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
}

resource "aws_db_subnet_group" "main" {
  name       = "skills-data-subnets"
  subnet_ids = [aws_subnet.data-a.id, aws_subnet.data-b.id]
}

resource "aws_security_group" "rds" {
  name        = "skills-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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