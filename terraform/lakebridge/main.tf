resource "databricks_schema" "lakebridge_schema" {
  catalog_name = var.catalog_name
  name         = var.schema_name
}

resource "databricks_volume" "lakebridge_volume" {
  name             = var.volume_name
  catalog_name     = var.catalog_name
  schema_name      = databricks_schema.lakebridge_schema.name
  volume_type      = "MANAGED"
}