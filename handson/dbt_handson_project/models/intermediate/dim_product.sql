{{ config(materialized='table') }}

with stg_products as (
    select * from {{ ref('stg_products') }}
),

dim_product as (
    select
        -- サロゲートキーを生成
        row_number() over (order by product_id) as product_key,
        product_id,
        product_name,
        category_id as category_key,
        category_name,
        service_id as service_key,
        service_name
    from stg_products
)

select * from dim_product
