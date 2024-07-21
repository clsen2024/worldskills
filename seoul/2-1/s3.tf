resource "aws_s3_bucket" "main" {
  bucket        = "wsi-static-arco"
  force_destroy = true
}

resource "aws_s3_object" "main" {
  for_each = fileset("static/", "**")

  bucket = aws_s3_bucket.main.id
  key    = each.value
  source = "static/${each.value}"

  content_type = lookup(local.content_type_map, split(".", "static/${each.value}")[1], "application/x-directory")
  etag         = filemd5("static/${each.value}")
}

resource "aws_s3_object" "dev" {
  bucket = aws_s3_bucket.main.id
  key    = "dev/"
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json
}

data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}