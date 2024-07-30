data "aws_iam_policy_document" "fluent-bit" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy",
    ]
  }
}

resource "aws_iam_policy" "fluent-bit" {
  name   = "FluentBitIAMPolicy"
  policy = data.aws_iam_policy_document.fluent-bit.json
}

module "iam_eks_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "FluentBitIAMRole"

  role_policy_arns = {
    policy = aws_iam_policy.fluent-bit.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["wsi-ns:fluent-bit"]
    }
  }
}