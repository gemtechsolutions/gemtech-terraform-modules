variable "environment" {
  description = "Deployment environment (e.g. production, staging)"
  type        = string
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

variable "s3_bucket" {
  type = string
}

variable "s3_key" {
  type = string
}

variable "lambda_env_vars" {
  type = map(string)
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
