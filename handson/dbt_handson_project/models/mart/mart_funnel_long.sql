{{ config(materialized='table') }}

with fact_events as (
    select * from {{ ref('fact_opportunity_events') }}
),

dim_date as (
    select * from {{ ref('dim_date') }}
),

dim_stage as (
    select * from {{ ref('dim_stage') }}
),

-- 月次×ステージ別の件数集計
funnel_monthly as (
    select
        concat(cast(d.year as varchar(4)), '-', 
               right('0' + cast(d.month as varchar(2)), 2)) as 年月,
        s.stage_name as ファネルステージ,
        s.stage_order as ステージ順序,
        count(distinct f.event_id) as 件数
    from dim_date as d
    cross join dim_stage as s
    left join fact_events as f
        on d.date_key = f.date_key
        and s.stage_key = f.stage_key
    where d.year >= 2023
    group by d.year, d.month, s.stage_name, s.stage_order
)

select 
    年月,
    ファネルステージ,
    ステージ順序,
    件数
from funnel_monthly
