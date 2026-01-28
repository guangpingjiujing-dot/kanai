{{ config(materialized='table') }}

with stg_stages as (
    select * from {{ ref('stg_crm_stages') }}
),

dim_stage as (
    select
        -- サロゲートキーを生成
        row_number() over (order by stage_order, stage_id) as stage_key,
        stage_id,
        stage_name,
        stage_order
    from stg_stages
)

select * from dim_stage
