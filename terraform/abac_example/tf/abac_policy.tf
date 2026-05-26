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
  #when_condition = "has_tag('pii')"

  # Match specific columns
  match_columns = [
    {
      condition = "has_tag('${databricks_tag_policy.tag_rls.tag_key}')"
      alias     = "rls_col"
    }
  ]

  # Row filter function to apply
  row_filter = {
    function_name = "${var.catalog_name}.${var.schema_name}.filter_users_rls"
    using = [
      {
        alias = "rls_col"
      }
    ]
  }
}

resource "databricks_policy_info" "email_mask" {
  on_securable_type     = "CATALOG"
  on_securable_fullname = var.catalog_name
  name                  = "email_mask"
  comment = "This policy is used to apply Masking to the email column"

  policy_type           = "POLICY_TYPE_COLUMN_MASK"
  for_securable_type    = "TABLE"
  to_principals         = ["account users"]
  except_principals     = []

  # Condition for when the policy applies
  #when_condition = "has_tag('pii')"

  # Match specific columns
  match_columns = [
    {
      condition = "has_tag_value('${databricks_tag_policy.tag_mask.tag_key}', 'email')"
      alias     = "mask_col"
    }
  ]

  # Column mask function to apply
  column_mask = {
    function_name = "${var.catalog_name}.${var.schema_name}.filter_email"
    on_column = "mask_col"
  }
}

resource "databricks_policy_info" "age_mask" {
  on_securable_type     = "CATALOG"
  on_securable_fullname = var.catalog_name
  name                  = "age_mask"
  comment = "This policy is used to apply Masking to the age column"

  policy_type           = "POLICY_TYPE_COLUMN_MASK"
  for_securable_type    = "TABLE"
  to_principals         = ["account users"]
  except_principals     = []

  # Condition for when the policy applies
  #when_condition = "has_tag('pii')"

  # Match specific columns
  match_columns = [
    {
      condition = "has_tag_value('${databricks_tag_policy.tag_mask.tag_key}', 'age')"
      alias     = "mask_col"
    }
  ]

  # Column mask function to apply
  column_mask = {
    function_name = "${var.catalog_name}.${var.schema_name}.filter_age"
    on_column = "mask_col"
  }
}