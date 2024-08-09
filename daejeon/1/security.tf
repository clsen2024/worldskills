# ap-northeast-2
resource "aws_secretsmanager_secret" "ap-database" {
  name                    = "dbsecret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ap-database" {
  secret_id = aws_secretsmanager_secret.ap-database.id
  secret_string = jsonencode({
    MYSQL_USER     = aws_rds_cluster.ap.master_username
    MYSQL_PASSWORD = aws_rds_cluster.ap.master_password
    MYSQL_HOST     = aws_rds_cluster.ap.endpoint
    MYSQL_PORT     = aws_rds_cluster.ap.port
    MYSQL_DBNAME   = aws_rds_global_cluster.main.database_name
  })
}

resource "aws_secretsmanager_secret" "ap-order" {
  name                    = "order"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ap-order" {
  secret_id = aws_secretsmanager_secret.ap-order.id
  secret_string = jsonencode({
    AWS_REGION = "ap-northeast-2"
  })
}

# us-east-1
resource "aws_secretsmanager_secret" "us-database" {
  provider = aws.us-east-1

  name                    = "dbsecret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "us-database" {
  provider = aws.us-east-1

  secret_id = aws_secretsmanager_secret.us-database.id
  secret_string = jsonencode({
    MYSQL_USER     = aws_rds_cluster.ap.master_username
    MYSQL_PASSWORD = aws_rds_cluster.ap.master_password
    MYSQL_HOST     = aws_rds_cluster.us.endpoint
    MYSQL_PORT     = aws_rds_cluster.us.port
    MYSQL_DBNAME   = aws_rds_global_cluster.main.database_name
  })
}

resource "aws_secretsmanager_secret" "us-order" {
  provider = aws.us-east-1

  name                    = "order"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "us-order" {
  provider = aws.us-east-1

  secret_id = aws_secretsmanager_secret.us-order.id
  secret_string = jsonencode({
    AWS_REGION = "us-east-1"
  })
}

data "aws_kms_alias" "default" {
  provider = aws.us-east-1

  name = "alias/aws/rds"
}