variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string
}

variable "domain_name" {
  description = "Domain name for the ACM certificate."
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 Hosted Zone ID for domain validation."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "aws_acm_certificate" {
  description = "ARN of the existing ACM certificate to use for CloudFront"
  type        = string
}

variable "create_route53_alias_record" {
  description = "Whether to create a Route53 A record alias for the subdomain"
  type        = bool
  default     = false
}

variable "private" {
  description = "Whether to use CloudFront signed URLs via OAI."
  type        = bool
  default     = false
}

variable "key_group_id" {
  description = "ID of the CloudFront key group for signed URLs (if private)."
  type        = string
  default     = ""
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for S3 CORS configuration."
  type        = list(string)
  default     = []
}

variable "cors_allowed_methods" {
  description = "List of allowed HTTP methods for S3 CORS configuration."
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cors_allowed_headers" {
  description = "List of allowed headers for S3 CORS configuration."
  type        = list(string)
  default     = ["*"]
}

variable "cors_max_age_seconds" {
  description = "Time in seconds the browser can cache the preflight response."
  type        = number
  default     = 3600
}