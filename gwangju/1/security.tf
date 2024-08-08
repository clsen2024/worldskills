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

resource "aws_secretsmanager_secret" "database" {
  name                    = "skills-rds-secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    MYSQL_USER     = aws_rds_cluster.main.master_username
    MYSQL_PASSWORD = aws_rds_cluster.main.master_password
    MYSQL_HOST     = aws_rds_cluster.main.endpoint
    MYSQL_PORT     = aws_rds_cluster.main.port
    MYSQL_DBNAME   = "skills"
  })
}

resource "aws_secretsmanager_secret_rotation" "database" {
  secret_id           = aws_secretsmanager_secret.database.id
  rotation_lambda_arn = aws_lambda_function.rotation.arn

  rotation_rules {
    automatically_after_days = 3
  }
}

resource "aws_wafv2_web_acl" "main" {
  provider = aws.us-east-1
  name     = "skills-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "not-allowed-method"
    priority = 1

    action {
      block {
        custom_response {
          response_code = 405
        }
      }
    }

    statement {
      not_statement {
        statement {
          or_statement {
            statement {
              byte_match_statement {
                field_to_match {
                  method {}
                }

                positional_constraint = "EXACTLY"
                search_string         = "GET"

                text_transformation {
                  type     = "NONE"
                  priority = 0
                }
              }
            }

            statement {
              byte_match_statement {
                field_to_match {
                  method {}
                }

                positional_constraint = "EXACTLY"
                search_string         = "POST"

                text_transformation {
                  type     = "NONE"
                  priority = 0
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "not-allowed-method"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "block-baduser"
    priority = 10

    action {
      block {
        custom_response {
          response_code = 403
        }
      }
    }

    statement {
      byte_match_statement {
        field_to_match {
          single_query_argument {
            name = "id"
          }
        }

        positional_constraint = "CONTAINS"
        search_string         = "baduser"

        text_transformation {
          type     = "NONE"
          priority = 0
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "block-baduser"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "skills-waf"
    sampled_requests_enabled   = false
  }
}