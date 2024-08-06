resource "aws_s3_bucket" "static-ap" {
  bucket        = "ap-wsi-static-${var.code}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "static-ap" {
  bucket = aws_s3_bucket.static-ap.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static-ap" {
  bucket = aws_s3_bucket.static-ap.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "cloudfront_allow_ap" {
  bucket = aws_s3_bucket.static-ap.id
  policy = data.aws_iam_policy_document.cloudfront_allow_ap.json
}

resource "aws_s3_object" "static-ap" {
  for_each = fileset("static/", "**")

  bucket = aws_s3_bucket.static-ap.id
  key    = each.value
  source = "static/${each.value}"

  content_type = lookup(local.content_type_map, split(".", "static/${each.value}")[1], "text/css")
  source_hash  = filemd5("static/${each.value}")

  depends_on = [aws_s3_bucket_replication_configuration.replication]
}

data "aws_iam_policy_document" "cloudfront_allow_ap" {
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.static-ap.arn}/*"]
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

resource "aws_s3_bucket" "static-us" {
  provider      = aws.us-east-1
  bucket        = "us-wsi-static-${var.code}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "static-us" {
  provider = aws.us-east-1
  bucket   = aws_s3_bucket.static-us.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static-us" {
  provider = aws.us-east-1
  bucket   = aws_s3_bucket.static-us.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.us.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "cloudfront_allow_us" {
  provider = aws.us-east-1
  bucket   = aws_s3_bucket.static-us.id
  policy   = data.aws_iam_policy_document.cloudfront_allow_us.json
}

data "aws_iam_policy_document" "cloudfront_allow_us" {
  provider = aws.us-east-1
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.static-us.arn}/*"]
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

resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.static-ap.id

  rule {
    id     = "All-Replication"
    status = "Enabled"

    filter {}

    destination {
      bucket        = aws_s3_bucket.static-us.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.us.arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    delete_marker_replication {
      status = "Disabled"
    }
  }

  depends_on = [aws_s3_bucket_versioning.static-ap]
}

data "aws_iam_policy_document" "s3_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "replication" {
  name               = "S3ReplicationRole"
  assume_role_policy = data.aws_iam_policy_document.s3_assume.json
}

data "aws_iam_policy_document" "replication" {
  statement {
    effect = "Allow"

    resources = [
      aws_s3_bucket.static-ap.arn,
      "${aws_s3_bucket.static-ap.arn}/*",
    ]

    actions = [
      "s3:ListBucket",
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["${aws_s3_bucket.static-us.arn}/*"]

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]

    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "aws:kms",
        "aws:kms:dsse",
        "AES256",
      ]
    }
  }

  statement {
    effect    = "Allow"
    resources = [aws_kms_key.main.arn]
    actions   = ["kms:Decrypt"]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.ap-northeast-2.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [aws_s3_bucket.static-ap.arn]
    }
  }

  statement {
    effect    = "Allow"
    resources = [aws_kms_key.us.arn]
    actions   = ["kms:Encrypt"]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.us-east-1.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [aws_s3_bucket.static-us.arn]
    }
  }
}

resource "aws_iam_policy" "replication" {
  name   = "S3ReplicationPolicy"
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}