{{ config(materialized='table') }}

with stg_customers as (
    select * from {{ ref('stg_crm_customers') }}
),

stg_channels as (
    select * from {{ ref('stg_crm_channels') }}
),

dim_customer as (
    select
        -- サロゲートキーを生成
        row_number() over (order by c.customer_id) as customer_key,
        c.customer_id,
        c.customer_name,
        c.account_name,
        c.phone_number,
        c.email,
        c.representative_name,
        -- チャネルキーを生成（channelsテーブルから取得）
        case 
            when c.channel_id is not null then 
                dense_rank() over (order by c.channel_id)
            else null
        end as channel_key,
        ch.channel_name,
        c.manager_name
    from stg_customers as c
    left join stg_channels as ch
        on c.channel_id = ch.channel_id
)

select * from dim_customer
