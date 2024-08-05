provider "aws" {
  region = "ap-northeast-2"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  caller_arn = data.aws_caller_identity.current.arn
}

variable "number" {
  type = number
}