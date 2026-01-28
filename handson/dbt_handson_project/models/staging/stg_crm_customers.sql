{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'customers') }}
),

renamed as (
    select
        trim(customer_id) as customer_id,
        trim(customer_name) as customer_name,
        trim(account_name) as account_name,
        trim(phone_number) as phone_number,
        lower(trim(email)) as email,
        trim(representative_name) as representative_name,
        trim(channel_id) as channel_id,
        trim(manager_name) as manager_name
    from source
)

select * from renamed
