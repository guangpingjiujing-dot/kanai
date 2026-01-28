{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'customers') }}
),

renamed as (
    select
        customer_id,
        customer_name,
        account_name,
        phone_number,
        email,
        representative_name,
        channel_id,
        manager_name
    from source
)

select * from renamed
