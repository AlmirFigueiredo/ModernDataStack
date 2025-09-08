
  
    

  create  table "dw"."silver"."orders__dbt_tmp"
  
  
    as
  
  (
    

select
  order_id,
  customer_id,
  order_date,
  created_at,
  status
from "dw"."bronze"."orders"
  );
  