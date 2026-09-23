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

variable "response_headers_policy_id" {
  description = <<-EOT
    Optional ID of an aws_cloudfront_response_headers_policy to attach to the
    default cache behavior. Leave null (the default) to preserve the existing
    behavior of attaching no policy.

    Consumers use this to add security or cross-origin headers (for example
    Cross-Origin-Opener-Policy / Cross-Origin-Embedder-Policy, which browsers
    require before a page may use SharedArrayBuffer and WASM threads).
  EOT
  type        = string
  default     = null
}

variable "routing_mode" {
  description = <<-EOT
    How CloudFront resolves a request whose path is not a literal S3 object key.

    "spa" (the default, and the historical behavior): 403/404 from the origin is
    rewritten to /index.html with a 200, so a client-side router can take over.
    Correct for a single-page app; wrong for a pre-rendered multi-page site,
    where it silently serves the home page for EVERY deep link, with a 200 that
    nothing downstream can flag as an error.

    "directory-index": a viewer-request CloudFront Function appends index.html
    to a directory-style path before the origin is consulted, so /docs/page/
    fetches the real /docs/page/index.html. Genuinely missing paths are then
    served /404.html with a 404, which is what a static site generator emits.
    Use this for Docusaurus, Hugo, Jekyll, Next export, mkdocs and similar.

    An S3 REST origin (what this module uses, via OAI) has no directory-index
    behavior of its own, and default_root_object applies only to "/", so one of
    these two mechanisms is always required.
  EOT
  type        = string
  default     = "spa"

  validation {
    condition     = contains(["spa", "directory-index"], var.routing_mode)
    error_message = "routing_mode must be either \"spa\" or \"directory-index\"."
  }
}

variable "not_found_page_path" {
  description = <<-EOT
    routing_mode = "directory-index" only: the object served, with a real 404
    status, when a path resolves to no object. Static site generators emit
    /404.html. Set to null to let the origin's own 403/404 surface untouched.
  EOT
  type        = string
  default     = "/404.html"
}
