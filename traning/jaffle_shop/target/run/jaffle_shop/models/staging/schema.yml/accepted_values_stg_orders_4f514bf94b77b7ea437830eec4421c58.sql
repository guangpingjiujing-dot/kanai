
    with test_main_sql as (
  
    
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from "jaffle_warehouse"."jaffle_training"."stg_orders"
    group by status

)

select *
from all_values
where value_field not in (
    'placed','shipped','completed','return_pending','returned'
)



  
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