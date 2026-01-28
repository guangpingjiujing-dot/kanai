{{ config(materialized='table') }}

with stg_branches as (
    select * from {{ ref('stg_crm_branches') }}
),

stg_regions as (
    select * from {{ ref('stg_crm_regions') }}
),

dim_branch as (
    select
        -- サロゲートキーを生成
        row_number() over (order by b.branch_id) as branch_key,
        b.branch_id,
        b.branch_name,
        -- 地域キーを生成（regionsテーブルから取得）
        case 
            when b.region_id is not null then 
                dense_rank() over (order by b.region_id)
            else null
        end as region_key,
        r.region_name
    from stg_branches as b
    left join stg_regions as r
        on b.region_id = r.region_id
)

select * from dim_branch
