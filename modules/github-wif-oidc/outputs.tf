output "terraform_apply_service_account_email" {
  value = google_service_account.terraform_apply.email
}

output "terraform_apply_service_account_name" {
  value = google_service_account.terraform_apply.name
}

output "workload_identity_provider_name" {
  value = local.effective_workload_identity_provider_name
}

output "workload_identity_pool_name" {
  value = local.effective_workload_identity_pool_name
}
