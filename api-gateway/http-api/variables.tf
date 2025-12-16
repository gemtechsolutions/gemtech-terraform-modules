variable "environment" {
  description = "Deployment environment (e.g., production, staging, test)"
  type        = string
}

variable "api_name" {
  description = "Name of the HTTP API Gateway"
  type        = string
}

variable "api_description" {
  description = "Description of the HTTP API Gateway"
  type        = string
  default     = "HTTP API Gateway"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
}

variable "api_resources" {
  description = "Map of API resources and their configurations"
  type = map(object({
    path_part     = string
    lambda_arn    = optional(string)
    parent_key    = optional(string)
    authorization = optional(string)
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

variable "enable_cors" {
  description = "Enable CORS support for HTTP API"
  type        = bool
  default     = true
}

variable "cors_configuration" {
  description = "CORS configuration overrides when enable_cors is true"
  type = object({
    allow_credentials = optional(bool)
    allow_headers     = optional(list(string))
    allow_methods     = optional(list(string))
    allow_origins     = optional(list(string))
    expose_headers    = optional(list(string))
    max_age           = optional(number)
  })
  default = {}
}

variable "payload_format_version" {
  description = "Payload format version for integrations (1.0 or 2.0)"
  type        = string
  default     = "2.0"
}

variable "enable_metrics" {
  description = "Enable CloudWatch metrics for HTTP API"
  type        = bool
  default     = true
}

variable "logging_level" {
  description = "Logging level for HTTP API (OFF, ERROR, INFO)"
  type        = string
  default     = "INFO"
}

variable "enable_data_trace" {
  description = "Enable full request/response data logging"
  type        = bool
  default     = false
}

variable "throttling_burst_limit" {
  description = "HTTP API throttling burst limit"
  type        = number
  default     = 5000
}

variable "throttling_rate_limit" {
  description = "HTTP API throttling rate limit (requests per second)"
  type        = number
  default     = 10000
}

variable "enable_access_logging" {
  description = "Enable access logging for HTTP API"
  type        = bool
  default     = true
}

# Cognito Authorizer Configuration
variable "enable_cognito_authorizer" {
  description = "Enable Cognito authorizer for HTTP API"
  type        = bool
  default     = false
}

variable "cognito_user_pool_arns" {
  description = "Optional list of Cognito User Pool ARNs (legacy). Used only to derive the pool ID if cognito_user_pool_id is not provided."
  type        = list(string)
  default     = []
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID used to build the JWT issuer URL"
  type        = string
  default     = null
}

variable "cognito_audience" {
  description = "Allowed audiences (typically Cognito App Client IDs) for the JWT authorizer"
  type        = list(string)
  default     = []
}

variable "authorizer_name" {
  description = "Name of the Cognito authorizer"
  type        = string
  default     = "CognitoAuthorizer"
}

variable "identity_source" {
  description = "Identity sources for the authorizer (e.g., $request.header.Authorization)"
  type        = list(string)
  default     = ["$request.header.Authorization"]
}
