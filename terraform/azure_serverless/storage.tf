# =============================================================================
# Storage Connection to Unity Catalog
# =============================================================================

module "connect_storage" {
  source = "./modules/connect_storage"
  create_storage_account = true
  resource_group = var.resource_group_name
  location = var.location
  storage_account_name = var.storage_account_name
  tags = var.tags
}