variable "environment" {
  type = string
}

variable "api_name" {
  type = string
}

variable "region" {
  type = string
}

variable "stage_name" {
  type = string
}

variable "api_resources" {
  type = map(object({
    path_part  = string
    lambda_arn = string
    methods    = map(object({
      integration_uri     = string
      status_code         = string
      response_models     = map(string)
      response_parameters = map(any)
    }))
    proxy = bool
  }))
}
