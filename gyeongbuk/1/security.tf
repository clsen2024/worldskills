resource "aws_kms_key" "main" {
  enable_key_rotation = true
}

resource "aws_kms_alias" "main" {
  name          = "alias/wsi"
  target_key_id = aws_kms_key.main.key_id
}

resource "aws_kms_key_policy" "main" {
  key_id = aws_kms_key.main.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "logs.ap-northeast-2.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:ap-northeast-2:${local.account_id}:*"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "cloudfront.amazonaws.com"
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

resource "aws_secretsmanager_secret" "customer" {
  name = "customer"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "customer" {
  secret_id = aws_secretsmanager_secret.customer.id
  secret_string = jsonencode({
    MYSQL_USER     = aws_rds_cluster.main.master_username
    MYSQL_PASSWORD = aws_rds_cluster.main.master_password
    MYSQL_HOST     = aws_rds_cluster.main.endpoint
    MYSQL_PORT     = aws_rds_cluster.main.port
    MYSQL_DBNAME   = "customer"
  })
}

resource "aws_secretsmanager_secret" "product" {
  name = "product"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "product" {
  secret_id = aws_secretsmanager_secret.product.id
  secret_string = jsonencode({
    MYSQL_USER     = aws_rds_cluster.main.master_username
    MYSQL_PASSWORD = aws_rds_cluster.main.master_password
    MYSQL_HOST     = aws_rds_cluster.main.endpoint
    MYSQL_PORT     = aws_rds_cluster.main.port
    MYSQL_DBNAME   = "product"
  })
}

resource "aws_secretsmanager_secret" "order" {
  name = "order"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "order" {
  secret_id = aws_secretsmanager_secret.order.id
  secret_string = jsonencode({
    AWS_REGION = "ap-northeast-2"
  })
}

resource "aws_wafv2_web_acl" "main" {
  provider = aws.us-east-1
  name     = "wsi-waf"
  scope    = "CLOUDFRONT"

  custom_response_body {
    key          = "unauthorized"
    content      = "Access Denied"
    content_type = "TEXT_PLAIN"
  }

  default_action {
    block {
      custom_response {
        custom_response_body_key = "unauthorized"
        response_code            = 403
      }
    }
  }

  rule {
    name     = "user-agent-allow"
    priority = 1

    action {
      allow {}
    }

    statement {
      byte_match_statement {
        field_to_match {
          single_header {
            name = "user-agent"
          }
        }

        positional_constraint = "CONTAINS"
        search_string         = "safe-client"

        text_transformation {
          type     = "NONE"
          priority = 0
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "user-agent-allow"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "wsi-waf"
    sampled_requests_enabled   = false
  }
}