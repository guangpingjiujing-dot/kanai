{{ config(materialized='table') }}

with stg_sales_persons as (
    select * from {{ ref('stg_crm_sales_persons') }}
),

dim_sales_person as (
    select
        -- サロゲートキーを生成（ROW_NUMBERを使用）
        row_number() over (order by sales_person_id) as sales_person_key,
        sales_person_id,
        sales_person_name,
        phone_number,
        email,
        manager_id
    from stg_sales_persons
)

select * from dim_sales_person
