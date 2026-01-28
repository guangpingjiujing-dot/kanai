{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'opportunity_events') }}
),

renamed as (
    select
        trim(event_id) as event_id,
        trim(sales_person_id) as sales_person_id,
        trim(customer_id) as customer_id,
        trim(product_id) as product_id,
        trim(branch_id) as branch_id,
        event_timestamp,
        trim(stage_id) as stage_id,
        -- NULLの場合は0で埋める
        isnull(expected_amount, 0) as expected_amount,
        isnull(contract_amount, 0) as contract_amount
    from source
)

select * from renamed
