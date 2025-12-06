output "lambda_functions" {
  value = {
    for k, v in module.lambda :
    k => {
      name = v.lambda_function_name
      arn  = v.lambda_function_arn
    }
  }
}
