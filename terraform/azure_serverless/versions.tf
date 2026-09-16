terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.12"
    }

    modtm = {
      source  = "Azure/modtm"
      version = "~> 0.3"
    }

    databricks = {
      source = "databricks/databricks"
      version = "~> 1.84"
    }
  }
}