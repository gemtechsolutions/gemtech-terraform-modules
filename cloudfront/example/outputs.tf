output "bucket_name" {
  value = module.cloudfront_static_site.s3_bucket_name
}

output "cloudfront_url" {
  value = "https://${module.cloudfront_static_site.cloudfront_domain_name}"
}

output "acm_cert" {
  value = module.cloudfront_static_site.acm_certificate_arn
}
