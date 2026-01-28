{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'branches') }}
),

renamed as (
    select
        branch_id,
        branch_name,
        region_id,
        region_name
    from source
)

select * from renamed
