{{ config(materialized='view') }}

with source as (
    select * from {{ source('crm_system', 'channels') }}
),

renamed as (
    select
        trim(channel_id) as channel_id,
        trim(channel_name) as channel_name
    from source
)

select * from renamed
