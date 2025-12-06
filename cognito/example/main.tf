provider "aws" {
  region = "us-east-1"
}

module "cognito" {
  source = "../"

  name           = "nvw-cognito"
  project_name   = "Nomad VPN"
  environment    = "test"
  label_order    = ["environment", "name"]
  domain         = "nomad-vpn"
  email_subject  = "Sign up for Nomad VPN"

  mfa_configuration        = "OFF"
  allow_software_mfa_token = false
  advanced_security_mode   = "OFF"

  users = {
    testadmin = {
      email = "admin@example.com"
    }
  }

  user_groups = [
    {
      name        = "standard"
      description = "Standard VPN users"
    },
    {
      name        = "admin"
      description = "Admin group"
    }
  ]

  clients = [
    {
      name                                 = "nvw-client"
      callback_urls                        = ["https://nomad-vpn.com/signin"]
      logout_urls                          = ["https://nomad-vpn.com/logout"]
      generate_secret                      = false
      refresh_token_validity               = 30
      allowed_oauth_flows_user_pool_client = true
      supported_identity_providers         = ["COGNITO"]
      allowed_oauth_scopes                 = ["email", "openid", "profile"]
      allowed_oauth_flows                  = ["code"]
      prevent_user_existence_errors        = "ENABLED"
      enable_token_revocation              = true
      explicit_auth_flows = [
        "ALLOW_ADMIN_USER_PASSWORD_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH",
        "ALLOW_USER_PASSWORD_AUTH",
        "ALLOW_USER_SRP_AUTH"
      ]
    }
  ]
}
