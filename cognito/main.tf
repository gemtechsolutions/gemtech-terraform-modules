resource "aws_cognito_user_pool" "this" {
  name = "${var.project_name}-${var.environment}"

  mfa_configuration        = var.mfa_configuration
  email_verification_subject = var.email_subject

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = var.domain
  user_pool_id = aws_cognito_user_pool.this.id
}

resource "aws_cognito_user_pool_client" "clients" {
  for_each = { for c in var.clients : c.name => c }

  name                                 = each.value.name
  user_pool_id                         = aws_cognito_user_pool.this.id
  callback_urls                        = each.value.callback_urls
  logout_urls                          = each.value.logout_urls
  generate_secret                      = each.value.generate_secret
  refresh_token_validity               = each.value.refresh_token_validity
  allowed_oauth_flows_user_pool_client = each.value.allowed_oauth_flows_user_pool_client
  supported_identity_providers         = each.value.supported_identity_providers
  allowed_oauth_scopes                 = each.value.allowed_oauth_scopes
  allowed_oauth_flows                  = each.value.allowed_oauth_flows
  prevent_user_existence_errors        = each.value.prevent_user_existence_errors
  enable_token_revocation              = each.value.enable_token_revocation
  explicit_auth_flows                  = each.value.explicit_auth_flows
}

resource "aws_cognito_user" "users" {
  for_each = var.users

  username       = each.key
  user_pool_id   = aws_cognito_user_pool.this.id
  desired_delivery_mediums = ["EMAIL"]
  attributes = {
    email = each.value.email
  }
}

resource "aws_cognito_user_group" "groups" {
  for_each = { for group in var.user_groups : group.name => group }

  name        = each.value.name
  user_pool_id = aws_cognito_user_pool.this.id
  description = each.value.description
}
