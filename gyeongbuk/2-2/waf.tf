resource "aws_wafv2_web_acl" "app" {
  name  = "wsi-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  custom_response_body {
    key          = "unauthorized"
    content      = "Blocked by WAF"
    content_type = "TEXT_PLAIN"
  }

  rule {
    name     = "none-block"
    priority = 1

    action {
      block {
        custom_response {
          custom_response_body_key = "unauthorized"
          response_code            = 401
        }
      }
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }

            positional_constraint = "EXACTLY"
            search_string         = "/v1/token/verify"

            text_transformation {
              type     = "NONE"
              priority = 0
            }
          }
        }

        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "authorization"
              }
            }

            positional_constraint = "CONTAINS"
            search_string         = "none"

            text_transformation {
              type     = "BASE64_DECODE"
              priority = 0
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "none-block"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "wsi-waf"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "app" {
  resource_arn = aws_alb.app.arn
  web_acl_arn  = aws_wafv2_web_acl.app.arn
}