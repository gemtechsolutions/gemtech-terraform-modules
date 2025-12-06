provider "aws" {
  region = "us-east-1"
}

locals {
  name              = "example-secrets"
  description       = "Example app credentials"
  reader_role_names = ["my-app-role", "my-debug-role"]
  tags = {
    Environment = "production"
    Project     = "static-site"
  }
}

module "secrets" {
  source = "../"

  name                    = local.name
  description             = local.description
  recovery_window_in_days = 7
  create_policy           = true

  reader_role_names = local.reader_role_names

  secret_values = var.secret_values

  tags = local.tags
}
