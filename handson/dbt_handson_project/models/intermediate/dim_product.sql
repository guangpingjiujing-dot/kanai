{{ config(materialized='table') }}

with stg_products as (
    select * from {{ ref('stg_products') }}
),

stg_categories as (
    select * from {{ ref('stg_categories') }}
),

stg_services as (
    select * from {{ ref('stg_services') }}
),

dim_product as (
    select
        -- サロゲートキーを生成
        row_number() over (order by p.product_id) as product_key,
        -- product_idはbigint型（fetch_products.pyで生成されるデータ）
        cast(p.product_id as bigint) as product_id,
        p.product_name,
        -- category_idとservice_idもbigint型として扱う
        cast(p.category_id as bigint) as category_key,
        c.category_name,
        cast(p.service_id as bigint) as service_key,
        s.service_name
    from stg_products as p
    left join stg_categories as c
        on p.category_id = c.category_id
    left join stg_services as s
        on p.service_id = s.service_id
)

select * from dim_product
