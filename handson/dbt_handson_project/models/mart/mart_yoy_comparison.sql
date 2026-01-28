{{ config(materialized='table') }}

with fact_events as (
    select * from {{ ref('fact_opportunity_events') }}
),

dim_date as (
    select * from {{ ref('dim_date') }}
),

-- 月次集計
monthly_summary as (
    select
        d.year,
        d.month,
        concat(cast(d.year as varchar(4)), '-', 
               right('0' + cast(d.month as varchar(2)), 2)) as 年月,
        count(distinct f.event_id) as 商談獲得数,
        sum(f.expected_amount) as 予想契約金額,
        count(distinct case when f.contract_amount is not null then f.event_id end) as 契約獲得数,
        sum(f.contract_amount) as 契約金額
    from dim_date as d
    left join fact_events as f
        on d.date_key = f.date_key
    where d.year >= 2023
    group by d.year, d.month
),

-- 前年比計算
yoy_comparison as (
    select
        cy.年月,
        cy.year as 当年,
        cy.year - 1 as 前年,
        cy.商談獲得数 as 商談獲得数_当年,
        py.商談獲得数 as 商談獲得数_前年,
        case 
            when py.商談獲得数 > 0 
            then round((cy.商談獲得数 - py.商談獲得数) * 100.0 / py.商談獲得数, 1)
            else null
        end as 商談獲得数_前年比,
        isnull(cy.予想契約金額, 0) as 予想契約金額_当年,
        isnull(py.予想契約金額, 0) as 予想契約金額_前年,
        case 
            when py.予想契約金額 > 0 
            then round((isnull(cy.予想契約金額, 0) - py.予想契約金額) * 100.0 / py.予想契約金額, 1)
            else null
        end as 予想契約金額_前年比,
        cy.契約獲得数 as 契約獲得数_当年,
        py.契約獲得数 as 契約獲得数_前年,
        case 
            when py.契約獲得数 > 0 
            then round((cy.契約獲得数 - py.契約獲得数) * 100.0 / py.契約獲得数, 1)
            else null
        end as 契約獲得数_前年比,
        isnull(cy.契約金額, 0) as 契約金額_当年,
        isnull(py.契約金額, 0) as 契約金額_前年,
        case 
            when py.契約金額 > 0 
            then round((isnull(cy.契約金額, 0) - py.契約金額) * 100.0 / py.契約金額, 1)
            else null
        end as 契約金額_前年比
    from monthly_summary as cy
    left join monthly_summary as py
        on cy.year = py.year + 1
        and cy.month = py.month
    where cy.year >= 2024
)

select 
    年月,
    当年,
    前年,
    商談獲得数_当年,
    商談獲得数_前年,
    商談獲得数_前年比,
    予想契約金額_当年,
    予想契約金額_前年,
    予想契約金額_前年比,
    契約獲得数_当年,
    契約獲得数_前年,
    契約獲得数_前年比,
    契約金額_当年,
    契約金額_前年,
    契約金額_前年比
from yoy_comparison
