output "workspace_url" {
  value = "https://${module.databricks.databricks_workspace_url}"
}

output "databricks_id" {
  value = module.databricks.databricks_id
}

output "databricks_workspace_id" {
  value = module.databricks.databricks_workspace_id
}

output "resource" {
  value = module.databricks.resource
}

output "resource_id" {
  value = module.databricks.resource_id
}