{{ config(materialized='view') }}

with source as (
    select * from {{ source('product_system', 'services') }}
),

renamed as (
    select
        cast(service_id as bigint) as service_id,
        trim(service_name) as service_name
    from source
)

select * from renamed
