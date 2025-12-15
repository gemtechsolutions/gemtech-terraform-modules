data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Example: Reference Lambda functions from terraform remote state
# Uncomment and configure if you want to use remote state
#
# data "terraform_remote_state" "lambda" {
#   backend = "s3"
#
#   config = {
#     bucket = "my-terraform-state-bucket"
#     key    = "lambda/terraform.tfstate"
#     region = "us-east-1"
#   }
# }

# Example: Look up existing Lambda functions by name
# Uncomment if you want to reference existing Lambda functions
#
# data "aws_lambda_function" "ws_connect" {
#   function_name = "ws-connect-handler"
# }
#
# data "aws_lambda_function" "ws_disconnect" {
#   function_name = "ws-disconnect-handler"
# }
#
# data "aws_lambda_function" "ws_default" {
#   function_name = "ws-default-handler"
# }
#
# data "aws_lambda_function" "ws_send_message" {
#   function_name = "ws-send-message"
# }
#
# data "aws_lambda_function" "ws_proxy" {
#   function_name = "ws-proxy-to-rest-api"
# }
