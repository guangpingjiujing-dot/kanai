{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'stages') }}
),

renamed as (
    select
        trim(stage_id) as stage_id,
        trim(stage_name) as stage_name,
        cast(stage_order as int) as stage_order
    from source
)

select * from renamed
