resource "aws_s3_bucket" "docker" {
  bucket        = "dockerfile-temp-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_object" "docker" {
  bucket = aws_s3_bucket.docker.id
  key    = "Dockerfile"
  source = "codecommit/app/Dockerfile"
  etag   = filemd5("codecommit/app/Dockerfile")
}