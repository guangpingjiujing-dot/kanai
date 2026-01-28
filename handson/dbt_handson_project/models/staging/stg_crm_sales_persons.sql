{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'sales_persons') }}
),

renamed as (
    select
        sales_person_id,
        sales_person_name,
        phone_number,
        email,
        manager_id
    from source
)

select * from renamed
