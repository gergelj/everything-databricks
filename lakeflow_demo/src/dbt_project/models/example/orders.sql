-- This model creates an orders table from seed data
-- In a real scenario, this would read from your source tables

{{ config(materialized='table') }}

select
    order_id,
    customer_id,
    order_date,
    total_amount
from {{ ref('orders_seed') }}

