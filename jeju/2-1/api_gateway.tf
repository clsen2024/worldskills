resource "aws_api_gateway_rest_api" "main" {
  name = "serverless-api-gw"
  body = data.template_file.api.rendered

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

data "template_file" "api" {
  template = file("api.json")

  vars = {
    get_role_arn  = aws_iam_role.dynamodb_get.arn
    post_role_arn = aws_iam_role.dynamodb_put.arn
    table_name    = aws_dynamodb_table.main.name
  }
}

data "aws_iam_policy_document" "dynamodb_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dynamodb_put" {
  name               = "DynamodbPutRole"
  assume_role_policy = data.aws_iam_policy_document.dynamodb_assume.json
}

data "aws_iam_policy_document" "dynamodb_put" {
  statement {
    effect    = "Allow"
    resources = [aws_dynamodb_table.main.arn]
    actions   = ["dynamodb:PutItem"]
  }
}

resource "aws_iam_role_policy" "dynamodb_put" {
  name   = "DynamodbPutPolicy"
  role   = aws_iam_role.dynamodb_put.id
  policy = data.aws_iam_policy_document.dynamodb_put.json
}

resource "aws_iam_role" "dynamodb_get" {
  name               = "DynamodbGetRole"
  assume_role_policy = data.aws_iam_policy_document.dynamodb_assume.json
}

data "aws_iam_policy_document" "dynamodb_get" {
  statement {
    effect    = "Allow"
    resources = [aws_dynamodb_table.main.arn]
    actions   = ["dynamodb:GetItem"]
  }
}

resource "aws_iam_role_policy" "dynamodb_get" {
  name   = "DynamodbGetPolicy"
  role   = aws_iam_role.dynamodb_get.id
  policy = data.aws_iam_policy_document.dynamodb_get.json
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.main.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "v1" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "v1"
}