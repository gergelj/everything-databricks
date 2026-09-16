# =============================================================================
# Metastore Assignment
# =============================================================================

resource "databricks_metastore_assignment" "this" {
  provider     = databricks.account
  workspace_id = module.databricks.databricks_workspace_id
  metastore_id = var.existing_metastore_id == "" ? databricks_metastore.this[0].id : var.existing_metastore_id
}

resource "databricks_metastore" "this" {
  count         = var.existing_metastore_id == "" ? 1 : 0
  provider      = databricks.account
  name          = var.new_metastore_name
  region        = var.location
}

# =============================================================================
# Catalog Creation
# =============================================================================

module "create_catalog" {
  source = "./modules/catalog"
  storage_account_id = module.connect_storage.storage_account_id
  storage_account_name = module.connect_storage.storage_account_name
  storage_credential_id = module.connect_storage.storage_credential_id
  catalog_name = var.catalog_name
  storage_container_name = var.storage_container_name
  force_destroy_external_location = false
  force_destroy_catalog = false
}