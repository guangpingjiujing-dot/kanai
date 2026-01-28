{{ config(materialized='table') }}

with fact_events as (
    select * from {{ ref('fact_opportunity_events') }}
),

dim_stage as (
    select * from {{ ref('dim_stage') }}
),

-- fact_eventsから日付情報を取得
fact_with_date as (
    select
        f.*,
        year(f.event_timestamp) as year,
        month(f.event_timestamp) as month
    from fact_events as f
),

-- 月次×ステージ別の件数集計（fact_eventsから直接集計）
funnel_monthly as (
    select
        concat(cast(f.year as varchar(4)), '-', 
               right('0' + cast(f.month as varchar(2)), 2)) as 年月,
        s.stage_name as ファネルステージ,
        s.stage_order as ステージ順序,
        count(distinct f.event_id) as 件数
    from fact_with_date as f
    inner join dim_stage as s
        on f.stage_key = s.stage_key
    where f.year >= 2023
    group by f.year, f.month, s.stage_name, s.stage_order
)

select 
    年月,
    ファネルステージ,
    ステージ順序,
    件数
from funnel_monthly
