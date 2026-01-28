{{ config(materialized='view') }}

with source as (
    select * from {{ source('product_system', 'categories') }}
),

renamed as (
    select
        category_id,
        category_name
    from source
)

select * from renamed
