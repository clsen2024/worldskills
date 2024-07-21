provider "aws" {
  region = "ap-northeast-2"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

locals {
  content_type_map = {
    "jpg"  = "image/jpeg"
    "html" = "text/html"
  }
}