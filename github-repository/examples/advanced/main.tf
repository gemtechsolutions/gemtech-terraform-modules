# Advanced Example - Full Featured Repository

module "advanced_repo" {
  source = "../../"

  repo_name        = "ciw-example-service"
  repo_description = "Advanced repository example with all features"
  repo_visibility  = "private"

  repo_branches  = ["dev", "stg", "master"]
  default_branch = "dev"

  topics = ["ciw", "microservice", "fastapi", "python"]

  has_issues      = true
  has_projects    = false
  has_wiki        = false
  has_discussions = false

  delete_branch_on_merge = true
  vulnerability_alerts   = true
  allow_auto_merge       = true

  # Branch Protection
  branch_protection = {
    "master" = {
      enforce_admins              = false
      allows_deletions            = false
      allows_force_pushes         = false
      require_signed_commits      = false
      required_linear_history     = true
      required_status_checks = {
        strict   = true
        contexts = ["test", "build", "lint"]
      }
      required_pull_request_reviews = {
        dismiss_stale_reviews           = true
        require_code_owner_reviews      = true
        required_approving_review_count = 2
        require_last_push_approval      = true
      }
    }
    "stg" = {
      enforce_admins         = false
      allows_deletions       = false
      allows_force_pushes    = false
      require_signed_commits = false
      required_pull_request_reviews = {
        dismiss_stale_reviews           = true
        required_approving_review_count = 1
      }
    }
    "dev" = {
      enforce_admins         = false
      allows_deletions       = true
      allows_force_pushes    = false
      require_signed_commits = false
    }
  }

  # Environments
  environments = {
    "production" = {
      deployment_branch_policy = {
        protected_branches = true
      }
    }
    "development" = {
      wait_timer = 0
    }
  }

  # Variables
  variables = {
    API_BASE_URL = "https://api.caminvoice-services.com"
    STAGE        = "prod"
  }

  # CODEOWNERS
  codeowners = <<-EOT
    # Default owners
    * @ciw-team

    # Backend
    *.py @backend-team
    app/ @backend-team

    # Infrastructure
    /terraform/ @devops-team
    /.github/ @devops-team
    serverless.yml @devops-team

    # Tests
    /tests/ @qa-team
  EOT

  # Auto-link references
  autolink_references = {
    "jira" = {
      key_prefix          = "JIRA-"
      target_url_template = "https://jira.example.com/browse/JIRA-<num>"
      is_alphanumeric     = false
    }
  }

  # Webhooks
  webhooks = {
    "ci-cd" = {
      url          = "https://ci.example.com/webhook"
      content_type = "json"
      events       = ["push", "pull_request", "release"]
      active       = true
    }
  }
}

output "repo_url" {
  value = module.advanced_repo.repo_html_url
}

output "clone_url" {
  value = module.advanced_repo.repo_ssh_clone_url
}
