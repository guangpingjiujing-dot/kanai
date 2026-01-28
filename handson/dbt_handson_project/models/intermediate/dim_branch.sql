{{ config(materialized='table') }}

with stg_branches as (
    select * from {{ ref('stg_crm_branches') }}
),

dim_branch as (
    select
        -- サロゲートキーを生成
        row_number() over (order by branch_id) as branch_key,
        branch_id,
        branch_name,
        -- 地域キーは簡易的にROW_NUMBERで生成
        case 
            when region_id is not null then 
                dense_rank() over (order by region_id)
            else null
        end as region_key,
        region_name
    from stg_branches
)

select * from dim_branch
