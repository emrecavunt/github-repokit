locals {
  role_bindings = flatten([
    for project_id, roles in var.target_project_roles : [
      for role in roles : {
        project_id = project_id
        role       = role
      }
    ]
  ])

  role_binding_map = {
    for binding in local.role_bindings :
    "${binding.project_id}:${binding.role}" => binding
  }

  trusted_github_repositories = distinct(compact(concat([var.github_repository], tolist(var.github_repositories))))

  owner_attribute_condition = trimspace(var.github_owner) != "" ? [
    "assertion.repository_owner==\"${var.github_owner}\""
  ] : []

  repository_attribute_condition = length(local.trusted_github_repositories) > 0 ? [
    format("(%s)", join(" || ", [
      for repo in local.trusted_github_repositories :
      "assertion.repository==\"${repo}\""
    ]))
  ] : []

  default_github_provider_attribute_condition = join(" && ", concat(
    local.owner_attribute_condition,
    local.repository_attribute_condition
  ))

  github_provider_attribute_condition = coalesce(
    var.github_provider_attribute_condition,
    local.default_github_provider_attribute_condition
  )

  effective_workload_identity_pool_name     = var.create_project_wif_provider ? google_iam_workload_identity_pool.github[0].name : var.workload_identity_pool_name
  effective_workload_identity_provider_name = var.create_project_wif_provider ? google_iam_workload_identity_pool_provider.github[0].name : var.workload_identity_provider_name
}
