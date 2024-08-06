resource "aws_ecr_repository" "customer" {
  name         = "customer-repo"
  force_delete = true
}

resource "aws_ecr_repository_policy" "customer_policy" {
  repository = aws_ecr_repository.customer.name
  policy     = data.aws_iam_policy_document.deny_bastion.json
}

resource "aws_ecr_repository" "product" {
  name         = "product-repo"
  force_delete = true
}

resource "aws_ecr_repository_policy" "product_policy" {
  repository = aws_ecr_repository.product.name
  policy     = data.aws_iam_policy_document.deny_bastion.json
}

resource "aws_ecr_repository" "order" {
  name         = "order-repo"
  force_delete = true
}

resource "aws_ecr_repository_policy" "order_policy" {
  repository = aws_ecr_repository.order.name
  policy     = data.aws_iam_policy_document.deny_bastion.json
}

data "aws_iam_policy_document" "deny_bastion" {
  statement {
    sid    = "DenyPull"
    effect = "Deny"

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.admin.arn]
    }
  }
}

resource "null_resource" "ecr_push" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.us-east-1.amazonaws.com"
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.customer.repository_url} ../../app-1/customer"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.customer.repository_url}"
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.product.repository_url} ../../app-1/product"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.product.repository_url}"
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.order.repository_url} ../../app-1/order"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.order.repository_url}"
  }
}