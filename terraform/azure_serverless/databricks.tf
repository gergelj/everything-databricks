# =============================================================================
# Databricks Serverless Workspace
# =============================================================================
module "databricks" {
  source  = "Azure/avm-res-databricks-workspace/azurerm"
  version = "~> 0.5"

  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "premium"

  compute_mode = "Serverless"

  tags = var.tags
  enable_telemetry = false
  public_network_access_enabled = true
}

# =============================================================================
# Admin Access
# =============================================================================

# data "databricks_group" "admin_group" {
#     provider = databricks.account
#     display_name = "<YOUR_ADMIN_GROUP>"
# }

# resource "databricks_mws_permission_assignment" "workspace_admins" {
#   provider     = databricks.account
#   workspace_id = module.databricks.databricks_workspace_id
#   principal_id = data.databricks_group.admin_group.id
#   permissions  = ["ADMIN"]
# }