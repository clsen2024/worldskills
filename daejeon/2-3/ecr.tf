resource "aws_ecr_repository" "main" {
  name         = "wsi-app"
  force_delete = true
}

resource "null_resource" "ecr_push" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com"
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.main.repository_url}:1 ./app"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.main.repository_url}:1"
  }
}