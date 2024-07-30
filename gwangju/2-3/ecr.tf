resource "aws_ecr_repository" "service-a" {
  name         = "service-a"
  force_delete = true
}

resource "aws_ecr_repository" "service-b" {
  name         = "service-b"
  force_delete = true
}

resource "aws_ecr_repository" "service-c" {
  name         = "service-c"
  force_delete = true
}

resource "null_resource" "ecr_push" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com"
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.service-a.repository_url}:1 ./app/service-a"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.service-a.repository_url}:1"
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.service-b.repository_url}:1 ./app/service-b"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.service-b.repository_url}:1"
  }

  provisioner "local-exec" {
    command = "docker build -t ${aws_ecr_repository.service-c.repository_url}:1 ./app/service-c"
  }

  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.service-c.repository_url}:1"
  }
}