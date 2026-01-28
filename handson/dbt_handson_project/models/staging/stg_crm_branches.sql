{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'branches') }}
),

renamed as (
    select
        trim(branch_id) as branch_id,
        trim(branch_name) as branch_name,
        trim(region_id) as region_id
    from source
)

select * from renamed
