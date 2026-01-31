with source as (
    select * from "jaffle_warehouse"."jaffle_training"."raw_payments"
),

renamed as (
    select
        id as payment_id,
        order_id,
        payment_method,
        amount / 100.0 as amount
    from source
)

select * from renamed