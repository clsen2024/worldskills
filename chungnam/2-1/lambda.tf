data "archive_file" "lambda" {
  type        = "zip"
  source_file = "function/main.py"
  output_path = "function/main.zip"
}

resource "aws_lambda_function" "main" {
  filename      = "function/main.zip"
  function_name = "wsc2024-gvn-Lambda"
  role          = aws_iam_role.lambda.arn
  handler       = "main.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.9"

  logging_config {
    log_format = "Text"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logging,
    aws_cloudwatch_log_group.lambda,
  ]
}

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

resource "aws_iam_role" "lambda" {
  name               = "lambdaRole"
  assume_role_policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_iam" {
  statement {
    sid       = "Statement1"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "iam:ListAttachedRolePolicies",
      "iam:DetachRolePolicy",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_iam" {
  role   = aws_iam_role.lambda.name
  policy = data.aws_iam_policy_document.lambda_iam.json
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = aws_cloudwatch_metric_alarm.main.arn
}

resource "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/wsc2024-gvn-Lambda"
}