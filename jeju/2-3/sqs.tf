resource "aws_sqs_queue" "main" {
  name   = "j-sqs-queue"
  policy = data.aws_iam_policy_document.queue.json
}

data "aws_iam_policy_document" "queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:ap-northeast-2:${local.account_id}:j-sqs-queue"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.backup.arn]
    }
  }
}

resource "aws_s3_bucket_notification" "sqs" {
  bucket = aws_s3_bucket.backup.id

  queue {
    queue_arn     = aws_sqs_queue.main.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "2024/"
  }
}