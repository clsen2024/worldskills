resource "aws_iam_user" "tester" {
  name = "tester"
}

resource "aws_iam_user_policy_attachment" "admin" {
  user       = aws_iam_user.tester.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "mfa" {
  statement {
    sid       = "Statement1"
    effect    = "Deny"
    resources = ["*"]
    actions   = ["s3:DeleteObject"]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "mfa" {
  name        = "mfaBucketDeleteControl"
  path        = "/"
  description = "MFA Bucket Delete Control Policy"

  policy = data.aws_iam_policy_document.mfa.json
}

resource "aws_iam_user_policy_attachment" "mfa" {
  user       = aws_iam_user.tester.name
  policy_arn = aws_iam_policy.mfa.arn
}

resource "aws_iam_group" "kr" {
  name = "user_group_kr"
}

resource "aws_iam_group_membership" "team" {
  name = aws_iam_group.kr.name

  users = [
    aws_iam_user.tester.name
  ]

  group = aws_iam_group.kr.name
}

data "aws_iam_policy_document" "kr" {
  statement {
    sid       = "Statement1"
    effect    = "Deny"
    resources = ["*"]
    actions   = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = ["ap-northeast-2"]
    }
  }
}

resource "aws_iam_policy" "kr" {
  name        = "regionAccessControl"
  path        = "/"
  description = "Region Access Control Policy"

  policy = data.aws_iam_policy_document.kr.json
}

resource "aws_iam_group_policy_attachment" "kr" {
  group      = aws_iam_group.kr.name
  policy_arn = aws_iam_policy.kr.arn
}