resource "aws_ecr_repository" "main" {
  name         = "wsc2024"
  force_delete = true
}

resource "null_resource" "ecr_push" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.us-west-1.amazonaws.com"
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.main.repository_url}:1 ./codecommit/app"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.main.repository_url}:1"
  }
}