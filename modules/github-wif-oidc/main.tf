data "google_project" "service_account_project" {
  project_id = var.service_account_project_id
}

resource "google_project_service" "identity_services" {
  for_each = var.create_project_wif_provider ? toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ]) : toset([])

  project            = var.service_account_project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_iam_workload_identity_pool" "github" {
  count = var.create_project_wif_provider ? 1 : 0

  project                   = data.google_project.service_account_project.number
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = "github"
  description               = "Workload Identity Pool for GitHub Actions"
  disabled                  = false

  depends_on = [google_project_service.identity_services]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  count = var.create_project_wif_provider ? 1 : 0

  project                            = data.google_project.service_account_project.number
  workload_identity_pool_id          = google_iam_workload_identity_pool.github[0].workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_provider_id
  display_name                       = "github"
  description                        = "Workload Identity Pool Provider for GitHub Actions"
  attribute_condition                = local.github_provider_attribute_condition

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.aud"              = "assertion.aud"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  lifecycle {
    precondition {
      condition     = trimspace(var.github_owner) != "" || var.github_provider_attribute_condition != null
      error_message = "github_owner is required when create_project_wif_provider=true unless github_provider_attribute_condition is set."
    }
  }
}

resource "google_service_account" "terraform_apply" {
  project      = var.service_account_project_id
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

resource "google_project_iam_member" "terraform_apply_roles" {
  for_each = local.role_binding_map

  project = each.value.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.terraform_apply.email}"
}

resource "google_service_account_iam_member" "github_wif_user" {
  for_each = toset(local.trusted_github_repositories)

  service_account_id = google_service_account.terraform_apply.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${local.effective_workload_identity_pool_name}/attribute.repository/${each.value}"

  depends_on = [
    google_iam_workload_identity_pool_provider.github,
  ]
}
