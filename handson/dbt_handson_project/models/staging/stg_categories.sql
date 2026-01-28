{{ config(materialized='view') }}

with source as (
    select * from {{ source('product_system', 'categories') }}
),

renamed as (
    select
        cast(category_id as bigint) as category_id,
        trim(category_name) as category_name
    from source
)

select * from renamed
