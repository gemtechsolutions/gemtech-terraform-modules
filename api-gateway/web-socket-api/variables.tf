variable "environment" {
  description = "Deployment environment (e.g., production, staging, test)"
  type        = string
}

variable "api_name" {
  description = "Name of the WebSocket API Gateway"
  type        = string
}

variable "api_description" {
  description = "Description of the WebSocket API Gateway"
  type        = string
  default     = "WebSocket API Gateway"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
}

variable "route_selection_expression" {
  description = "Route selection expression for the WebSocket API"
  type        = string
  default     = "$request.body.action"
}

variable "routes" {
  description = "Map of WebSocket routes and their Lambda function integrations"
  type = map(object({
    route_key              = string
    lambda_arn             = string
    integration_method     = optional(string, "POST")
    content_handling       = optional(string)
    passthrough_behavior   = optional(string, "WHEN_NO_MATCH")
    timeout_milliseconds   = optional(number, 29000)
  }))
  default = {}
}

variable "connect_lambda_arn" {
  description = "Lambda ARN for $connect route"
  type        = string
  default     = null
}

variable "disconnect_lambda_arn" {
  description = "Lambda ARN for $disconnect route"
  type        = string
  default     = null
}

variable "default_lambda_arn" {
  description = "Lambda ARN for $default route"
  type        = string
  default     = null
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

variable "enable_access_logging" {
  description = "Enable access logging for WebSocket API"
  type        = bool
  default     = true
}

variable "logging_level" {
  description = "Logging level for WebSocket API (OFF, ERROR, INFO)"
  type        = string
  default     = "INFO"
}

variable "data_trace_enabled" {
  description = "Enable full request/response data logging"
  type        = bool
  default     = false
}

variable "throttle_burst_limit" {
  description = "WebSocket API throttling burst limit"
  type        = number
  default     = 5000
}

variable "throttle_rate_limit" {
  description = "WebSocket API throttling rate limit (requests per second)"
  type        = number
  default     = 10000
}

variable "stage_variables" {
  description = "Stage variables for the WebSocket API"
  type        = map(string)
  default     = {}
}

# Cognito Authorizer Configuration
variable "enable_cognito_authorizer" {
  description = "Enable Cognito authorizer for WebSocket API"
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
  description = "Identity source for the authorizer (e.g., route.request.header.Authorization)"
  type        = list(string)
  default     = ["route.request.header.Authorization"]
}
