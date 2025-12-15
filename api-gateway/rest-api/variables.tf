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

# Cognito Authorizer Configuration
variable "enable_cognito_authorizer" {
  description = "Enable Cognito authorizer for REST API"
  type        = bool
  default     = false
}

variable "cognito_user_pool_arns" {
  description = "List of Cognito User Pool ARNs for authorization"
  type        = list(string)
  default     = []
}

variable "authorizer_name" {
  description = "Name of the Cognito authorizer"
  type        = string
  default     = "CognitoAuthorizer"
}

variable "identity_source" {
  description = "Source of the identity in the incoming request (e.g., method.request.header.Authorization)"
  type        = string
  default     = "method.request.header.Authorization"
}

variable "authorizer_result_ttl_in_seconds" {
  description = "TTL of cached authorizer results in seconds (0-3600). Set to 0 to disable caching."
  type        = number
  default     = 300
}
