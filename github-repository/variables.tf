# GitHub Repository Module Variables

variable "repo_name" {
  description = "Name of the GitHub repository"
  type        = string
}

variable "repo_description" {
  description = "Description of the GitHub repository"
  type        = string
  default     = ""
}

variable "repo_visibility" {
  description = "Visibility of the repository (public, private, internal)"
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "internal"], var.repo_visibility)
    error_message = "Visibility must be one of: public, private, internal"
  }
}

variable "has_issues" {
  description = "Enable GitHub Issues"
  type        = bool
  default     = true
}

variable "has_projects" {
  description = "Enable GitHub Projects"
  type        = bool
  default     = false
}

variable "has_wiki" {
  description = "Enable GitHub Wiki"
  type        = bool
  default     = false
}

variable "has_downloads" {
  description = "Enable downloads"
  type        = bool
  default     = false
}

variable "has_discussions" {
  description = "Enable GitHub Discussions"
  type        = bool
  default     = false
}

variable "auto_init" {
  description = "Auto-initialize repository with README"
  type        = bool
  default     = true
}

variable "gitignore_template" {
  description = "Gitignore template to use"
  type        = string
  default     = null
}

variable "license_template" {
  description = "License template to use"
  type        = string
  default     = null
}

variable "allow_merge_commit" {
  description = "Allow merge commits"
  type        = bool
  default     = true
}

variable "allow_squash_merge" {
  description = "Allow squash merges"
  type        = bool
  default     = true
}

variable "allow_rebase_merge" {
  description = "Allow rebase merges"
  type        = bool
  default     = true
}

variable "allow_auto_merge" {
  description = "Allow auto-merge"
  type        = bool
  default     = false
}

variable "delete_branch_on_merge" {
  description = "Delete branch after merge"
  type        = bool
  default     = true
}

variable "archive_on_destroy" {
  description = "Archive repository on destroy instead of deleting"
  type        = bool
  default     = true
}

variable "topics" {
  description = "List of topics for the repository"
  type        = list(string)
  default     = []
}

variable "vulnerability_alerts" {
  description = "Enable vulnerability alerts"
  type        = bool
  default     = true
}

variable "repo_branches" {
  description = "List of branches to create"
  type        = list(string)
  default     = ["dev", "stg", "master"]
}

variable "default_branch" {
  description = "Default branch name"
  type        = string
  default     = "dev"
}

variable "branch_protection" {
  description = "Branch protection rules"
  type = map(object({
    enforce_admins              = optional(bool, false)
    allows_deletions            = optional(bool, false)
    allows_force_pushes         = optional(bool, false)
    require_signed_commits      = optional(bool, false)
    required_linear_history     = optional(bool, false)
    required_status_checks = optional(object({
      strict   = optional(bool, false)
      contexts = optional(list(string), [])
    }))
    required_pull_request_reviews = optional(object({
      dismiss_stale_reviews           = optional(bool, true)
      restrict_dismissals             = optional(bool, false)
      dismissal_restrictions          = optional(list(string), [])
      require_code_owner_reviews      = optional(bool, false)
      required_approving_review_count = optional(number, 1)
      require_last_push_approval      = optional(bool, false)
    }))
    restrict_pushes = optional(object({
      blocks_creations = optional(bool, false)
      push_allowances  = optional(list(string), [])
    }))
  }))
  default = {}
}

variable "collaborators" {
  description = "Repository collaborators"
  type = list(object({
    username   = string
    permission = string # pull, push, maintain, triage, admin
  }))
  default = []
}

variable "teams" {
  description = "Repository teams"
  type = list(object({
    team_id    = string
    permission = string # pull, push, maintain, triage, admin
  }))
  default = []
}

variable "webhooks" {
  description = "Repository webhooks"
  type = map(object({
    url          = string
    content_type = optional(string, "json")
    insecure_ssl = optional(bool, false)
    secret       = optional(string)
    active       = optional(bool, true)
    events       = list(string)
  }))
  default = {}
}

variable "environments" {
  description = "Repository environments"
  type = map(object({
    reviewers = optional(object({
      teams = optional(list(number))
      users = optional(list(number))
    }))
    deployment_branch_policy = optional(object({
      protected_branches     = optional(bool, false)
      custom_branch_policies = optional(bool, false)
    }))
    wait_timer = optional(number)
  }))
  default = {}
}

variable "secrets" {
  description = "GitHub Actions secrets"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "variables" {
  description = "GitHub Actions variables"
  type        = map(string)
  default     = {}
}

variable "codeowners" {
  description = "CODEOWNERS file content"
  type        = string
  default     = null
}

variable "autolink_references" {
  description = "Auto-link references"
  type = map(object({
    key_prefix          = string
    target_url_template = string
    is_alphanumeric     = optional(bool, true)
  }))
  default = {}
}

variable "pages" {
  description = "GitHub Pages configuration"
  type = object({
    branch = string
    path   = optional(string, "/")
    cname  = optional(string)
  })
  default = null
}

variable "template_owner" {
  description = "Owner of template repository"
  type        = string
  default     = null
}

variable "template_repository" {
  description = "Template repository name"
  type        = string
  default     = null
}
