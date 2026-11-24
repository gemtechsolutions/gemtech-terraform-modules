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
    # Optional attributes the client's users may write themselves
    # (UpdateUserAttributes with their own token). Omit (null) to keep the
    # current setting: Cognito then lets users write every writable
    # attribute, email included. Updated in place.
    write_attributes = optional(list(string))
    # Optional access/ID token lifetimes. Omit to inherit the AWS default
    # (60 minutes). Pair with `token_validity_units` if a unit other than the
    # AWS default for that field is desired.
    access_token_validity = optional(number)
    id_token_validity     = optional(number)
    # Optional unit overrides (per-field). Cognito defaults: hours for the
    # access/id tokens, days for the refresh token.
    token_validity_units = optional(object({
      access_token  = optional(string)
      id_token      = optional(string)
      refresh_token = optional(string)
    }))
  }))
}

# Optional sign-in settings. null (the default) leaves the pool exactly as
# before, so existing callers see no change. Changing username_attributes on
# an existing pool forces Terraform to REPLACE the pool (users are lost).
variable "username_attributes" {
  description = "Attributes users can sign in with instead of a username, e.g. [\"email\"]. Forces pool replacement when changed."
  type        = list(string)
  default     = null
}

variable "auto_verified_attributes" {
  description = "Attributes Cognito verifies automatically, e.g. [\"email\"]."
  type        = list(string)
  default     = null
}

# Optional body of the verification email (attribute verification and
# forgot-password codes). It must contain the {####} code placeholder. null
# (the default) leaves the pool's current message, so existing callers see no
# change. Updated in place; it never replaces the pool.
variable "email_message" {
  description = "Verification email body; must contain {####}. null keeps the pool's current message."
  type        = string
  default     = null
}
