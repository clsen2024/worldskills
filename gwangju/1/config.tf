terraform {
  required_providers {
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "2.3.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "opensearch" {
  url               = "https://${aws_opensearch_domain.main.endpoint}"
  username          = local.username
  password          = local.password
  sign_aws_requests = false
}

data "aws_caller_identity" "current" {}

locals {
  username   = "admin"
  password   = "Password01!"
  account_id = data.aws_caller_identity.current.account_id
  caller_arn = data.aws_caller_identity.current.arn
}

variable "code" {
  type = string
}