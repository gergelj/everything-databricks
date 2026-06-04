# Databricks Attribute-Based Access Control (ABAC) Demo

This example demonstrates how to implement Attribute-Based Access Control (ABAC) in Databricks using Unity Catalog policies. The demo showcases:

- **Row-Level Security (RLS)**: Filtering rows based on user group membership and tenant attributes
- **Column Masking**: Masking sensitive data (email and age) based on column tags
- **Tag-Based Governance**: Using governed tags to apply policies dynamically

## Architecture

The solution consists of two main components:

1. **SQL Setup** (`setup.sql`): Creates demo tables, data, and security functions
2. **Terraform Configuration** (`tf/`): Deploys ABAC policies, tags, and groups

### Key Components

- **Demo Table**: `users_demo` - Contains user records with tenant information
- **Mapping Table**: `group_tenant_mapping` - Maps Databricks groups to tenant names
- **RLS Function**: `filter_users_rls` - Filters rows based on group membership
- **Masking Functions**: `filter_email`, `filter_age` - Mask sensitive columns

## Prerequisites

- Databricks workspace (AWS, Azure, or GCP)
- Unity Catalog enabled
- Terraform installed
- Databricks CLI configured
- Account admin access for group and workspace assignment management

## Setup Instructions

### 1. Prepare SQL Objects

Run the SQL setup script to create the demo tables and functions:

```sql
-- Edit the variables in setup.sql to match your environment
DECLARE OR REPLACE VARIABLE catalog_name STRING DEFAULT 'your_catalog';
DECLARE OR REPLACE VARIABLE schema_name STRING DEFAULT 'your_schema';

-- Then run the entire setup.sql script
```

This creates:
- `users_demo` table with 10 sample users across 3 tenants
- `group_tenant_mapping` table linking groups to tenants
- RLS function that checks group membership
- Column masking functions for email and age

### 2. Configure Terraform

Create a `terraform.tfvars` file from the example:

```bash
cd tf
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
workspace_url           = "https://your-workspace.cloud.databricks.com"
workspace_name          = "your-workspace-name"  # Required for AWS/GCP
databricks_account_id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
cloud_provider          = "aws"  # or "azure", "gcp"
catalog_name            = "your_catalog"
schema_name             = "your_schema"
databricks_cli_profile  = "your-profile"
```

### 3. Deploy with Terraform

Initialize and apply the Terraform configuration:

```bash
terraform init
terraform plan
terraform apply
```

This will create:
- Account group `abac_demo_group_1`
- Group membership (adds current user)
- Workspace access for the group
- Governed tags (`ABAC_DEMO_RLS`, `ABAC_DEMO_MASK`)
- Tag assignments to table columns
- ABAC policies for RLS and column masking

## How It Works

### Row-Level Security

1. The `ABAC_DEMO_RLS` tag is applied to the `tenant_name` column
2. The `tenant_rls` policy matches columns with this tag
3. For matched columns, the policy calls `filter_users_rls(tenant_name)`
4. The function checks if the user belongs to a group mapped to that tenant
5. Users only see rows for their assigned tenant(s)

**Example**: Users in `abac_demo_group_1` only see rows where `tenant_name = 'tenantB'`

### Column Masking

1. The `ABAC_DEMO_MASK` tag (with values `email`, `age`) is applied to respective columns
2. The `email_mask` policy matches columns tagged with `ABAC_DEMO_MASK:email`
3. The `age_mask` policy matches columns tagged with `ABAC_DEMO_MASK:age`
4. Masking functions replace actual values with:
   - Email: `***@***`
   - Age: `0`

### Policy Application

Policies are applied at the catalog level and automatically affect all tables within the catalog that match the policy conditions. The policies use:

- `to_principals = ["account users"]`: Applies to all users
- `match_columns`: Targets columns based on tag conditions
- `row_filter` or `column_mask`: Specifies the function to apply

## Testing the Demo

### As a Group Member

```sql
-- Query as a user in abac_demo_group_1
SELECT * FROM your_catalog.your_schema.users_demo;

-- Expected results:
-- - Only rows with tenant_name = 'tenantB' (Bob, Edward, Hannah)
-- - Email shows as '***@***'
-- - Age shows as 0
```

### As an Admin (with except_principals)

To exempt admins from policies, modify the policies:

```hcl
resource "databricks_policy_info" "tenant_rls" {
  # ... other config ...
  except_principals = ["your-admin-group"]
}
```

## Cleanup

To remove all resources:

```bash
cd tf
terraform destroy
```

Then manually drop the SQL objects:

```sql
DROP TABLE IF EXISTS your_catalog.your_schema.users_demo;
DROP TABLE IF EXISTS your_catalog.your_schema.group_tenant_mapping;
DROP FUNCTION IF EXISTS your_catalog.your_schema.filter_users_rls;
DROP FUNCTION IF EXISTS your_catalog.your_schema.filter_email;
DROP FUNCTION IF EXISTS your_catalog.your_schema.filter_age;
```

## Key Concepts

### Governed Tags

Governed tags are centrally managed metadata that can be used to enforce policies. Unlike regular tags:
- Defined at the account level
- Can have controlled values
- Used in policy conditions
- Provide governance and compliance

### Policy Types

- **POLICY_TYPE_ROW_FILTER**: Controls which rows users can see
- **POLICY_TYPE_COLUMN_MASK**: Transforms column values before display

### Policy Matching

Policies use conditions to determine which columns/tables they apply to:
- `has_tag(tag_key)`: Matches any column with the tag
- `has_tag_value(tag_key, tag_value)`: Matches columns with specific tag value

## References

- [Databricks Unity Catalog ABAC Documentation](https://docs.databricks.com/en/data-governance/unity-catalog/abac.html)
- [Row and Column Filters](https://docs.databricks.com/en/data-governance/unity-catalog/manage-privileges/row-and-column-filters.html)
- [Terraform Provider - databricks_policy_info](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/policy_info)
