# =============================================================================
# Azure Configuration
# =============================================================================

variable "tenant_id" {
    description = "Your Azure Tenant ID"
    type        = string
}

variable "azure_subscription_id" {
    description = "Your Azure Subscription ID"
    type        = string
}

variable "resource_group_name" {
    description = "The name of the resource group"
    type        = string
}

variable "tags" {
    description = "A map of tags to assign to the resources"
    type        = map(string)
    default     = {}
}

# # =============================================================================
# # Databricks Configuration
# # =============================================================================

variable "databricks_account_id" {
  description = "ID of the Databricks account"
  type        = string
  sensitive   = true
}

variable "workspace_name" {
    description = "The name of the Databricks workspace"
    type        = string  
}

variable "location" {
    description = "The Azure region to deploy the workspace to"
    type        = string
    validation {
    condition = contains([
      "australiacentral", "australiacentral2", "australiaeast", "australiasoutheast", "brazilsouth", "canadacentral", "canadaeast", "centralindia", "centralus", "chinaeast2", "chinaeast3", "chinanorth2", "chinanorth3", "eastasia", "eastus", "eastus2", "francecentral", "germanywestcentral", "japaneast", "japanwest", "koreacentral", "mexicocentral", "northcentralus", "northeurope", "norwayeast", "qatarcentral", "southafricanorth", "southcentralus", "southeastasia", "southindia", "swedencentral", "switzerlandnorth", "switzerlandwest", "uaenorth", "uksouth", "ukwest", "westcentralus", "westeurope", "westindia", "westus", "westus2", "westus3"
    ], var.location)
    error_message = "Valid values for var.location are standard Azure regions supported by Databricks."
  }
}

# # =============================================================================
# # Unity Catalog and Storage Configuration
# # =============================================================================

variable "existing_metastore_id" {
    description = "The ID of the existing metastore. Leave empty to create a new metastore."
    type        = string
    default     = ""
}

variable "new_metastore_name" {
    description = "The name of the new metastore."
    type        = string
    default     = ""
    validation {
        condition     = can(regex("^[a-zA-Z0-9_-]*$", var.new_metastore_name))
        error_message = "metastore_name can only contain alphanumerical characters, hyphens, and underscores."
    }
}

variable "catalog_name" {
  type        = string
  description = "Name of the Unity Catalog catalog"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the Azure storage account"
}

variable "storage_container_name" {
  type        = string
  description = "Name of the storage container"
}

# # =============================================================================
# # Front-end PrivateLink Configuration
# # =============================================================================

variable "privatelink_subnet_id" {
  description = "Resource ID of the existing subnet in your VNet where the databricks_ui_api private endpoint will be created."
  type        = string
}

variable "privatelink_vnet_id" {
  description = "Resource ID of the existing VNet that the privatelink.azuredatabricks.net private DNS zone will be linked to."
  type        = string
}