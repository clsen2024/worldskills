resource "aws_cloudfront_distribution" "main" {
  origin_group {
    origin_id = "static"

    failover_criteria {
      status_codes = [403]
    }

    member {
      origin_id = aws_s3_bucket.static-ap.bucket
    }

    member {
      origin_id = aws_s3_bucket.static-us.bucket
    }
  }

  origin {
    domain_name              = aws_s3_bucket.static-ap.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.ap.id
    origin_id                = aws_s3_bucket.static-ap.bucket
  }

  origin {
    domain_name              = aws_s3_bucket.static-us.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.us.id
    origin_id                = aws_s3_bucket.static-us.bucket
  }

  origin {
    domain_name = aws_alb.main.dns_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1"]
    }
    origin_id = aws_alb.main.name
  }

  enabled         = true
  is_ipv6_enabled = false
  comment         = "CloudFront for S3, ALB"

  default_cache_behavior {
    cache_policy_id  = data.aws_cloudfront_cache_policy.caching_optimized.id
    target_origin_id = "static"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern             = "/v1/*"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
    target_origin_id         = aws_alb.main.name

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_code         = 403
    response_code      = 503
    response_page_path = "/error.html"
  }

  tags = {
    Name = "wsi-cdn"
  }
}

resource "aws_cloudfront_origin_access_control" "ap" {
  name                              = aws_s3_bucket.static-ap.bucket
  description                       = "CloudFront OAC for ${aws_s3_bucket.static-ap.bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "us" {
  name                              = aws_s3_bucket.static-us.bucket
  description                       = "CloudFront OAC for ${aws_s3_bucket.static-us.bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}