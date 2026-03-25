resource "github_repository" "repo" {
  name        = var.repo_name
  description = var.repo_description
  visibility  = var.repo_visibility

  has_issues      = var.has_issues
  has_projects    = var.has_projects
  has_wiki        = var.has_wiki
  has_downloads   = var.has_downloads
  has_discussions = var.has_discussions

  auto_init          = var.auto_init
  gitignore_template = var.gitignore_template
  license_template   = var.license_template

  allow_merge_commit     = var.allow_merge_commit
  allow_squash_merge     = var.allow_squash_merge
  allow_rebase_merge     = var.allow_rebase_merge
  allow_auto_merge       = var.allow_auto_merge
  delete_branch_on_merge = var.delete_branch_on_merge

  archive_on_destroy = var.archive_on_destroy

  topics = var.topics

  vulnerability_alerts = var.vulnerability_alerts

  dynamic "pages" {
    for_each = var.pages != null ? [var.pages] : []
    content {
      source {
        branch = pages.value.branch
        path   = pages.value.path
      }
      cname = pages.value.cname
    }
  }

  dynamic "template" {
    for_each = var.template_owner != null && var.template_repository != null ? [1] : []
    content {
      owner      = var.template_owner
      repository = var.template_repository
    }
  }
}

# Create branches
resource "github_branch" "branches" {
  for_each   = toset(var.repo_branches)
  repository = github_repository.repo.name
  branch     = each.value
}

# Set default branch
resource "github_branch_default" "default" {
  count      = var.default_branch != null ? 1 : 0
  repository = github_repository.repo.name
  branch     = var.default_branch

  depends_on = [github_branch.branches]
}

# Branch Protection Rules
resource "github_branch_protection" "protection" {
  for_each      = var.branch_protection
  repository_id = github_repository.repo.node_id
  pattern       = each.key

  enforce_admins         = each.value.enforce_admins
  allows_deletions       = each.value.allows_deletions
  allows_force_pushes    = each.value.allows_force_pushes
  require_signed_commits = each.value.require_signed_commits

  required_linear_history = each.value.required_linear_history

  dynamic "required_status_checks" {
    for_each = each.value.required_status_checks != null ? [each.value.required_status_checks] : []
    content {
      strict   = required_status_checks.value.strict
      contexts = required_status_checks.value.contexts
    }
  }

  dynamic "required_pull_request_reviews" {
    for_each = each.value.required_pull_request_reviews != null ? [each.value.required_pull_request_reviews] : []
    content {
      dismiss_stale_reviews           = required_pull_request_reviews.value.dismiss_stale_reviews
      restrict_dismissals             = required_pull_request_reviews.value.restrict_dismissals
      dismissal_restrictions          = required_pull_request_reviews.value.dismissal_restrictions
      require_code_owner_reviews      = required_pull_request_reviews.value.require_code_owner_reviews
      required_approving_review_count = required_pull_request_reviews.value.required_approving_review_count
      require_last_push_approval      = required_pull_request_reviews.value.require_last_push_approval
    }
  }

  dynamic "restrict_pushes" {
    for_each = each.value.restrict_pushes != null ? [each.value.restrict_pushes] : []
    content {
      blocks_creations = restrict_pushes.value.blocks_creations
      push_allowances  = restrict_pushes.value.push_allowances
    }
  }
}

# Repository Collaborators
resource "github_repository_collaborators" "collaborators" {
  count      = length(var.collaborators) > 0 || length(var.teams) > 0 ? 1 : 0
  repository = github_repository.repo.name

  dynamic "user" {
    for_each = var.collaborators
    content {
      username   = user.value.username
      permission = user.value.permission
    }
  }

  dynamic "team" {
    for_each = var.teams
    content {
      team_id    = team.value.team_id
      permission = team.value.permission
    }
  }
}

# Repository Webhooks
resource "github_repository_webhook" "webhooks" {
  for_each   = var.webhooks
  repository = github_repository.repo.name

  configuration {
    url          = each.value.url
    content_type = each.value.content_type
    insecure_ssl = each.value.insecure_ssl
    secret       = each.value.secret
  }

  active = each.value.active
  events = each.value.events
}

# Repository Environments
resource "github_repository_environment" "environments" {
  for_each    = var.environments
  repository  = github_repository.repo.name
  environment = each.key

  dynamic "reviewers" {
    for_each = each.value.reviewers != null ? [each.value.reviewers] : []
    content {
      teams = reviewers.value.teams
      users = reviewers.value.users
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = each.value.deployment_branch_policy != null ? [each.value.deployment_branch_policy] : []
    content {
      protected_branches     = deployment_branch_policy.value.protected_branches
      custom_branch_policies = deployment_branch_policy.value.custom_branch_policies
    }
  }

  wait_timer = each.value.wait_timer
}

# Repository Secrets
resource "github_actions_secret" "secrets" {
  for_each        = var.secrets
  repository      = github_repository.repo.name
  secret_name     = each.key
  plaintext_value = each.value
}

# Repository Variables
resource "github_actions_variable" "variables" {
  for_each      = var.variables
  repository    = github_repository.repo.name
  variable_name = each.key
  value         = each.value
}

# CODEOWNERS file
resource "github_repository_file" "codeowners" {
  count               = var.codeowners != null ? 1 : 0
  repository          = github_repository.repo.name
  branch              = var.default_branch != null ? var.default_branch : "main"
  file                = ".github/CODEOWNERS"
  content             = var.codeowners
  commit_message      = "Add CODEOWNERS file"
  commit_author       = "Terraform"
  commit_email        = "terraform@ciw.com"
  overwrite_on_create = true

  depends_on = [github_branch_default.default]
}

# Auto-link references
resource "github_repository_autolink_reference" "autolinks" {
  for_each            = var.autolink_references
  repository          = github_repository.repo.name
  key_prefix          = each.value.key_prefix
  target_url_template = each.value.target_url_template
  is_alphanumeric     = each.value.is_alphanumeric
}
