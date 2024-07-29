resource "aws_dynamodb_table" "main" {
  name         = "gm-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  tags = {
    Name = "gm-db"
  }
}

resource "aws_s3_bucket" "main" {
  bucket        = "gm-0612"
  force_destroy = true
}

resource "aws_s3_bucket" "app" {
  bucket        = "application-temp-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_object" "app" {
  for_each = fileset("app/", "**")

  bucket = aws_s3_bucket.app.id
  key    = each.value
  source = "app/${each.value}"

  etag = filemd5("app/${each.value}")
}