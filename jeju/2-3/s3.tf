resource "aws_s3_bucket" "original" {
  bucket = "j-s3-bucket-hellohi-original"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "original" {
  bucket = aws_s3_bucket.original.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "backup" {
  bucket = "j-s3-bucket-hellohi-backup"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "backup" {
  bucket = aws_s3_bucket.backup.id
  policy = data.aws_iam_policy_document.backup.json
}

data "aws_iam_policy_document" "backup" {
  statement {
    effect    = "Deny"
    resources = ["${aws_s3_bucket.backup.arn}/*/*"]
    actions   = ["s3:PutObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.original.id

  rule {
    id = "2024-Replication"

    filter {
      prefix = "2024/"
    }

    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.backup.arn
      storage_class = "STANDARD"
    }

    delete_marker_replication {
      status = "Disabled"
    }
  }

  depends_on = [aws_s3_bucket_versioning.original]
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

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.original.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${aws_s3_bucket.original.arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["${aws_s3_bucket.backup.arn}/*"]
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