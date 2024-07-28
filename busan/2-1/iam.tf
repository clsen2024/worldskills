resource "aws_iam_user" "user1" {
  name = "wsi-project-user1"
}

data "aws_iam_policy_document" "user1" {
  statement {
    sid       = "AllowToDescribeAll"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:Describe*"]
  }

  statement {
    sid    = "AllowRunInstances"
    effect = "Allow"

    resources = [
      "arn:aws:ec2:*::image/*",
      "arn:aws:ec2:*::snapshot/*",
      "arn:aws:ec2:*:*:subnet/*",
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:key-pair/*",
      "arn:aws:ec2:*:*:volume/*",
    ]

    actions = ["ec2:RunInstances"]
  }

  statement {
    sid       = "AllowRunInstancesWithRestrictions"
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:instance/*"]
    actions   = ["ec2:RunInstances"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/wsi-project"
      values   = ["developer"]
    }
  }

  statement {
    sid       = "AllowCreateTagsOnlyLaunching"
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:instance/*"]
    actions   = ["ec2:CreateTags"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["RunInstances"]
    }
  }
}

resource "aws_iam_user_policy" "user1" {
  user       = aws_iam_user.user1.name
  policy = data.aws_iam_policy_document.user1.json
}

resource "aws_iam_user" "user2" {
  name = "wsi-project-user2"
}

data "aws_iam_policy_document" "user2" {
  statement {
    sid       = "AllowToDescribeAll"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:Describe*"]
  }

  statement {
    sid       = "AllowTerminateInstancesWithRestrictions"
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:instance/*"]
    actions   = ["ec2:TerminateInstances"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/wsi-project"
      values   = ["developer"]
    }
  }
}

resource "aws_iam_user_policy" "user2" {
  user       = aws_iam_user.user2.name
  policy = data.aws_iam_policy_document.user2.json
}