# Sample dbt Project

This is a sample dbt project demonstrating basic transformations with Databricks.

## Project Structure

```
dbt_project/
├── models/
│   └── example/
│       ├── schema.yml          # Model documentation and tests
│       ├── customers.sql       # Customers model
│       ├── orders.sql          # Orders model
│       └── customer_orders_summary.sql  # Aggregated summary
├── seeds/
│   ├── customers_seed.csv      # Sample customer data
│   └── orders_seed.csv         # Sample order data
├── dbt_project.yml             # Project configuration
└── profiles.yml                # Connection profile
```

## Models

1. **customers**: Base customer table loaded from seed data
2. **orders**: Base orders table loaded from seed data
3. **customer_orders_summary**: Aggregated view showing total orders and spending per customer

## Running the Project

This project is configured to run as part of a Databricks job. The job file is located at:
`../resources/dbt_sample_job.job.yml`

To run locally (if you have dbt installed):
```bash
dbt seed
dbt run
dbt test
```

## Notes

- The project uses the `databricks` adapter
- Models are materialized as tables
- Sample data is provided in the `seeds/` directory
- Tests are defined in `schema.yml` for data quality checks

