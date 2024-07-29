resource "aws_s3_bucket" "app" {
  bucket_prefix = "wsi-application-"
  force_destroy = true
}

resource "aws_s3_object" "app" {
  for_each = fileset("app/", "*")

  bucket = aws_s3_bucket.app.id
  key    = each.value
  source = "app/${each.value}"

  etag = filemd5("app/${each.value}")
}