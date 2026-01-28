{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'sales_persons') }}
),

renamed as (
    select
        trim(sales_person_id) as sales_person_id,
        trim(sales_person_name) as sales_person_name,
        trim(phone_number) as phone_number,
        lower(trim(email)) as email,
        trim(manager_id) as manager_id
    from source
)

select * from renamed
