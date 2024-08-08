data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_rotation" {
  name               = "lambda_rotation_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_rotation" {
  role       = aws_iam_role.lambda_rotation.name
  policy_arn = aws_iam_policy.lambda_rotation.arn
}

data "aws_iam_policy_document" "lambda_rotation" {
  statement {
    effect    = "Allow"
    resources = [aws_secretsmanager_secret.database.arn]

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
      "secretsmanager:DescribeSecret",
      "rds:ModifyDBCluster"
    ]
  }
}

resource "aws_iam_policy" "lambda_rotation" {
  name   = "lambda_rotation_policy"
  policy = data.aws_iam_policy_document.lambda_rotation.json
}

data "archive_file" "rotation" {
  type        = "zip"
  source_file = "function/rotation.py"
  output_path = "function/rotation.zip"
}

resource "aws_lambda_function" "rotation" {
  filename      = data.archive_file.rotation.output_path
  function_name = "SecretRotationFunction"
  role          = aws_iam_role.lambda_rotation.arn
  handler       = "rotation.lambda_handler"

  runtime          = "python3.12"
  source_code_hash = data.archive_file.rotation.output_base64sha256

  logging_config {
    log_format = "Text"
  }

  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.database.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logging
  ]
}

resource "aws_lambda_permission" "allow_secretsmanager" {
  statement_id  = "AllowSecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.database.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_rotation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}