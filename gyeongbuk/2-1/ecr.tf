resource "aws_ecr_repository" "main" {
  name = "wsi"
  force_delete = true
}

resource "null_resource" "ecr_push" {
  provisioner "local-exec" {
    command = <<EOF
      aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.main.registry_id}
      docker build -t ${aws_ecr_repository.main.repository_url}:1 ./app
      docker push ${aws_ecr_repository.main.repository_url}:1
    EOF
  }
}