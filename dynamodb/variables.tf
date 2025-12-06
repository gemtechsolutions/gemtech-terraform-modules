variable "name" {
  type = string
}

variable "hash_key" {
  type = string
}

variable "range_key" {
  type      = string
  default   = null
}

variable "table_class" {
  type    = string
  default = "STANDARD"
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

variable "deletion_protection_enabled" {
  type    = bool
  default = false
}

variable "point_in_time_recovery_enabled" {
  type    = bool
  default = false
}

variable "attributes" {
  type = list(object({
    name = string
    type = string
  }))
}

variable "global_secondary_indexes" {
  type    = list(object({
    name               = string
    hash_key           = string
    range_key          = optional(string)
    projection_type    = string
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
