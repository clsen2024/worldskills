resource "aws_ecr_repository" "customer" {
  name         = "customer"
  force_delete = true
}

resource "aws_ecr_repository" "product" {
  name         = "product"
  force_delete = true
}

resource "aws_ecr_repository" "order" {
  name         = "order"
  force_delete = true
}

resource "null_resource" "ecr_push" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com"
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