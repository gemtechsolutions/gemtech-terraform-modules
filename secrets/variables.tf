variable "name" {
  description = "Name of the secret"
  type        = string
}

variable "description" {
  description = "Secret description"
  type        = string
}

variable "recovery_window_in_days" {
  description = "Window before permanent deletion"
  type        = number
  default     = 30
}

variable "create_policy" {
  description = "Whether to create a resource-based policy"
  type        = bool
  default     = false
}

variable "secret_values" {
  description = "Map of key-value pairs to store as the secret string"
  type        = any
}

variable "tags" {
  type        = map(string)
  default     = {}
}

variable "reader_role_names" {
  description = "List of IAM role names that should be granted access to the secret"
  type        = list(string)
  default     = []
}