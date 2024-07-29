data "archive_file" "lambda" {
  type        = "zip"
  source_file = "function/main.py"
  output_path = "function/main.zip"
}

resource "aws_lambda_function" "main" {
  filename      = "function/main.zip"
  function_name = "wsi-project-log-function"
  role          = aws_iam_role.lambda.arn
  handler       = "main.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.12"

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

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/wsi-project-log-function"
}