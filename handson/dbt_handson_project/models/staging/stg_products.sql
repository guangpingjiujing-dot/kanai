{{ config(materialized='view') }}

with source as (
    select * from {{ source('product_system', 'products') }}
),

renamed as (
    select
        cast(product_id as bigint) as product_id,
        trim(product_name) as product_name,
        cast(category_id as bigint) as category_id,
        cast(service_id as bigint) as service_id
    from source
)

select * from renamed
