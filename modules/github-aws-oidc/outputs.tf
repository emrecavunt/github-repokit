output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for token.actions.githubusercontent.com."
  value       = local.oidc_provider_arn
}

output "role_arn" {
  description = "IAM role ARN for GitHub Actions to assume via OIDC. Set this as AWS_ROLE_ARN on the actions stack when you want keyless AWS access."
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "IAM role name assumed by GitHub Actions."
  value       = aws_iam_role.github_actions.name
}
