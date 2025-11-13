-- This model creates a customers table from seed data
-- In a real scenario, this would read from your source tables

{{ config(materialized='table') }}

select
    customer_id,
    first_name,
    last_name,
    email,
    registration_date
from {{ ref('customers_seed') }}

