{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'stages') }}
),

renamed as (
    select
        stage_id,
        stage_name,
        stage_order
    from source
)

select * from renamed
