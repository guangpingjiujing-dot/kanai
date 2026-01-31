
    with test_main_sql as (
  
    
    
    

select
    customer_id as unique_field,
    count(*) as n_records

from "jaffle_warehouse"."jaffle_training"."stg_customers"
where customer_id is not null
group by customer_id
having count(*) > 1



  
  ),
  dbt_internal_test as (
    select  * from test_main_sql
  )
  select
    count(*) as failures,
    case when count(*) != 0
      then 'true' else 'false' end as should_warn,
    case when count(*) != 0
      then 'true' else 'false' end as should_error
  from dbt_internal_test