{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'channels') }}
),

renamed as (
    select
        channel_id,
        channel_name
    from source
)

select * from renamed
