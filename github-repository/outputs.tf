# GitHub Repository Module Outputs

output "repo_id" {
  description = "Repository ID"
  value       = github_repository.repo.repo_id
}

output "repo_node_id" {
  description = "Repository Node ID"
  value       = github_repository.repo.node_id
}

output "repo_name" {
  description = "Repository name"
  value       = github_repository.repo.name
}

output "repo_full_name" {
  description = "Repository full name (owner/repo)"
  value       = github_repository.repo.full_name
}

output "repo_html_url" {
  description = "Repository HTML URL"
  value       = github_repository.repo.html_url
}

output "repo_ssh_clone_url" {
  description = "Repository SSH clone URL"
  value       = github_repository.repo.ssh_clone_url
}

output "repo_http_clone_url" {
  description = "Repository HTTP clone URL"
  value       = github_repository.repo.http_clone_url
}

output "repo_git_clone_url" {
  description = "Repository Git clone URL"
  value       = github_repository.repo.git_clone_url
}

output "default_branch" {
  description = "Default branch name"
  value       = github_repository.repo.default_branch
}

output "branches" {
  description = "Created branches"
  value       = [for b in github_branch.branches : b.branch]
}

output "protected_branches" {
  description = "Protected branch patterns"
  value       = [for p in github_branch_protection.protection : p.pattern]
}
