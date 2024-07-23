resource "aws_s3_bucket" "app" {
  bucket_prefix = "wsi-application-"
  force_destroy = true
}

resource "aws_s3_object" "main" {
  bucket = aws_s3_bucket.app.id
  key    = "main.py"
  source = "app/main.py"
  etag   = filemd5("app/main.py")
}

resource "aws_s3_object" "requirements" {
  bucket = aws_s3_bucket.app.id
  key    = "requirements.txt"
  source = "app/requirements.txt"
  etag   = filemd5("app/requirements.txt")
}