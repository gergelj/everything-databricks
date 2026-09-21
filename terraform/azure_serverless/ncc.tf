# -----------------------------------------------------------------------------
# Network Connectivity Configuration (NCC)
# -----------------------------------------------------------------------------
resource "databricks_mws_network_connectivity_config" "ncc" {
  provider = databricks.account
  name     = "${var.workspace_name}-ncc"
  region   = var.location
}

# -----------------------------------------------------------------------------
# Attach NCC to this workspace
# -----------------------------------------------------------------------------
resource "databricks_mws_ncc_binding" "ncc_binding" {
  provider                       = databricks.account
  network_connectivity_config_id = databricks_mws_network_connectivity_config.ncc.network_connectivity_config_id
  workspace_id                   = module.databricks.databricks_workspace_id
}

# -----------------------------------------------------------------------------
# Private endpoint rule: Blob
# -----------------------------------------------------------------------------
resource "databricks_mws_ncc_private_endpoint_rule" "blob" {
  provider                       = databricks.account
  network_connectivity_config_id = databricks_mws_network_connectivity_config.ncc.network_connectivity_config_id
  resource_id                    = module.connect_storage.storage_account_id
  group_id                       = "blob"
}

# Brief pause after blob rule so the dfs rule creation starts without overloading the account API.
resource "time_sleep" "after_ncc_blob_rule" {
  create_duration = "75s"
  depends_on      = [databricks_mws_ncc_private_endpoint_rule.blob]
}

# -----------------------------------------------------------------------------
# Private endpoint rule: DFS
# -----------------------------------------------------------------------------
resource "databricks_mws_ncc_private_endpoint_rule" "dfs" {
  provider                       = databricks.account
  network_connectivity_config_id = databricks_mws_network_connectivity_config.ncc.network_connectivity_config_id
  resource_id                    = module.connect_storage.storage_account_id
  group_id                       = "dfs"
  depends_on                     = [time_sleep.after_ncc_blob_rule]
}