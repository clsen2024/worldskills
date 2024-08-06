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

resource "aws_kms_key" "us" {
  provider            = aws.us-east-1
  enable_key_rotation = true
}

resource "aws_kms_alias" "us" {
  provider      = aws.us-east-1
  name          = "alias/wsi"
  target_key_id = aws_kms_key.us.key_id
}

resource "aws_kms_key_policy" "us" {
  provider = aws.us-east-1
  key_id   = aws_kms_key.us.id
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