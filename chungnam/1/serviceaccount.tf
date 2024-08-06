data "aws_iam_policy_document" "order" {
  statement {
    effect    = "Allow"
    resources = [aws_dynamodb_table.main.arn]

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

module "order" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "AccessDynamodbRole"

  role_policy_arns = {
    policy = aws_iam_policy.order.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["wsc2024:access-dynamodb"]
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