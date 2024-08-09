resource "aws_s3_bucket" "static" {
  bucket        = "hrdkorea-static-${var.number}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudfront_allow" {
  bucket = aws_s3_bucket.static.id
  policy = data.aws_iam_policy_document.cloudfront_allow.json
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

resource "aws_s3_object" "static" {
  bucket = aws_s3_bucket.static.id

  key    = "static/index.html"
  source = "static/index.html"

  content_type = "text/html"
  source_hash  = filemd5("static/index.html")
}