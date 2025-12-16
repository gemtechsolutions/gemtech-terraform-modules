data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Example: Reference Lambda functions from terraform remote state
# Uncomment and configure if you want to use remote state
#
# data "terraform_remote_state" "lambda" {
#   backend = "local"
#
#   config = {
#     path = "../../lambda/terraform.tfstate"
#   }
# }

# Example: Look up existing Lambda functions by name
# Uncomment if you want to reference existing Lambda functions
#
# data "aws_lambda_function" "users_api" {
#   function_name = "users-api"
# }
#
# data "aws_lambda_function" "products_api" {
#   function_name = "products-api"
# }
