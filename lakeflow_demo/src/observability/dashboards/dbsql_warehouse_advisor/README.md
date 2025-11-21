## DBSQL Warehouse Advisor dashboard

This dashboard references [this Medium blog post](https://medium.com/dbsql-sme-engineering/the-dbsql-warehouse-advisor-dashboard-v5-multi-warehouse-analytics-ef4f07578ac1).

## How to install

1. Run the `setup` notebook to create the necessary external location and catalog.
2. Run one of the sql files:
    - Table Version: for static data
    - Streaming Table Version
    - or Materialized View Version for periodic refreshes.
3. Publish the dashboard
