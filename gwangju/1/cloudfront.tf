resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name              = aws_s3_bucket.static.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    origin_id                = aws_s3_bucket.static.bucket
  }

  enabled         = true
  is_ipv6_enabled = false
  comment         = "CloudFront for S3, NLB"
  web_acl_id      = aws_wafv2_web_acl.main.arn

  default_cache_behavior {
    cache_policy_id  = data.aws_cloudfront_cache_policy.caching_optimized.id
    target_origin_id = aws_s3_bucket.static.bucket

    allowed_methods = ["GET", "HEAD"]
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

  tags = {
    Name = "skills-cdn"
  }
}

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = aws_s3_bucket.static.bucket
  description                       = "CloudFront OAC for ${aws_s3_bucket.static.bucket}"
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