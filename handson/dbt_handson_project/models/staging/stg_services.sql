{{ config(materialized='view') }}

with source as (
    select * from {{ source('product_system', 'services') }}
),

renamed as (
    select
        service_id,
        service_name
    from source
)

select * from renamed
