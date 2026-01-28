{{ config(materialized='table') }}

with stg_opportunity_events as (
    select * from {{ ref('stg_crm_opportunity_events') }}
),

dim_sales_person as (
    select * from {{ ref('dim_sales_person') }}
),

dim_customer as (
    select * from {{ ref('dim_customer') }}
),

dim_product as (
    select * from {{ ref('dim_product') }}
),

dim_branch as (
    select * from {{ ref('dim_branch') }}
),

dim_stage as (
    select * from {{ ref('dim_stage') }}
),

dim_date as (
    select * from {{ ref('dim_date') }}
),

fact_opportunity_events as (
    select
        -- イベントIDをそのまま使用（主キー）
        stg.event_id,
        
        -- 各ディメンションのサロゲートキーを結合
        sp.sales_person_key,
        c.customer_key,
        p.product_key,
        b.branch_key,
        stg_dim.stage_key,
        
        -- 日付キーを生成（YYYYMMDD形式）
        cast(format(stg.event_timestamp, 'yyyyMMdd') as bigint) as date_key,
        
        -- ファクトメジャー
        stg.event_timestamp,
        stg.expected_amount,
        stg.contract_amount
        
    from stg_opportunity_events as stg
    left join dim_sales_person as sp
        on stg.sales_person_id = sp.sales_person_id
    left join dim_customer as c
        on stg.customer_id = c.customer_id
    left join dim_product as p
        -- CRMシステムのproduct_id（'PROD001'形式）から数値部分を抽出して結合
        -- 例: 'PROD001' → 1, 'PROD002' → 2
        on cast(
            case 
                when stg.product_id like 'PROD%' 
                then substring(stg.product_id, 5, len(stg.product_id))
                else stg.product_id
            end as bigint
        ) = p.product_id
    left join dim_branch as b
        on stg.branch_id = b.branch_id
    left join dim_stage as stg_dim
        on stg.stage_id = stg_dim.stage_id
    left join dim_date as d
        on cast(format(stg.event_timestamp, 'yyyyMMdd') as bigint) = d.date_key
)

select * from fact_opportunity_events
