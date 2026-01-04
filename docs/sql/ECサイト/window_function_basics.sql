-- Window Function Basics
-- Uses tables defined in sql/01_ddl.sql and seeded by sql/02_seed.sql
-- Each example focuses on a single window-function concept with minimal extra clauses.
-- For Microsoft Fabric Warehouse

/* ------------------------------------------------------------------
   1) ROW_NUMBER: 全体に連番を振る
   注文日時が早い順に、ROW_NUMBER() でシンプルな連番を付与。
------------------------------------------------------------------ */
SELECT
  ROW_NUMBER() OVER (ORDER BY order_date) AS seq_no,
  order_id,
  customer_id,
  order_date
FROM [taitechWarehouseTraning].[ecommerce_system].[orders]
ORDER BY seq_no;

/* ------------------------------------------------------------------
   2) ROW_NUMBER + PARTITION: 顧客ごとに連番
   PARTITION BY customer_id を指定すると、顧客単位で番号がリセットされる。
------------------------------------------------------------------ */
SELECT
  customer_id,
  order_id,
  order_date,
  ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY order_date, order_id
  ) AS customer_order_seq
FROM [taitechWarehouseTraning].[ecommerce_system].[orders]
ORDER BY customer_id, customer_order_seq;

/* ------------------------------------------------------------------
   3) RANK: カテゴリ内で価格順位を付ける
   同じ価格の製品は同順位になる（順位に飛び番が生じる）。
------------------------------------------------------------------ */
SELECT
  category_id,
  product_id,
  name,
  price,
  RANK() OVER (
    PARTITION BY category_id
    ORDER BY price DESC
  ) AS price_rank_in_category
FROM [taitechWarehouseTraning].[ecommerce_system].[products]
ORDER BY category_id, price_rank_in_category, product_id;

/* ------------------------------------------------------------------
   4) DENSE_RANK: カテゴリ内で途切れない順位
   価格が同額でも順位の飛び番が発生しないバージョン。
------------------------------------------------------------------ */
SELECT
  category_id,
  product_id,
  name,
  price,
  DENSE_RANK() OVER (
    PARTITION BY category_id
    ORDER BY price DESC
  ) AS dense_price_rank_in_category
FROM [taitechWarehouseTraning].[ecommerce_system].[products]
ORDER BY category_id, dense_price_rank_in_category, product_id;

/* ------------------------------------------------------------------
   5) SUM OVER: 注文内で合計金額を各明細に表示
   集計結果を別クエリにしなくても、同じ行に明細と合計を並べられる。
------------------------------------------------------------------ */
SELECT
  order_id,
  product_id,
  quantity,
  unit_price,
  SUM(quantity * unit_price) OVER (
    PARTITION BY order_id
  ) AS order_total
FROM [taitechWarehouseTraning].[ecommerce_system].[order_items]
ORDER BY order_id, product_id;

/* ------------------------------------------------------------------
   6) AVG + PARTITION: 都市ごとの平均注文回数
   顧客ごとに注文数を数え、同じ都市に属する顧客の平均をウィンドウで計算。
   まず顧客単位の注文数を求めるCTEを作り、そこでウィンドウ関数を適用。
------------------------------------------------------------------ */
WITH customer_order_counts AS (
  SELECT
    c.customer_id,
    c.city,
    COUNT(o.order_id) AS orders_per_customer
  FROM [taitechWarehouseTraning].[ecommerce_system].[customers] c
  LEFT JOIN [taitechWarehouseTraning].[ecommerce_system].[orders] o ON o.customer_id = c.customer_id
  GROUP BY c.customer_id, c.city
)
SELECT
  customer_id,
  city,
  orders_per_customer,
  AVG(orders_per_customer) OVER (
    PARTITION BY city
  ) AS city_avg_orders
FROM customer_order_counts
ORDER BY city, customer_id;


