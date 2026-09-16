provider "azurerm" {
  subscription_id = var.azure_subscription_id
  tenant_id = var.tenant_id
  features {}
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.databricks_account_id
  azure_tenant_id = var.tenant_id
}

provider "databricks" {
  host                        = "https://${module.databricks.databricks_workspace_url}"
  azure_workspace_resource_id = module.databricks.resource_id
  azure_tenant_id             = var.tenant_id
}