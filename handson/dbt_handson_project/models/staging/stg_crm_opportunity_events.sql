{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'opportunity_events') }}
),

renamed as (
    select
        event_id,
        sales_person_id,
        customer_id,
        product_id,
        branch_id,
        event_timestamp,
        stage_id,
        expected_amount,
        contract_amount
    from source
)

select * from renamed
