-- This model creates a summary of customer orders
-- It aggregates order data by customer

{{ config(materialized='table') }}

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    count(o.order_id) as total_orders,
    coalesce(sum(o.total_amount), 0) as total_spent,
    avg(o.total_amount) as avg_order_value,
    min(o.order_date) as first_order_date,
    max(o.order_date) as last_order_date
from {{ ref('customers') }} c
left join {{ ref('orders') }} o
    on c.customer_id = o.customer_id
group by
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email

