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