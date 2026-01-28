{{ config(materialized='table') }}

with stg_customers as (
    select * from {{ ref('stg_crm_customers') }}
),

dim_customer as (
    select
        -- サロゲートキーを生成
        row_number() over (order by customer_id) as customer_key,
        customer_id,
        customer_name,
        account_name,
        phone_number,
        email,
        representative_name,
        -- チャネルキーは簡易的にROW_NUMBERで生成（実際は別テーブルから取得する場合もある）
        case 
            when channel_id is not null then 
                dense_rank() over (order by channel_id)
            else null
        end as channel_key,
        channel_name,
        manager_name
    from stg_customers
)

select * from dim_customer
