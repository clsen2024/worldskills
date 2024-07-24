terraform {
  required_providers {
    opensearch = {
      source = "opensearch-project/opensearch"
      version = "2.3.0"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  username = "admin"
  password = "Password01!"
  account_id = data.aws_caller_identity.current.account_id
}

provider "opensearch" {
  url = "https://${aws_opensearch_domain.main.endpoint}"
  username = local.username
  password = local.password
  sign_aws_requests = false
}