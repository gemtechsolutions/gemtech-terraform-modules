variable "name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "label_order" {
  type    = list(string)
  default = ["name"]
}

variable "domain" {
  type = string
}

variable "enabled" {
  type    = bool
  default = true
}

variable "advanced_security_mode" {
  type    = string
  default = "OFF"
}

variable "mfa_configuration" {
  type    = string
  default = "OFF"
}

variable "allow_software_mfa_token" {
  type    = bool
  default = false
}

variable "email_subject" {
  type    = string
  default = ""
}

variable "users" {
  type = map(object({
    email = string
  }))
  default = {}
}

variable "user_groups" {
  type = list(object({
    name        = string
    description = string
  }))
  default = []
}

variable "clients" {
  type = list(object({
    name                                 = string
    callback_urls                        = list(string)
    logout_urls                          = list(string)
    generate_secret                      = bool
    refresh_token_validity               = number
    allowed_oauth_flows_user_pool_client = bool
    supported_identity_providers         = list(string)
    allowed_oauth_scopes                 = list(string)
    allowed_oauth_flows                  = list(string)
    prevent_user_existence_errors        = string
    enable_token_revocation              = bool
    explicit_auth_flows                  = list(string)
  }))
}
