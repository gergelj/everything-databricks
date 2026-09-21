# =============================================================================
# Front-end / Back-end PrivateLink to the Databricks workspace control plane
# -----------------------------------------------------------------------------
# Creates a private endpoint (sub-resource: databricks_ui_api) in your own
# VNet's subnet, so the workspace web UI + REST API are reachable over a private
# IP. A private DNS zone (privatelink.azuredatabricks.net) is created and linked
# to the VNet so the workspace hostname resolves to that private IP.
#
# Note: public_network_access_enabled is intentionally left true on the
# workspace, so this endpoint works alongside public access.
# =============================================================================

# -----------------------------------------------------------------------------
# Private endpoint: databricks_ui_api
# -----------------------------------------------------------------------------
resource "azurerm_private_endpoint" "ui_api" {
  name                = "${var.workspace_name}-ui-api-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.privatelink_subnet_id

  private_service_connection {
    name                           = "${var.workspace_name}-ui-api-psc"
    private_connection_resource_id = module.databricks.resource_id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "databricks-ui-api"
    private_dns_zone_ids = [azurerm_private_dns_zone.databricks.id]
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Private DNS zone: privatelink.azuredatabricks.net
# -----------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "databricks" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Link the private DNS zone to your VNet
# -----------------------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "databricks" {
  name                  = "${var.workspace_name}-dbx-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.databricks.name
  virtual_network_id    = var.privatelink_vnet_id
  registration_enabled  = false

  tags = var.tags
}
