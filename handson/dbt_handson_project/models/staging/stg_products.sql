{{ config(materialized='view') }}

with source as (
    select * from {{ source('product_system', 'products') }}
),

renamed as (
    select
        product_id,
        product_name,
        category_id,
        category_name,
        service_id,
        
        service_name
    from source
)

select * from renamed
