resource "aws_ecr_repository" "hrdkorea" {
  name = "hrdkorea-ecr-repo"
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
}

resource "aws_ecr_replication_configuration" "hrdkorea" {
  replication_configuration {
    rule {
      destination {
        region      = "us-east-1"
        registry_id = local.account_id
      }
    }
  }
}

resource "null_resource" "ecr_push" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com"
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.hrdkorea.repository_url}:customer ../../app-1/customer"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.hrdkorea.repository_url}:customer"
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.hrdkorea.repository_url}:product ../../app-1/product"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.hrdkorea.repository_url}:product"
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.hrdkorea.repository_url}:order ../../app-1/order"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.hrdkorea.repository_url}:order"
  }
}