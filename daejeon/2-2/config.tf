provider "aws" {
  region = "ap-northeast-2"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}