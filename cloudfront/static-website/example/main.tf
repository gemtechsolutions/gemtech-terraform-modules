provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket  = "gemtech-remotestate-prod"
    key     = "/cloudfront/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    profile = "default"
  }
}

locals {
  bucket_name      = "example-static-site-bucket"
  domain_name      = "static.example.com"
  route53_zone_id  = "Z3P5QSUBK4POTI"  # replace with your actual zone ID
  public           = true
  private          = false
  key_group_id     = ""  # only used if private = true
  tags = {
    Environment = "production"
    Project     = "static-site"
  }
}

module "cloudfront_static_site" {
  source = "../"

  bucket_name       = local.bucket_name
  domain_name       = local.domain_name
  route53_zone_id   = local.route53_zone_id
  public            = local.public
  private           = local.private
  key_group_id      = local.key_group_id
  tags              = local.tags
}
