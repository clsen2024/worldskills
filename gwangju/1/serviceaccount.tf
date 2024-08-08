data "aws_iam_policy_document" "order" {
  statement {
    effect    = "Allow"
    resources = [aws_dynamodb_table.main.arn]

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem"
    ]
  }

  statement {
    effect    = "Allow"
    resources = [aws_kms_key.main.arn]
    actions   = ["kms:Decrypt"]
  }
}

resource "aws_iam_policy" "order" {
  name   = "AccessDynamodbPolicy"
  policy = data.aws_iam_policy_document.order.json
}

module "order" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "AccessDynamodbRole"

  role_policy_arns = {
    policy = aws_iam_policy.order.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["app:access-dynamodb"]
    }
  }
}

data "aws_iam_policy_document" "fluent-bit" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "es:ESHttp*"
    ]
  }
}

resource "aws_iam_policy" "fluent-bit" {
  name   = "FluentBitIAMPolicy"
  policy = data.aws_iam_policy_document.fluent-bit.json
}

module "fluent-bit" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "FluentBitIAMRole"

  role_policy_arns = {
    policy = aws_iam_policy.fluent-bit.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["default:fluent-bit"]
    }
  }
}

data "aws_iam_policy_document" "external_secret" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
  }
}

resource "aws_iam_policy" "external_secret" {
  name   = "ExternalSecretsPolicy"
  policy = data.aws_iam_policy_document.external_secret.json
}

module "external_secret" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "ExternalSecretsRole"

  role_policy_arns = {
    policy = aws_iam_policy.external_secret.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["app:access-secrets"]
    }
  }
}