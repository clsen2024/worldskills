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
      namespace_service_accounts = ["wsi:access-dynamodb"]
    }
  }
}

data "aws_iam_policy_document" "fluent-bit" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy"
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
      namespace_service_accounts = ["amazon-cloudwatch:fluent-bit"]
    }
  }
}

module "aws_load_balancer_controller" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "AmazonEKSLoadBalancerControllerRole"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

data "aws_iam_policy_document" "external-secret" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
  }
}

resource "aws_iam_policy" "external-secret" {
  name   = "ExternalSecretsPolicy"
  policy = data.aws_iam_policy_document.external-secret.json
}

module "external-secret" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "ExternalSecretsRole"

  role_policy_arns = {
    policy = aws_iam_policy.external-secret.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["wsi:access-secrets"]
    }
  }
}