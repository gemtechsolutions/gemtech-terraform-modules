# Basic Example - Simple Repository

module "simple_repo" {
  source = "../../"

  repo_name        = "my-simple-app"
  repo_description = "A simple application"
  repo_visibility  = "private"

  repo_branches  = ["dev", "stg", "master"]
  default_branch = "dev"

  topics = ["example", "simple"]
}

output "repo_url" {
  value = module.simple_repo.repo_html_url
}
