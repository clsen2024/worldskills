data "archive_file" "lambda" {
  type        = "zip"
  source_file = "function/lambda_edge.py"
  output_path = "function/lambda_edge.zip"
}

resource "aws_lambda_function" "edge" {
  provider = aws.us-east-1

  filename      = data.archive_file.lambda.output_path
  function_name = "hrdkorea-healthcheck"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_edge.lambda_handler"

  timeout          = 10
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"
  publish = true
}

resource "aws_iam_role" "lambda" {
  name               = "LambdaEdgeRole"
  assume_role_policy = data.aws_iam_policy_document.lambda.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "logging" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda" {
  name        = "LambdaEdgePolicy"
  path        = "/"
  description = "${aws_lambda_function.edge.function_name} IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:GetFunction",
          "lambda:EnableReplication*",
          "lambda:DisableReplication*",
          "iam:CreateServiceLinkedRole",
          "cloudfront:UpdateDistribution"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "edge" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}