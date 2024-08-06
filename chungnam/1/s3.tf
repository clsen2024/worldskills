resource "aws_s3_bucket" "static" {
  bucket        = "wsc2024-s3-static-${var.code}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudfront_allow" {
  bucket = aws_s3_bucket.static.id
  policy = data.aws_iam_policy_document.cloudfront_allow.json
}

resource "aws_s3_object" "static" {
  bucket = aws_s3_bucket.static.id
  key    = "index.html"
  source = "static/index.html"

  content_type = "index.html"
  source_hash  = filemd5("static/index.html")
}

data "aws_iam_policy_document" "cloudfront_allow" {
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.static.arn}/*"]
    actions   = ["s3:GetObject"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }
}