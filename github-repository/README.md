# GitHub Repository Terraform Module

Terraform module for creating and managing GitHub repositories with comprehensive features.

## Features

- ✅ Repository creation with full configuration
- ✅ Multiple branch creation and management
- ✅ Default branch configuration
- ✅ Branch protection rules
- ✅ Collaborators and team management
- ✅ Webhooks configuration
- ✅ GitHub Actions secrets and variables
- ✅ Environment configuration
- ✅ CODEOWNERS file management
- ✅ Auto-link references
- ✅ GitHub Pages support

## Usage

### Basic Example

```hcl
module "repo" {
  source = "./modules/github-repository"

  repo_name        = "my-app"
  repo_description = "My awesome application"
  repo_visibility  = "private"
  repo_branches    = ["dev", "stg", "master"]
  default_branch   = "dev"
}
```

### Advanced Example with Branch Protection

```hcl
module "repo" {
  source = "./modules/github-repository"

  repo_name        = "ciw-invoices-service"
  repo_description = "CIW Invoices microservice"
  repo_visibility  = "private"

  repo_branches  = ["dev", "stg", "master"]
  default_branch = "dev"

  topics = ["ciw", "microservice", "invoices", "fastapi"]

  delete_branch_on_merge = true
  vulnerability_alerts   = true

  branch_protection = {
    "master" = {
      enforce_admins              = false
      allows_deletions            = false
      allows_force_pushes         = false
      require_signed_commits      = false
      required_linear_history     = false
      required_status_checks = {
        strict   = true
        contexts = ["test", "build"]
      }
      required_pull_request_reviews = {
        dismiss_stale_reviews           = true
        require_code_owner_reviews      = false
        required_approving_review_count = 1
        require_last_push_approval      = false
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

  environments = {
    "production" = {
      reviewers = {
        users = [12345, 67890]
      }
      deployment_branch_policy = {
        protected_branches = true
      }
    }
    "development" = {
      wait_timer = 0
    }
  }

  variables = {
    API_BASE_URL = "https://api.caminvoice-services.com"
    STAGE        = "prod"
  }
}
```

### With Webhooks

```hcl
module "repo" {
  source = "./modules/github-repository"

  repo_name = "my-app"

  webhooks = {
    "ci-cd" = {
      url          = "https://ci.example.com/webhook"
      content_type = "json"
      events       = ["push", "pull_request"]
      active       = true
    }
  }
}
```

### With CODEOWNERS

```hcl
module "repo" {
  source = "./modules/github-repository"

  repo_name = "my-app"

  codeowners = <<-EOT
    # Backend team owns all Python files
    *.py @backend-team

    # Frontend team owns React files
    src/components/ @frontend-team

    # DevOps owns infrastructure
    /terraform/ @devops-team
    /.github/ @devops-team
  EOT
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| repo_name | Repository name | string | - | yes |
| repo_description | Repository description | string | "" | no |
| repo_visibility | Visibility (public, private, internal) | string | "private" | no |
| repo_branches | List of branches to create | list(string) | ["main"] | no |
| default_branch | Default branch name | string | "main" | no |
| branch_protection | Branch protection rules | map(object) | {} | no |
| topics | Repository topics | list(string) | [] | no |
| collaborators | Repository collaborators | list(object) | [] | no |
| teams | Repository teams | list(object) | [] | no |
| webhooks | Repository webhooks | map(object) | {} | no |
| environments | GitHub environments | map(object) | {} | no |
| secrets | GitHub Actions secrets | map(string) | {} | no |
| variables | GitHub Actions variables | map(string) | {} | no |
| codeowners | CODEOWNERS file content | string | null | no |

See [variables.tf](./variables.tf) for complete list.

## Outputs

| Name | Description |
|------|-------------|
| repo_id | Repository ID |
| repo_name | Repository name |
| repo_full_name | Repository full name |
| repo_html_url | Repository HTML URL |
| repo_ssh_clone_url | SSH clone URL |
| default_branch | Default branch |
| branches | List of branches |
| protected_branches | Protected branch patterns |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| github | ~> 6.0 |

## Notes

- Archive on destroy is enabled by default to prevent accidental deletion
- Branch protection rules are flexible and can be customized per branch
- Secrets are marked as sensitive and won't be shown in logs
- CODEOWNERS file is created automatically if provided

## License

MIT
