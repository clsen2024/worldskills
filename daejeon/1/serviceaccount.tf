# ap-northeast-2
module "ap-order" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "AccessDynamodbRole-ap"

  role_policy_arns = {
    policy = aws_iam_policy.order.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.ap-eks.arn
      namespace_service_accounts = ["hrdkorea:access-dynamodb"]
    }
  }
}

module "ap-aws_load_balancer_controller" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "AmazonEKSLoadBalancerControllerRole-ap"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.ap-eks.arn
      namespace_service_accounts = ["hrdkorea:aws-load-balancer-controller"]
    }
  }
}

module "ap-external_secret" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "ExternalSecretsRole-ap"

  role_policy_arns = {
    policy = aws_iam_policy.external_secret.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.ap-eks.arn
      namespace_service_accounts = ["hrdkorea:access-secrets"]
    }
  }
}

# us-east-1
module "us-order" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "AccessDynamodbRole-us"

  role_policy_arns = {
    policy = aws_iam_policy.order.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.us-eks.arn
      namespace_service_accounts = ["hrdkorea:access-dynamodb"]
    }
  }
}

module "us-aws_load_balancer_controller" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "AmazonEKSLoadBalancerControllerRole-us"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.us-eks.arn
      namespace_service_accounts = ["hrdkorea:aws-load-balancer-controller"]
    }
  }
}

module "us-external_secret" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "ExternalSecretsRole-us"

  role_policy_arns = {
    policy = aws_iam_policy.external_secret.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.us-eks.arn
      namespace_service_accounts = ["hrdkorea:access-secrets"]
    }
  }
}

# global
data "aws_iam_policy_document" "order" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem"
    ]
  }
}

resource "aws_iam_policy" "order" {
  name   = "AccessDynamodbPolicy"
  policy = data.aws_iam_policy_document.order.json
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