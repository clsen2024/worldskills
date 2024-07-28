resource "aws_s3_bucket" "config" {
  bucket        = "config-bucket-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id
  policy = data.aws_iam_policy_document.config.json
}

data "aws_iam_policy_document" "config" {
  statement {
    sid       = "AWSConfigBucketPermissionsCheck"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.config.arn}"]
    actions   = ["s3:GetBucketAcl"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = ["${local.account_id}"]
    }

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSConfigBucketExistenceCheck"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.config.arn}"]
    actions   = ["s3:ListBucket"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = ["${local.account_id}"]
    }

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSConfigBucketDelivery"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.config.arn}/AWSLogs/${local.account_id}/Config/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = ["${local.account_id}"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}