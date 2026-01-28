{{ config(materialized='table') }}

with seed_dim_date as (
    select * from {{ ref('dim_date_seed') }}
),

dim_date as (
    select
        cast(date_key as bigint) as date_key,
        cast(date_value as date) as date_value,
        cast(year as int) as year,
        cast(month as int) as month,
        cast(day as int) as day,
        cast(quarter as int) as quarter,
        day_of_week
    from seed_dim_date
)

select * from dim_date
