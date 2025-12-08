variable "environment" {
  description = "Deployment environment (e.g., production, staging, test)"
  type        = string
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "REST API Gateway"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
}

variable "endpoint_type" {
  description = "API Gateway endpoint type (EDGE, REGIONAL, PRIVATE)"
  type        = string
  default     = "REGIONAL"
}

variable "api_resources" {
  description = "Map of API resources and their configurations"
  type = map(object({
    path_part  = string
    lambda_arn = optional(string)
    parent_key = optional(string)
    methods = map(object({
      integration_uri     = string
      status_code         = string
      response_models     = map(string)
      response_parameters = map(any)
    }))
    proxy = bool
  }))
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing for API Gateway"
  type        = bool
  default     = false
}

variable "enable_metrics" {
  description = "Enable CloudWatch metrics for API Gateway"
  type        = bool
  default     = true
}

variable "logging_level" {
  description = "Logging level for API Gateway (OFF, ERROR, INFO)"
  type        = string
  default     = "INFO"
}

variable "enable_data_trace" {
  description = "Enable full request/response data logging"
  type        = bool
  default     = false
}

variable "throttling_burst_limit" {
  description = "API Gateway throttling burst limit"
  type        = number
  default     = 5000
}

variable "throttling_rate_limit" {
  description = "API Gateway throttling rate limit (requests per second)"
  type        = number
  default     = 10000
}

variable "enable_cors" {
  description = "Enable CORS support for API Gateway"
  type        = bool
  default     = true
}
