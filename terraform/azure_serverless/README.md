# Azure Databricks Serverless Workspace (Terraform)

Provisions a **serverless Azure Databricks workspace** with Unity Catalog wired up end to end:

- A premium, serverless-mode Databricks workspace (via the [Azure AVM module](https://registry.terraform.io/modules/Azure/avm-res-databricks-workspace/azurerm/latest)).
- A Unity Catalog metastore assignment (create a new metastore or attach an existing one).
- An Azure storage account + access connector (managed identity) for UC storage.
- A UC storage credential, external location, and catalog backed by that storage.
- (Optional) Workspace admin access for a Databricks account group.



## Architecture

```
                         ┌─────────────────────────────────────────┐
                         │  Azure Subscription / Resource Group    │
                         │                                         │
  module.databricks ────►│  Databricks Workspace (Serverless)      │
                         │                                         │
  module.connect_storage►│  Storage Account (ADLS Gen2)            │
                         │  Databricks Access Connector (MSI)      │
                         │  Role assignments (Blob/Queue/EventGrid)│
                         └─────────────────────────────────────────┘
                                          │
        databricks.account provider       │   default (workspace) provider
        (accounts.azuredatabricks.net)    ▼   (adb-<id>.azuredatabricks.net)
                         ┌─────────────────────────────────────────┐
                         │  Unity Catalog                          │
                         │   • Metastore + assignment              │
                         │   • Storage credential                  │
                         │   • External location                   │
                         │   • Catalog                             │
                         └─────────────────────────────────────────┘
```



## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.6.0`
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), logged in:
  ```bash
  az login
  az account set --subscription <your-subscription-id>
  ```
- **Databricks account admin** rights (needed to create/assign metastores and manage workspace permission assignments at the account level).
- An existing **Azure resource group** (`resource_group_name`) — this project deploys *into* it and does not create it.
- Authentication is via the **Azure CLI**. Both the account-level and workspace-level Databricks providers authenticate using your `az login` session and tenant ID — no PAT or service principal secret is required.



## Provider setup

Two `databricks` providers are configured in `providers.tf`:


| Provider                       | Endpoint                                         | Used for                                                                                 |
| ------------------------------ | ------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| `databricks.account` (aliased) | `accounts.azuredatabricks.net`                   | Account-level objects: metastore, metastore assignment, workspace permission assignments |
| `databricks` (default)         | `https://adb-<workspace-id>.azuredatabricks.net` | Workspace-level Unity Catalog objects: storage credential, external location, catalog    |


The default provider's host is derived from the workspace module output, so it resolves automatically after the workspace is created.

## Configuration

Copy the example tfvars and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```



### Variables


| Variable                 | Required | Default | Description                                                                                |
| ------------------------ | -------- | ------- | ------------------------------------------------------------------------------------------ |
| `tenant_id`              | ✅        | —       | Azure tenant ID                                                                            |
| `azure_subscription_id`  | ✅        | —       | Azure subscription ID                                                                      |
| `resource_group_name`    | ✅        | —       | Existing resource group to deploy into                                                     |
| `workspace_name`         | ✅        | —       | Name of the Databricks workspace                                                           |
| `location`               | ✅        | —       | Azure region (validated against Databricks-supported regions, e.g. `westeurope`)           |
| `databricks_account_id`  | ✅        | —       | Databricks account ID (sensitive)                                                          |
| `catalog_name`           | ✅        | —       | Name of the Unity Catalog catalog to create                                                |
| `storage_account_name`   | ✅        | —       | Name of the ADLS Gen2 storage account (3–24 lowercase alphanumeric chars, globally unique) |
| `storage_container_name` | ✅        | —       | Name of the storage container / UC root path                                               |
| `existing_metastore_id`  | —        | `""`    | Attach an existing metastore. Leave empty to create a new one                              |
| `new_metastore_name`     | —        | `""`    | Name for a new metastore (only used when `existing_metastore_id` is empty)                 |
| `tags`                   | —        | `{}`    | Map of tags applied to resources                                                           |


> **Metastore choice:** set **either** `existing_metastore_id` (to reuse a metastore — recommended, since a region can only have one) **or** `new_metastore_name` (to create one). Leaving both empty will fail unless a new metastore is created; most Azure regions already have a metastore, so prefer `existing_metastore_id`.



### Example `terraform.tfvars`

```hcl
tenant_id             = "00000000-0000-0000-0000-000000000000"
azure_subscription_id = "00000000-0000-0000-0000-000000000000"
resource_group_name   = "my-resource-group"
workspace_name        = "my-databricks-serverless"
location              = "westeurope"
databricks_account_id = "00000000-0000-0000-0000-000000000000"

# Unity Catalog + storage
existing_metastore_id  = "7215a9fc-0933-4efd-b718-c2fd8ac512b9"  # or leave "" and set new_metastore_name
new_metastore_name     = ""
catalog_name           = "demo"
storage_account_name   = "myucstorage"   # must be globally unique, lowercase alphanumeric
storage_container_name = "demo"

tags = {
  Owner = "your.name@example.com"
}
```



## Usage

```bash
# Initialize providers and modules
terraform init

# Preview changes
terraform plan

# Apply
terraform apply
# or non-interactively:
terraform apply -auto-approve
```



### Enabling workspace admin access (optional)

Assigning a Databricks account group as workspace admin is scaffolded but commented out in `databricks.tf`. To enable it, uncomment the `databricks_group` data source and `databricks_mws_permission_assignment` resource, and set the group's `display_name`. Both use `provider = databricks.account`.

## Outputs


| Output          | Description                                                   |
| --------------- | ------------------------------------------------------------- |
| `workspace_url` | The Databricks workspace URL (`adb-<id>.azuredatabricks.net`) |




## Project layout

```
.
├── databricks.tf              # Workspace module + (optional) admin access
├── storage.tf                 # connect_storage module (storage account, access connector, roles)
├── unity_catalog.tf           # Metastore, metastore assignment, catalog module
├── providers.tf               # azurerm + two databricks providers (account + workspace)
├── variables.tf               # Input variables
├── outputs.tf                 # Outputs
├── versions.tf                # Terraform + provider version constraints
├── terraform.tfvars.example   # Copy to terraform.tfvars and fill in
└── modules/
    ├── connect_storage/       # Storage account, access connector, role assignments, storage credential
    └── catalog/               # External location + catalog
```



## Cleanup

```bash
terraform destroy
```

> **Note:** the external location and catalog are created with `force_destroy = false`, so `destroy` will fail if the catalog contains schemas/tables or the location has data. Remove that data first, or set `force_destroy_external_location` / `force_destroy_catalog` to `true` in `unity_catalog.tf` (**this permanently deletes data**).
