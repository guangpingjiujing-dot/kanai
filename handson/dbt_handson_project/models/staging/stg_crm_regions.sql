{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'regions') }}
),

renamed as (
    select
        region_id,
        region_name
    from source
)

select * from renamed
