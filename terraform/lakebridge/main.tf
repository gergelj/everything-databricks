resource "databricks_schema" "lakebridge_schema" {
  catalog_name = var.catalog_name
  name         = "lakebridge"
}

resource "databricks_volume" "lakebridge_volume" {
  name             = "lakebridge_volume"
  catalog_name     = var.catalog_name
  schema_name      = databricks_schema.lakebridge_schema.name
  volume_type      = "MANAGED"
}