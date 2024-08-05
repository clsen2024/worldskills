resource "aws_cloudwatch_log_group" "customer" {
  name       = "/wsi/webapp/customer"
  kms_key_id = aws_kms_key.main.arn
}

resource "aws_cloudwatch_log_group" "product" {
  name       = "/wsi/webapp/product"
  kms_key_id = aws_kms_key.main.arn
}

resource "aws_cloudwatch_log_group" "order" {
  name       = "/wsi/webapp/order"
  kms_key_id = aws_kms_key.main.arn
}