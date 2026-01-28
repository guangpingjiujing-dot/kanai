{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'regions') }}
),

renamed as (
    select
        trim(region_id) as region_id,
        trim(region_name) as region_name
    from source
)

select * from renamed
