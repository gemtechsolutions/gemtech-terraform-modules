variable "environment" {
  description = "Deployment environment (e.g. production, staging)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "lambda_function_name" {
  type = string
}

variable "description" {
  type = string
}

variable "lambda_exec_role_arn" {
  type = string
}

variable "handler" {
  type = string
}

variable "runtime" {
  type = string
}

variable "lambda_timeout" {
  type    = number
  default = 300
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda function can use at runtime"
  type        = number
  default     = 256
}

variable "architectures" {
  description = "Instruction set architecture for your function"
  type        = list(string)
  default     = ["x86_64"]
}

variable "layers" {
  description = "List of Lambda Layer Version ARNs"
  type        = list(string)
  default     = []
}

variable "publish" {
  description = "Whether to publish creation/change as a new function version"
  type        = bool
  default     = true
}

variable "reserved_concurrent_executions" {
  description = "The maximum number of concurrent executions. Set to null for unlimited."
  type        = number
  default     = null
}

variable "s3_bucket" {
  type    = string
  default = null
}

variable "s3_key" {
  type    = string
  default = null
}

variable "filename" {
  description = "Path to local Lambda deployment package (ZIP file)"
  type        = string
  default     = null
}

variable "lambda_env_vars" {
  type = map(string)
  default = {}
}

variable "enable_vpc" {
  description = "Whether the Lambda should run inside a VPC"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "List of subnet IDs for Lambda VPC config"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for Lambda VPC config"
  type        = list(string)
  default     = []
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing for the function"
  type        = bool
  default     = false
}

variable "dead_letter_target_arn" {
  description = "ARN of an SNS topic or SQS queue for Lambda dead-letter config"
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "KMS key ARN to encrypt environment variables"
  type        = string
  default     = ""
}

variable "ephemeral_storage_size" {
  description = "Ephemeral storage (/tmp) size in MB. Default null uses AWS default (512MB)."
  type        = number
  default     = null
}

variable "enable_function_url" {
  description = "Enable Lambda Function URL for direct HTTP(S) access"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "Authorization type for Function URL. Valid values: NONE, AWS_IAM"
  type        = string
  default     = "AWS_IAM"
}

variable "function_url_cors_config" {
  description = "CORS configuration for Function URL"
  type = object({
    allow_credentials = optional(bool, false)
    allow_origins     = optional(list(string), ["*"])
    allow_methods     = optional(list(string), ["*"])
    allow_headers     = optional(list(string), [])
    expose_headers    = optional(list(string), [])
    max_age           = optional(number, 0)
  })
  default = null
}

variable "enable_api_gateway_integration" {
  description = "Enable API Gateway integration permission"
  type        = bool
  default     = false
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permission"
  type        = string
  default     = ""
}
