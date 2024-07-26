resource "aws_cloudtrail" "main" {
  name                  = "cg-trail"
  s3_bucket_name        = aws_s3_bucket.main.id

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.main.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail.arn

  depends_on = [aws_s3_bucket_policy.main]
}

data "aws_iam_policy_document" "cloudtrail_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail" {
  name               = "CloudTrailForCloudWatchLogs"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume.json
}

data "aws_iam_policy_document" "cloudtrail_policy" {
  statement {
    sid       = "AWSCloudTrailCreateLogStream2014110"
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.main.arn}:log-stream:${local.account_id}_CloudTrail_ap-northeast-2*"]
    actions   = ["logs:CreateLogStream"]
  }

  statement {
    sid       = "AWSCloudTrailPutLogEvents20141101"
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.main.arn}:log-stream:${local.account_id}_CloudTrail_ap-northeast-2*"]
    actions   = ["logs:PutLogEvents"]
  }
}

resource "aws_iam_role_policy" "cloudtrail" {
  role   = aws_iam_role.cloudtrail.name
  policy = data.aws_iam_policy_document.cloudtrail_policy.json
}

resource "aws_s3_bucket" "main" {
  bucket        = "aws-cloudtrail-logs-${local.account_id}"
  force_destroy = true
}

data "aws_iam_policy_document" "main" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.main.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:ap-northeast-2:${local.account_id}:trail/cg-trail"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.main.arn}/AWSLogs/${local.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:ap-northeast-2:${local.account_id}:trail/cg-trail"]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.main.json
}