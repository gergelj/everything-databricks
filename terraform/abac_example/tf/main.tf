data "databricks_current_user" "me" {
}

resource "databricks_schema" "schema" {
  catalog_name = var.catalog_name
  name         = var.schema_name
  force_destroy = true
}

locals {
    users_demo_table_name = "users_demo"
    group_tenant_mapping_table_name = "group_tenant_mapping"
}

resource "databricks_sql_table" "users_demo" {
  name         = local.users_demo_table_name
  catalog_name = var.catalog_name
  schema_name  = databricks_schema.schema.name
  table_type   = "MANAGED"
  warehouse_id = var.serverless_warehouse_id

  column {
    name = "id"
    type = "int"
  }
  column {
    name    = "user_name"
    type    = "string"
  }
  column {
    name    = "email"
    type    = "string"
  }
  column {
    name    = "age"
    type    = "int"
  }
  column {
    name    = "tenant_name"
    type    = "string"
  }

  comment = "this table is managed by terraform"
}

resource "databricks_sql_table" "group_tenant_mapping" {
  name         = local.group_tenant_mapping_table_name
  catalog_name = var.catalog_name
  schema_name  = databricks_schema.schema.name
  table_type   = "MANAGED"
  warehouse_id = var.serverless_warehouse_id

  column {
    name = "group_name"
    type = "string"
  }
  column {
    name = "tenant_name"
    type = "string"
  }

  comment = "this table is managed by terraform"
}

resource "databricks_notebook" "notebook" {
  content_base64 = base64encode(<<-EOT
    USE CATALOG ${var.catalog_name};
    USE SCHEMA ${databricks_schema.schema.name};

    CREATE OR REPLACE FUNCTION filter_users_rls(tenant STRING)
    RETURNS BOOLEAN
    RETURN CASE
        WHEN tenant IS NULL THEN FALSE
        ELSE EXISTS (
            SELECT
            1
            FROM
            ${var.catalog_name}.${databricks_schema.schema.name}.${local.group_tenant_mapping_table_name} m
            WHERE
        m.tenant_name = tenant
        AND is_account_group_member(m.group_name)
    )
    END;

    INSERT INTO ${local.users_demo_table_name} VALUES
        (1, 'Alice', 'alice@company.com', 42, 'tenantA'),
        (2, 'Bob', 'bob@company.com', 35, 'tenantB'),
        (3, 'Charlie', 'charlie@company.com', 27, 'tenantA'),
        (4, 'Diana', 'diana@company.com', 58, 'tenantC'),
        (5, 'Edward', 'edward@company.com', 19, 'tenantB'),
        (6, 'Fiona', 'fiona@company.com', 63, 'tenantA'),
        (7, 'George', 'george@company.com', 22, 'tenantC'),
        (8, 'Hannah', 'hannah@company.com', 47, 'tenantB'),
        (9, 'Ian', 'ian@company.com', 31, 'tenantA'),
        (10, 'Julia', 'julia@company.com', 54, 'tenantC');

    INSERT INTO ${local.group_tenant_mapping_table_name} VALUES
        ('abac_demo_group_1', 'tenantB');
    
    EOT
  )
  path     = "/Workspace/Users/${data.databricks_current_user.me.user_name}/abac_demo"
  language = "SQL"
}

resource "databricks_tag_policy" "tag_rls" {
  tag_key     = "ABAC_DEMO_RLS"
  description = "Tag for Row Level Security"
}

resource "databricks_entity_tag_assignment" "tag_rls_assignment" {
  entity_type = "columns"
  entity_name = "${databricks_sql_table.users_demo.id}.tenant_name"
  tag_key     = "${databricks_tag_policy.tag_rls.tag_key}"
  tag_value   = ""
}

resource "databricks_tag_policy" "tag_mask" {
  tag_key     = "ABAC_DEMO_MASK"
  values = [
    {
      name = "email"
    },
    {
      name = "age"
    } 
  ]
  description = "Tag for Masking"
}

resource "databricks_entity_tag_assignment" "tag_mask_assignment_email" {
  entity_type = "columns"
  entity_name = "${databricks_sql_table.users_demo.id}.email"
  tag_key     = "${databricks_tag_policy.tag_mask.tag_key}"
  tag_value   = "email"
}

resource "databricks_entity_tag_assignment" "tag_mask_assignment_age" {
  entity_type = "columns"
  entity_name = "${databricks_sql_table.users_demo.id}.age"
  tag_key     = "${databricks_tag_policy.tag_mask.tag_key}"
  tag_value   = "age"
}

resource "databricks_policy_info" "tenant_rls" {
  on_securable_type     = "CATALOG"
  on_securable_fullname = var.catalog_name
  name                  = "tenant_rls"
  comment = "This policy is used to apply Row Level Security to the users_demo table"

  policy_type           = "POLICY_TYPE_ROW_FILTER"
  for_securable_type    = "TABLE"
  to_principals         = ["account users"]
  except_principals     = []

  # Condition for when the policy applies
  #when_condition = "hasTag('pii')"

  # Match specific columns
  match_columns = [
    {
      condition = "hasTag('${databricks_tag_policy.tag_rls.tag_key}')"
      alias     = "rls_col"
    }
  ]

  # Row filter function to apply
  row_filter = {
    function_name = "${var.catalog_name}.${databricks_schema.schema.name}.filter_users_rls"
    using = [
      {
        alias = "rls_col"
      }
    ]
  }
}

resource "databricks_group" "group" {
  provider = databricks.accounts
  display_name = "abac_demo_group_1"
}

resource "databricks_group_member" "group_member" {
  provider = databricks.accounts
  group_id = databricks_group.group.id
  member_id = data.databricks_current_user.me.id
}

locals {
  workspace_id  = var.cloud_provider == "azure" ? regex("adb-(\\d+)\\.", var.workspace_url)[0] : data.databricks_mws_workspaces.all[0].ids["gergeljkis-serverless"]
}

resource "databricks_mws_permission_assignment" "workspace_access" {
  provider = databricks.accounts
  workspace_id = local.workspace_id
  principal_id = databricks_group.group.id
  permissions  = ["USER"]
}

data "databricks_mws_workspaces" "all" {
    count = var.cloud_provider == "azure" ? 0 : 1
    provider = databricks.accounts
}
