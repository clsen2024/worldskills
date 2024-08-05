provider "aws" {
  region = "ap-northeast-2"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  caller_arn = data.aws_caller_identity.current.arn
}