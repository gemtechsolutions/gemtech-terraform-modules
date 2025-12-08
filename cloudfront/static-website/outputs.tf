output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket."
  value       = aws_s3_bucket.website.id
}

output "acm_certificate_arn" {
  value = var.aws_acm_certificate
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.cdn.id
}