output "terraform_apply_service_account_email" {
  description = "Email of the Terraform apply service account. Set this as GCP_TERRAFORM_SA on the actions stack."
  value       = google_service_account.terraform_apply.email
}

output "terraform_apply_service_account_name" {
  description = "Fully qualified name of the Terraform apply service account."
  value       = google_service_account.terraform_apply.name
}

output "workload_identity_provider_name" {
  description = "Workload identity provider resource name. Set this as GCP_WORKLOAD_IDENTITY_PROVIDER on the actions stack."
  value       = local.effective_workload_identity_provider_name
}

output "workload_identity_pool_name" {
  description = "Workload identity pool resource name used by GitHub Actions."
  value       = local.effective_workload_identity_pool_name
}
