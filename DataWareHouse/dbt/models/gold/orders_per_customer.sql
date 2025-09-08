{{ config(materialized='view') }}

select
  c.customer_id,
  c.name,
  count(o.order_id) as orders_count,
  min(o.order_date) as first_order_date,
  max(o.order_date) as last_order_date
from {{ ref('orders') }} o
join {{ source('bronze', 'customers') }} c
  on c.customer_id = o.customer_id
group by c.customer_id, c.name
