variable "workspace_url" {
  description = "The URL of the Databricks workspace"
  type = string
}

variable "databricks_account_id" {
  description = "The ID of the Databricks account"
  type = string
}

variable "cloud_provider" {
  description = "The cloud provider"
  type = string
  validation {
    condition = contains(["azure", "aws", "gcp"], var.cloud_provider)
    error_message = "Invalid cloud provider. Valid values are azure, aws, gcp."
  }
}

variable "catalog_name" {
  description = "The name of the catalog"
  type = string
}

variable "schema_name" {
  description = "The name of the schema"
  type = string
  default = "abac_demo"
}

variable "databricks_cli_profile" {
  description = "The profile of the Databricks CLI"
  type = string
}

variable "serverless_warehouse_id" {
  description = "The ID of the serverless warehouse"
  type = string
}