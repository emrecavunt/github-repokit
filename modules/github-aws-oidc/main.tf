data "tls_certificate" "github" {
  count = local.fetch_oidc_thumbprints ? 1 : 0

  url = local.github_oidc_url
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "GitHubOidcAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = var.oidc_audiences
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_host}:sub"
      values   = local.repository_subjects
    }
  }
}

data "aws_iam_policy_document" "secrets" {
  dynamic "statement" {
    for_each = local.secrets_statements

    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = local.github_oidc_url
  client_id_list  = var.oidc_audiences
  thumbprint_list = local.oidc_thumbprints
  tags            = var.tags
}

resource "aws_iam_role" "github_actions" {
  name                 = var.role_name
  description          = var.role_description
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}

resource "aws_iam_role_policy" "secrets" {
  count = length(local.secrets_statements) > 0 ? 1 : 0

  name   = "secrets-read"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.secrets.json
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_policy_arns)

  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}
