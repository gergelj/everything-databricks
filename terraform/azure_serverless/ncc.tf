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

# -----------------------------------------------------------------------------
# Auto-approve NCC private endpoint connections on the DBFS storage account
# -----------------------------------------------------------------------------
data "azapi_resource" "storage_approvals" {
  type                   = "Microsoft.Storage/storageAccounts@2024-01-01"
  resource_id            = module.connect_storage.storage_account_id
  response_export_values = ["properties.privateEndpointConnections"]
  depends_on = [
    databricks_mws_ncc_private_endpoint_rule.blob,
    databricks_mws_ncc_private_endpoint_rule.dfs
  ]
}

locals {
  # azapi 2.x returns output as a typed object; [] if no connections yet.
  pe_connections = try(data.azapi_resource.storage_approvals.output.properties.privateEndpointConnections, [])
  blob_pe_name = [for pe in local.pe_connections : pe.name if endswith(try(pe.properties.privateEndpoint.id, ""), databricks_mws_ncc_private_endpoint_rule.blob.endpoint_name)][0]
  dfs_pe_name = [for pe in local.pe_connections : pe.name if endswith(try(pe.properties.privateEndpoint.id, ""), databricks_mws_ncc_private_endpoint_rule.dfs.endpoint_name)][0]
  ncc_description = "NCC: ${databricks_mws_network_connectivity_config.ncc.name} (${databricks_mws_network_connectivity_config.ncc.network_connectivity_config_id})"
  pe_approval_body = {
    properties = {
      privateLinkServiceConnectionState = {
        description = "Approved for Databricks ${local.ncc_description}"
        status      = "Approved"
      }
    }
  }
}

resource "azapi_update_resource" "ncc_pe_approve_blob" {
  type       = "Microsoft.Storage/storageAccounts/privateEndpointConnections@2024-01-01"
  name       = local.blob_pe_name
  parent_id  = module.connect_storage.storage_account_id
  body       = local.pe_approval_body
  depends_on = [data.azapi_resource.storage_approvals]
}

resource "azapi_update_resource" "ncc_pe_approve_dfs" {
  type      = "Microsoft.Storage/storageAccounts/privateEndpointConnections@2024-01-01"
  name      = local.dfs_pe_name
  parent_id = module.connect_storage.storage_account_id
  body      = local.pe_approval_body
  # Storage returns 409 StorageAccountOperationInProgress if two PE connection updates run concurrently.
  depends_on = [
    data.azapi_resource.storage_approvals,
    azapi_update_resource.ncc_pe_approve_blob,
  ]
}