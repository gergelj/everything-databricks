# Azure Databricks Serverless Workspace (Terraform)

Provisions a **serverless Azure Databricks workspace** with Unity Catalog and
**private networking** wired up end to end:

- A premium, serverless Databricks workspace (via the [Azure AVM module](https://registry.terraform.io/modules/Azure/avm-res-databricks-workspace/azurerm/latest)).
- A Unity Catalog metastore assignment (create a new metastore or attach an existing one).
- A **private** Azure ADLS Gen2 storage account (public network access disabled) + access connector (managed identity) for UC storage.
- A UC storage credential, external location, and catalog backed by that storage.
- **Front-end PrivateLink**: a private endpoint for the workspace web UI + REST API (`databricks_ui_api`), a private DNS zone, and a VNet link.
- **Back-end private connectivity for serverless**: a Network Connectivity Configuration (NCC) bound to the workspace, with private endpoint rules to the storage account (blob + dfs) that are auto-approved on the storage side.
- (Optional) Workspace admin access for a Databricks account group.



## Architecture

```
                         ┌─────────────────────────────────────────────┐
                         │  Azure Subscription / Resource Group        │
                         │                                             │
  module.databricks ────►│  Databricks Workspace (Serverless)          │
                         │                                             │
  module.connect_storage►│  Storage Account (ADLS Gen2, private)       │
                         │  Databricks Access Connector (MSI)          │
                         │  Role assignments (Blob/Queue/EventGrid)    │
                         │                                             │
  frontend_privatelink ─►│  Private Endpoint (databricks_ui_api)       │
                         │  Private DNS zone + VNet link               │
                         └─────────────────────────────────────────────┘
                                          │
        databricks.account provider       │   default (workspace) provider
        (accounts.azuredatabricks.net)    ▼   (adb-<id>.azuredatabricks.net)
                         ┌─────────────────────────────────────────────┐
                         │  Unity Catalog                              │
                         │   • Metastore + assignment                  │
                         │   • Storage credential                      │
                         │   • External location                       │
                         │   • Catalog                                 │
                         │                                             │
                         │  Network Connectivity Config (NCC)          │
                         │   • Workspace binding                       │
                         │   • Private endpoint rules (blob, dfs) ─────┼──► auto-approved
                         └─────────────────────────────────────────────┘      on storage
```



## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.6.0`
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), logged in:
  ```bash
  az login
  az account set --subscription <your-subscription-id>
  ```
- **Databricks account admin** rights (needed to create/assign metastores, manage workspace permission assignments, and create the NCC + private endpoint rules at the account level).
- An existing **Azure resource group** (`resource_group_name`) — this project deploys *into* it and does not create it.
- An existing **VNet and subnet** for the front-end PrivateLink private endpoint (`privatelink_vnet_id`, `privatelink_subnet_id`). This project does not create them.
- Authentication is via the **Azure CLI**. Both the account-level and workspace-level Databricks providers authenticate using your `az login` session and tenant ID — no PAT or service principal secret is required.



## Provider setup

Two `databricks` providers are configured in `providers.tf`:


| Provider                       | Endpoint                                         | Used for                                                                                                     |
| ------------------------------ | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `databricks.account` (aliased) | `accounts.azuredatabricks.net`                   | Account-level objects: metastore, metastore assignment, workspace permission assignments, NCC + PE rules     |
| `databricks` (default)         | `https://adb-<workspace-id>.azuredatabricks.net` | Workspace-level Unity Catalog objects: storage credential, external location, catalog                        |


The default provider's host is derived from the workspace module output, so it resolves automatically after the workspace is created.

In addition to `azurerm` and the two `databricks` providers, the configuration
uses the **`azapi`** provider (to auto-approve the NCC private endpoint
connections on the storage account) and the **`modtm`** provider (a transitive
dependency of the AVM workspace module). See `versions.tf` for the pinned
version constraints.

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
| `privatelink_subnet_id`  | ✅        | —       | Resource ID of the existing subnet where the `databricks_ui_api` private endpoint is created |
| `privatelink_vnet_id`    | ✅        | —       | Resource ID of the existing VNet the `privatelink.azuredatabricks.net` DNS zone is linked to |
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

# Front-end PrivateLink (existing VNet + subnet)
privatelink_subnet_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>"
privatelink_vnet_id   = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/<vnet>"

tags = {
  Owner = "your.name@example.com"
}
```



## Networking

This deployment locks down both directions of network access:

- **Storage account is private.** `module.connect_storage` creates the ADLS Gen2
  account with `public_network_access_enabled = false`, so it is not reachable
  over the public internet.
- **Serverless → storage (back end).** A **Network Connectivity Configuration
  (NCC)** is created and bound to the workspace (`ncc.tf`), with private endpoint
  rules for the `blob` and `dfs` sub-resources of the storage account. The blob
  and dfs rules are created sequentially (with a short `time_sleep` between them)
  to avoid overloading the account API. Serverless compute uses these rules to
  reach the storage account privately.
- **Auto-approval on storage.** `ncc_auto_approve.tf` reads the pending private
  endpoint connections on the storage account and approves them via the `azapi`
  provider, so you don't have to approve them by hand in the Azure portal. The
  two connections are approved sequentially to avoid a `409
  StorageAccountOperationInProgress` conflict.
- **Workspace UI/API (front end).** `frontend_privatelink.tf` creates a private
  endpoint for the `databricks_ui_api` sub-resource in your subnet, plus a
  `privatelink.azuredatabricks.net` private DNS zone linked to your VNet so the
  workspace hostname resolves to the private IP.

> **Note:** `public_network_access_enabled` is intentionally left **`true`** on
> the *workspace* (see `databricks.tf`), so the workspace UI/API remains
> reachable publicly *and* over the front-end private endpoint. Set it to
> `false` if you want to force private-only access.



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
├── storage.tf                 # connect_storage module (private storage account, access connector, roles)
├── unity_catalog.tf           # Metastore, metastore assignment, catalog module
├── ncc.tf                     # NCC, workspace binding, private endpoint rules (blob, dfs)
├── ncc_auto_approve.tf        # Auto-approve NCC private endpoint connections on the storage account (azapi)
├── frontend_privatelink.tf    # Front-end PrivateLink: private endpoint (databricks_ui_api), DNS zone, VNet link
├── providers.tf               # azurerm + two databricks providers (account + workspace)
├── variables.tf               # Input variables
├── outputs.tf                 # Outputs
├── versions.tf                # Terraform + provider version constraints (azurerm, databricks, azapi, modtm)
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
