{{ config(materialized='table') }}

select
  order_id,
  customer_id,
  order_date,
  created_at,
  status
from {{ source('bronze', 'orders') }}
