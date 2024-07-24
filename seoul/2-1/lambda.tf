data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "function/lambda_edge"
  output_path = "function/lambda_edge.zip"
}

resource "aws_lambda_function" "edge" {
  provider = aws.us_east_1

  filename      = data.archive_file.lambda.output_path
  function_name = "wsi-resizing-function"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"

  timeout          = 10
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs20.x"
  publish = true
}

resource "aws_iam_role" "lambda" {
  name               = "ResizingFunctionRole"
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
  name        = "ResizingFunctionPolicy"
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
          "cloudfront:UpdateDistribution",
          "s3:GetObject"
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