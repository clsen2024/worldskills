data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "preserve" {
  name               = "PreserveSecurityGroupRole"
  assume_role_policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_policy" "preserve" {
  name        = "PreserveSecurityGroupPolicy"
  path        = "/"
  description = "${aws_lambda_function.preserve.function_name} IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "preserve" {
  role       = aws_iam_role.preserve.name
  policy_arn = aws_iam_policy.preserve.arn
}

data "archive_file" "preserve" {
  type        = "zip"
  source_file = "function/main.py"
  output_path = "function/main.zip"
}

resource "aws_lambda_function" "preserve" {
  filename      = data.archive_file.preserve.output_path
  function_name = "wsi-preserve-sg"
  role          = aws_iam_role.preserve.arn
  handler       = "main.lambda_handler"

  source_code_hash = data.archive_file.preserve.output_base64sha256

  runtime = "python3.12"
}

resource "aws_lambda_permission" "preserve" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.preserve.arn
  principal     = "config.amazonaws.com"
  statement_id  = "AllowExecutionFromConfig"
}