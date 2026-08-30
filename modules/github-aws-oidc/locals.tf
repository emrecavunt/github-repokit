locals {
  github_oidc_url  = "https://token.actions.githubusercontent.com"
  github_oidc_host = "token.actions.githubusercontent.com"

  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.oidc_provider_arn

  wildcard_subjects = [
    for repo in var.github_repositories : "repo:${repo}:*"
  ]

  environment_subjects = flatten([
    for repo in var.github_repositories : [
      for environment in var.allowed_environments : "repo:${repo}:environment:${environment}"
    ]
  ])

  repository_subjects = length(var.allowed_environments) == 0 ? local.wildcard_subjects : local.environment_subjects

  fetch_oidc_thumbprints = var.create_oidc_provider && length(var.oidc_thumbprints) == 0

  fetched_thumbprints = local.fetch_oidc_thumbprints ? distinct([
    for cert in data.tls_certificate.github[0].certificates : cert.sha1_fingerprint
  ]) : []

  oidc_thumbprints = length(var.oidc_thumbprints) > 0 ? var.oidc_thumbprints : local.fetched_thumbprints

  secrets_statement_candidates = [
    {
      enabled = length(var.secretsmanager_secret_arns) > 0
      sid     = "ReadSecretsManager"
      effect  = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
      ]
      resources = var.secretsmanager_secret_arns
    },
    {
      enabled = length(var.ssm_parameter_arns) > 0
      sid     = "ReadSsmParameters"
      effect  = "Allow"
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath",
      ]
      resources = var.ssm_parameter_arns
    },
    {
      enabled = length(var.kms_key_arns) > 0
      sid     = "DecryptSecrets"
      effect  = "Allow"
      actions = [
        "kms:Decrypt",
      ]
      resources = var.kms_key_arns
    },
  ]

  secrets_statements = [
    for statement in local.secrets_statement_candidates : {
      sid       = statement.sid
      effect    = statement.effect
      actions   = statement.actions
      resources = statement.resources
    } if statement.enabled
  ]
}
