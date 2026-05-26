# RLS Tag
resource "databricks_tag_policy" "tag_rls" {
  tag_key     = "ABAC_DEMO_RLS"
  description = "Tag for Row Level Security"
}

resource "databricks_entity_tag_assignment" "tag_rls_assignment" {
  entity_type = "columns"
  entity_name = "${local.users_demo_table_name}.tenant_name"
  tag_key     = "${databricks_tag_policy.tag_rls.tag_key}"
  tag_value   = ""
}

# Column Mask Tags
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
  entity_name = "${local.users_demo_table_name}.email"
  tag_key     = "${databricks_tag_policy.tag_mask.tag_key}"
  tag_value   = "email"
}

resource "databricks_entity_tag_assignment" "tag_mask_assignment_age" {
  entity_type = "columns"
  entity_name = "${local.users_demo_table_name}.age"
  tag_key     = "${databricks_tag_policy.tag_mask.tag_key}"
  tag_value   = "age"
}