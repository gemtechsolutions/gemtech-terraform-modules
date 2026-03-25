# GitHub Repository Module - Usage Guide

## Quick Start

### 1. Initialize Terraform

```bash
cd /Users/admin/Documents/projects/cam-invoice/ciw-devops/github-repos
terraform init
```

### 2. Plan Changes

```bash
terraform plan
```

### 3. Apply Changes

```bash
terraform apply
```

## Module Structure

```
modules/github-repository/
├── main.tf           # Main resource definitions
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── versions.tf       # Provider version constraints
├── README.md         # Module documentation
├── USAGE.md          # This file
├── .gitignore        # Git ignore rules
└── examples/
    ├── basic/        # Basic usage example
    └── advanced/     # Advanced usage example
```

## Common Use Cases

### Create a Simple Private Repository

```hcl
module "my_repo" {
  source = "../modules/github-repository"

  repo_name        = "my-app"
  repo_description = "My application"
  repo_visibility  = "private"
}
```

### Create Repository with Multiple Branches

```hcl
module "my_repo" {
  source = "../modules/github-repository"

  repo_name      = "my-app"
  repo_branches  = ["dev", "stg", "master"]
  default_branch = "dev"
}
```

### Add Branch Protection

```hcl
module "my_repo" {
  source = "../modules/github-repository"

  repo_name      = "my-app"
  repo_branches  = ["dev", "stg", "master"]
  default_branch = "dev"

  branch_protection = {
    "master" = {
      enforce_admins         = false
      allows_deletions       = false
      required_pull_request_reviews = {
        required_approving_review_count = 1
      }
    }
    "stg" = {
      enforce_admins         = false
      allows_deletions       = false
      required_pull_request_reviews = {
        required_approving_review_count = 1
      }
    }
  }
}
```

### Add GitHub Actions Secrets

```hcl
module "my_repo" {
  source = "../modules/github-repository"

  repo_name = "my-app"

  secrets = {
    AWS_ACCESS_KEY_ID     = "AKIA..."
    AWS_SECRET_ACCESS_KEY = "secret..."
    API_TOKEN             = "token..."
  }
}
```

### Configure Environments

```hcl
module "my_repo" {
  source = "../modules/github-repository"

  repo_name = "my-app"

  environments = {
    "production" = {
      deployment_branch_policy = {
        protected_branches = true
      }
    }
    "development" = {}
  }
}
```

## Your Current Setup

Your [github-repos/main.tf](../../github-repos/main.tf) now uses the local module:

```hcl
module "repos" {
  source           = "../modules/github-repository"
  for_each         = local.repos
  repo_name        = each.key
  repo_description = "GitHub repo for ${each.key}"
  repo_branches    = ["develop", "main"]
  default_branch   = "develop"
  repo_visibility  = each.value.visibility

  topics                 = ["ciw", "microservice"]
  delete_branch_on_merge = true
  vulnerability_alerts   = true

  branch_protection = {
    "main" = {
      enforce_admins         = false
      allows_deletions       = false
      allows_force_pushes    = false
      require_signed_commits = false
      required_pull_request_reviews = {
        dismiss_stale_reviews           = true
        required_approving_review_count = 1
      }
    }
  }
}
```

## Migrate from Remote Module

### Before (Remote Module)
```hcl
module "repos" {
  source = "git::ssh://git@github.com/user/repo.git//github-repos"
  # ...
}
```

### After (Local Module)
```hcl
module "repos" {
  source = "../modules/github-repository"
  # ...
}
```

### Migration Steps

1. **Update module source** in your configuration
2. **Run terraform init -upgrade** to download new module
3. **Run terraform plan** to see changes
4. **Review the plan** carefully
5. **Run terraform apply** to apply changes

```bash
cd github-repos
terraform init -upgrade
terraform plan
terraform apply
```

## Customization Per Repository

You can customize settings per repository using the `for_each` pattern:

```hcl
locals {
  repos = {
    "ciw-frontend" = {
      visibility = "private"
      has_pages  = true
      topics     = ["ciw", "frontend", "react"]
    }
    "ciw-backend" = {
      visibility = "private"
      has_pages  = false
      topics     = ["ciw", "backend", "python"]
    }
  }
}

module "repos" {
  source   = "../modules/github-repository"
  for_each = local.repos

  repo_name       = each.key
  repo_visibility = each.value.visibility
  topics          = each.value.topics

  pages = each.value.has_pages ? {
    branch = "gh-pages"
  } : null
}
```

## Adding Secrets Dynamically

Secrets should be managed securely. Best practices:

### Option 1: AWS SSM Parameter Store (Recommended)

```hcl
data "aws_ssm_parameter" "github_token" {
  name = "/ciw/github/token"
}

module "repos" {
  source = "../modules/github-repository"

  repo_name = "my-app"

  secrets = {
    GITHUB_TOKEN = data.aws_ssm_parameter.github_token.value
  }
}
```

### Option 2: Environment Variables

```bash
export TF_VAR_github_token="ghp_..."
```

```hcl
variable "github_token" {
  sensitive = true
}

module "repos" {
  source = "../modules/github-repository"

  secrets = {
    GITHUB_TOKEN = var.github_token
  }
}
```

### Option 3: Terraform Cloud/Enterprise

Store secrets in Terraform Cloud workspace variables.

## Testing Changes

### Plan Only (Dry Run)

```bash
terraform plan -out=tfplan
```

### Target Specific Repository

```bash
terraform plan -target=module.repos[\"ciw-frontend\"]
terraform apply -target=module.repos[\"ciw-frontend\"]
```

### Destroy Specific Repository

```bash
terraform destroy -target=module.repos[\"ciw-old-repo\"]
```

## Troubleshooting

### Module Not Found

```
Error: Module not found
```

**Solution:** Run `terraform init -upgrade`

### Authentication Error

```
Error: GET https://api.github.com/user: 401 Bad credentials
```

**Solution:** Check GitHub token in AWS SSM Parameter Store

### Branch Protection Conflicts

```
Error: Resource already exists
```

**Solution:** Import existing resources:

```bash
terraform import 'module.repos["ciw-frontend"].github_branch_protection.protection["main"]' ciw-frontend:main
```

## Best Practices

1. **Use consistent naming** - All repos should follow `ciw-{service}-{type}` pattern
2. **Enable branch protection** - Protect main/master branches
3. **Enable vulnerability alerts** - Security scanning
4. **Delete branches on merge** - Keep repo clean
5. **Use topics** - Organize and discover repos
6. **Archive instead of delete** - Set `archive_on_destroy = true`
7. **Version control secrets** - Use AWS SSM, not plain text
8. **Review before apply** - Always run `terraform plan` first

## Advanced Features

### CODEOWNERS

```hcl
codeowners = <<-EOT
  * @ciw-team
  *.py @backend-team
  *.tsx @frontend-team
  /terraform/ @devops-team
EOT
```

### Webhooks

```hcl
webhooks = {
  "slack" = {
    url    = "https://hooks.slack.com/services/..."
    events = ["push", "pull_request", "issues"]
  }
}
```

### Auto-link References

```hcl
autolink_references = {
  "jira" = {
    key_prefix          = "JIRA-"
    target_url_template = "https://jira.company.com/browse/JIRA-<num>"
  }
}
```

## Support

For issues or questions:
- Check [README.md](./README.md) for detailed documentation
- Review [examples/](./examples/) for usage patterns
- Check Terraform GitHub provider docs: https://registry.terraform.io/providers/integrations/github/latest/docs

---

**Last Updated:** 2026-03-25
