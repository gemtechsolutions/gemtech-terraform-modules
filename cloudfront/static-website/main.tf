resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.bucket_name}"
}


data "aws_iam_policy_document" "private_access" {
  statement {
    sid     = "AllowCloudFrontRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.website.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "website" {
  count  = length(var.cors_allowed_origins) > 0 ? 1 : 0
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_origins = var.cors_allowed_origins
    allowed_methods = var.cors_allowed_methods
    allowed_headers = var.cors_allowed_headers
    max_age_seconds = var.cors_max_age_seconds
  }
}

resource "aws_s3_bucket_policy" "private_access" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.private_access.json
}

locals {
  # "spa": every origin 403/404 becomes the app shell with a 200, so a
  # client-side router can resolve the path. "directory-index": the rewrite
  # function below has already mapped real pages onto real keys, so anything
  # still missing is genuinely missing and must say so with a 404 status.
  spa_fallback = var.private || var.routing_mode != "spa" ? [] : [
    { error_code = 404, response_code = 200, response_page_path = "/index.html" },
    { error_code = 403, response_code = 200, response_page_path = "/index.html" },
  ]

  # 403 is listed alongside 404 because the bucket policy grants s3:GetObject
  # but not s3:ListBucket, so S3 answers a missing key with AccessDenied rather
  # than NoSuchKey. Dropping it would leave a bare 403 for every typo'd URL.
  not_found_pages = (
    var.private || var.routing_mode != "directory-index" || var.not_found_page_path == null ? [] : [
      { error_code = 404, response_code = 404, response_page_path = var.not_found_page_path },
      { error_code = 403, response_code = 404, response_page_path = var.not_found_page_path },
    ]
  )

  custom_error_responses = concat(local.spa_fallback, local.not_found_pages)
}

resource "aws_cloudfront_function" "directory_index" {
  count = var.routing_mode == "directory-index" ? 1 : 0

  name    = "${replace(var.bucket_name, ".", "-")}-directory-index"
  runtime = "cloudfront-js-2.0"
  comment = "Append index.html to directory-style paths for ${var.domain_name}"
  publish = true
  code    = file("${path.module}/functions/directory-index.js")
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  default_root_object = "index.html"

  aliases = [var.domain_name]

  origin {
    origin_id   = "s3-origin"
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    # null (the default) attaches no policy, preserving prior behavior.
    response_headers_policy_id = var.response_headers_policy_id

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    trusted_key_groups = var.private ? [var.key_group_id] : null

    # CloudFront rejects a CloudFront Function and a Lambda@Edge on the same
    # event, so a viewer-request Lambda (which must then do the directory-index
    # rewrite itself) replaces the function's association. The function is
    # still created; only its association switches. Written as for-expressions
    # rather than count so an ARN that is unknown until apply still plans.
    dynamic "function_association" {
      for_each = [for f in aws_cloudfront_function.directory_index : f.arn if var.viewer_request_lambda_arn == null]
      content {
        event_type   = "viewer-request"
        function_arn = function_association.value
      }
    }

    dynamic "lambda_function_association" {
      for_each = [for arn in [var.viewer_request_lambda_arn] : arn if arn != null]
      content {
        event_type   = "viewer-request"
        lambda_arn   = lambda_function_association.value
        include_body = false
      }
    }

    forwarded_values {
      query_string = false

      headers = length(var.cors_allowed_origins) > 0 ? [
        "Origin",
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method",
      ] : []

      cookies {
        forward = "none"
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = local.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = 0
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.aws_acm_certificate
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = var.tags
}

resource "aws_route53_record" "alias" {
  count   = var.create_route53_alias_record ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
