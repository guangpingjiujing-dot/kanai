# dbt 機能ガイド

対象のDWHは **Microsoft Fabric Warehouse** です。

---

## マテリアライズ（Materializations）

### 概要

マテリアライズは、dbtがモデルをどのようにDWHに保存するかを制御する機能です。**Fabric Warehouseでは`table`がデフォルト**ですが、用途に応じて変更できます。

**重要**: Fabric Warehouseでは、ネストされたCTE（Common Table Expressions）がサポートされていません。複数のネストされたCTEを使用するモデルは、コンパイルまたは実行時に失敗する可能性があります。

### 種類

#### 1. view

- **特徴**: ビューとして作成される
- **メリット**: ストレージを消費しない、常に最新データを参照
- **デメリット**: クエリのたびに計算が発生するため、重いクエリには不向き
- **用途**: 軽量な変換、頻繁に変更されるモデル
- **制約**: ネストされたCTEは使用できません

```sql
-- models/staging/stg_orders.sql
{{ config(materialized='view') }}

select
    order_id,
    customer_id,
    order_date,
    total_amount
from {{ source('ecommerce_system', 'orders') }}
```

#### 2. table

- **特徴**: 物理テーブルとして作成される
- **メリット**: クエリパフォーマンスが良い
- **デメリット**: ストレージを消費する、更新には`dbt run`が必要
- **用途**: 重い集計処理、頻繁に参照されるマート層

```sql
-- models/marts/mart_daily_sales.sql
{{ config(materialized='table') }}

select
    order_date,
    count(*) as order_count,
    sum(total_amount) as total_sales
from {{ ref('stg_orders') }}
group by order_date
```

#### 3. incremental

- **特徴**: 初回は全件、2回目以降は差分のみ追加
- **メリット**: 実行時間が短縮される、大規模データに適している
- **デメリット**: 設定が複雑、重複チェックが必要
- **用途**: 大規模なトランザクションデータ、日次更新されるファクトテーブル

```sql
-- models/marts/fct_orders_incremental.sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge'
) }}

select
    order_id,
    customer_id,
    order_date,
    total_amount,
    updated_at
from {{ source('ecommerce_system', 'orders') }}

{% if is_incremental() %}
    -- 2回目以降の実行時のみ実行される
    where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
```

**Fabricでの注意点**: Fabric Warehouseでは`merge`戦略が推奨されます。`unique_key`を必ず指定してください。

#### 5. table_clone（Fabric固有）

- **特徴**: Fabricのクローニング機能を使用して既存テーブルの物理コピーを作成
- **メリット**: 高速なゼロコピー複製、バージョニングやブランチングに便利
- **デメリット**: ソーステーブルがターゲットウェアハウスに存在する必要がある
- **用途**: テスト、ロールバック、スナップショット的なワークフロー

```sql
-- models/marts/mart_orders_clone.sql
{{ config(materialized='table_clone', clone_from='staging.stg_orders') }}

select * from {{ ref('stg_orders') }}
```

**注意点**:
- ソーステーブルはターゲットウェアハウスに存在している必要があります
- クローニング時点のスキーマとデータ状態が保持されます

### プロジェクトレベルでの設定

`dbt_project.yml`で一括設定も可能です：

```yaml
models:
  dbt_project:
    staging:
      +materialized: view
    marts:
      +materialized: table
```


---

## インクリメンタルモデル（Incremental Models）

### 概要

インクリメンタルモデルは、初回実行時は全件処理し、2回目以降は新規・変更されたデータのみを処理するモデルです。大規模データの処理時間を大幅に短縮できます。

### 基本的な使い方

```sql
-- models/marts/fct_orders_incremental.sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge'
) }}

select
    order_id,
    customer_id,
    order_date,
    total_amount,
    updated_at
from {{ source('ecommerce_system', 'orders') }}

{% if is_incremental() %}
    where updated_at > (
        select max(updated_at) 
        from {{ this }}
    )
{% endif %}
```

### 重要な設定項目

#### unique_key

- **必須**: レコードを一意に識別するキー
- **用途**: 重複チェック、マージ時の更新判定

#### incremental_strategy

Fabric Warehouseで使用可能な戦略（**デフォルトは`merge`**、v1.9.7以降）：

- **`merge`**（デフォルト・推奨）: MERGE文を使用して更新・挿入
- **`append`**: 既存データセットに新しいレコードを追加
- **`delete+insert`**: 削除してから挿入（パフォーマンスは劣る）
- **`microbatch`**: イベントタイムスタンプカラムを使用して時間間隔ごとに処理

```sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge'
) }}
```

**append戦略の例**:

```sql
{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}
select * from new_data
```

**microbatch戦略の例**:

```sql
{{ config(
    materialized='incremental',
    incremental_strategy='microbatch',
    event_time='event_timestamp',
    batch_size='1 day'
) }}
select * from raw_events
```

**microbatch戦略の注意点**:
- `event_time`は有効なタイムスタンプカラムである必要があります
- dbtは各バッチを独立して処理し、大規模な時系列データセットの効率的なインクリメンタル更新を可能にします
- `unique_key`を指定しない場合、dbt-fabricはデフォルトで`append`を使用します

#### on_schema_change

スキーマ変更時の動作：

- **`ignore`**: 変更を無視（デフォルト）
- **`fail`**: エラーで停止
- **`append_new_columns`**: 新しいカラムを追加
- **`sync_all_columns`**: カラムの追加・削除を同期

### 実践例：日次更新のファクトテーブル

```sql
-- models/marts/fct_daily_orders.sql
{{ config(
    materialized='incremental',
    unique_key=['order_date', 'customer_id'],
    incremental_strategy='merge',
    partition_by={'field': 'order_date', 'data_type': 'date'}
) }}

with daily_orders as (
    select
        cast(order_date as date) as order_date,
        customer_id,
        count(*) as order_count,
        sum(total_amount) as total_sales,
        max(updated_at) as last_updated
    from {{ ref('stg_orders') }}
    group by 
        cast(order_date as date),
        customer_id
)

select * from daily_orders

{% if is_incremental() %}
    where order_date > (
        select max(order_date) 
        from {{ this }}
    )
{% endif %}
```

### 注意点

1. **タイムスタンプカラムの存在**: インクリメンタル更新には、更新日時を表すカラムが必要です
2. **データの整合性**: `unique_key`が正しく設定されていないと重複が発生します
3. **初回実行時間**: 初回は全件処理のため時間がかかります
4. **手動リセット**: 問題が発生した場合は`--full-refresh`フラグで全件再処理できます

```bash
dbt run --select fct_orders_incremental --full-refresh
```

---

## スナップショット（Snapshots）

### 概要

スナップショットは、時点でのデータの状態を記録し、変更履歴を追跡する機能です。SCD（Slowly Changing Dimension）タイプ2の実装に使用されます。

### 基本的な使い方

#### 1. スナップショットファイルの作成

`snapshots/snap_customers.sql`を作成：

```sql
{% snapshot snap_customers %}

{{
    config(
      target_schema='snapshots',
      unique_key='customer_id',
      strategy='check',
      check_cols=['email', 'city'],
      updated_at='updated_at'
    )
}}

select
    customer_id,
    full_name,
    email,
    city,
    created_at,
    updated_at
from {{ source('ecommerce_system', 'customers') }}

{% endsnapshot %}
```

#### 2. スナップショットの実行

```bash
dbt snapshot
```

### 戦略の種類

#### check戦略

指定したカラムの値が変更された場合に新しいレコードを作成：

```sql
{{
    config(
      unique_key='customer_id',
      strategy='check',
      check_cols=['email', 'city']
    )
}}
```

#### timestamp戦略

`updated_at`カラムの値が前回実行時より新しい場合に新しいレコードを作成：

```sql
{{
    config(
      unique_key='customer_id',
      strategy='timestamp',
      updated_at='updated_at'
    )
}}
```

### スナップショットテーブルの構造

スナップショット実行後、以下のカラムが自動的に追加されます：

- `dbt_scd_id`: スナップショットレコードの一意識別子
- `dbt_updated_at`: スナップショットが作成された日時
- `dbt_valid_from`: このレコードが有効になった日時
- `dbt_valid_to`: このレコードが無効になった日時（現在有効な場合はNULL）

### 実践例：商品マスタの変更履歴追跡

```sql
-- snapshots/snap_products.sql
{% snapshot snap_products %}

{{
    config(
      target_schema='snapshots',
      unique_key='product_id',
      strategy='check',
      check_cols=['product_name', 'price', 'category_id'],
      updated_at='updated_at'
    )
}}

select
    product_id,
    product_name,
    price,
    category_id,
    created_at,
    updated_at
from {{ source('ecommerce_system', 'products') }}

{% endsnapshot %}
```

### スナップショットデータの活用

現在有効なレコードのみを取得：

```sql
-- models/marts/dim_products_current.sql
select
    product_id,
    product_name,
    price,
    category_id
from {{ ref('snap_products') }}
where dbt_valid_to is null
```

特定時点のデータを取得：

```sql
-- 2024-01-01時点の商品情報
select *
from {{ ref('snap_products') }}
where dbt_valid_from <= '2024-01-01'
  and (dbt_valid_to > '2024-01-01' or dbt_valid_to is null)
```

### 注意点

1. **ストレージ消費**: 変更のたびにレコードが追加されるため、ストレージ使用量が増加します
2. **実行時間**: 全件チェックのため、大規模データでは時間がかかります
3. **Fabricでの制約**: 
   - `target_schema`を明示的に指定する必要があります
   - **重要**: ソーステーブルのカラムに制約（`NOT NULL`など）がある場合、エラーが発生します。スナップショットを使用する前に、ソーステーブルの制約を確認してください

---

## マクロ（Macros）

### 概要

マクロは、再利用可能なSQLコードのテンプレートです。Jinja2テンプレートを使用して、動的なSQLを生成できます。

### 基本的な使い方

#### 1. マクロファイルの作成

`macros/generate_surrogate_key.sql`を作成：

```sql
{% macro generate_surrogate_key(field_list) %}
    {%- set fields = field_list | join(', ') -%}
    hash(concat(
        {%- for field in field_list %}
            coalesce(cast({{ field }} as varchar), '')
            {%- if not loop.last %}, '-' ,{% endif %}
        {%- endfor %}
    ))
{% endmacro %}
```

#### 2. マクロの使用

```sql
-- models/marts/fct_orders.sql
select
    {{ generate_surrogate_key(['order_id', 'order_date']) }} as order_key,
    order_id,
    order_date,
    customer_id,
    total_amount
from {{ ref('stg_orders') }}
```

### よく使われるマクロの例

#### 日付フォーマット変換

```sql
-- macros/date_format.sql
{% macro date_format(date_column, format='YYYY-MM-DD') %}
    format({{ date_column }}, '{{ format }}')
{% endmacro %}
```

使用例：

```sql
select
    {{ date_format('order_date', 'YYYY-MM') }} as order_month
from {{ ref('stg_orders') }}
```

#### 条件付きWHERE句

```sql
-- macros/where_filter.sql
{% macro where_filter(column, value, operator='=') %}
    {% if value is not none %}
        and {{ column }} {{ operator }} {{ value }}
    {% endif %}
{% endmacro %}
```

使用例：

```sql
select *
from {{ ref('stg_orders') }}
where 1=1
    {{ where_filter('customer_id', var('target_customer_id')) }}
    {{ where_filter('order_date', var('start_date'), '>=') }}
```

#### カラムリストの生成

```sql
-- macros/get_column_list.sql
{% macro get_column_list(table_ref, exclude_columns=[]) %}
    {%- set columns = adapter.get_columns_in_relation(table_ref) -%}
    {%- for col in columns -%}
        {%- if col.name not in exclude_columns -%}
            {{ col.name }}{% if not loop.last %}, {% endif %}
        {%- endif -%}
    {%- endfor -%}
{% endmacro %}
```

使用例：

```sql
select
    {{ get_column_list(ref('stg_orders'), ['internal_id']) }}
from {{ ref('stg_orders') }}
```

### 組み込みマクロ

dbtには多くの組み込みマクロが用意されています：

- `ref()`: モデル参照
- `source()`: ソース参照
- `config()`: 設定
- `var()`: 変数参照
- `this`: 現在のモデル参照
- `is_incremental()`: インクリメンタル実行判定

### マクロのデバッグ

マクロの出力を確認するには、`dbt compile`を使用：

```bash
dbt compile --select your_model
```

コンパイル後のSQLは`target/compiled/`ディレクトリに保存されます。

---

## 変数（Variables）

### 概要

変数は、プロジェクト全体で使用できる設定値です。環境ごとに異なる値を設定したり、動的なクエリを作成したりする際に便利です。

### 変数の定義

#### 1. dbt_project.ymlで定義

```yaml
# dbt_project.yml
name: 'dbt_project'
version: '1.0.0'

vars:
  start_date: '2024-01-01'
  end_date: '2024-12-31'
  target_schema: 'analytics'
  min_order_amount: 1000
```

#### 2. コマンドラインで定義

```bash
dbt run --vars '{"start_date": "2024-06-01", "min_order_amount": 5000}'
```

#### 3. profiles.ymlで定義

```yaml
# profiles.yml
dbt_project:
  target: dev
  outputs:
    dev:
      type: fabric
      # ... その他の設定
      vars:
        environment: development
```

### 変数の使用

#### モデル内での使用

```sql
-- models/marts/mart_orders.sql
select
    order_id,
    customer_id,
    order_date,
    total_amount
from {{ ref('stg_orders') }}
where order_date >= '{{ var("start_date") }}'
  and order_date <= '{{ var("end_date") }}'
  and total_amount >= {{ var("min_order_amount") }}
```

#### マクロ内での使用

```sql
-- macros/filter_by_date.sql
{% macro filter_by_date(date_column) %}
    where {{ date_column }} >= '{{ var("start_date") }}'
      and {{ date_column }} <= '{{ var("end_date") }}'
{% endmacro %}
```

### デフォルト値の設定

変数が定義されていない場合のデフォルト値を設定：

```sql
select *
from {{ ref('stg_orders') }}
where order_date >= '{{ var("start_date", "2020-01-01") }}'
```

### 条件分岐での使用

```sql
-- models/marts/mart_orders.sql
select
    order_id,
    customer_id,
    order_date,
    total_amount
from {{ ref('stg_orders') }}

{% if var('include_test_orders', false) %}
    -- テスト注文も含める
{% else %}
    where customer_id not like 'TEST%'
{% endif %}
```

### 実践例：環境別設定

#### dbt_project.yml

```yaml
vars:
  # 開発環境用のデフォルト値
  start_date: '2024-01-01'
  end_date: '2024-12-31'
  schema_suffix: '_dev'
```

#### 本番環境での実行

```bash
dbt run --vars '{"start_date": "2020-01-01", "schema_suffix": "_prod"}'
```

### 注意点

1. **型の扱い**: 文字列は`'{{ var("key") }}'`、数値は`{{ var("key") }}`のように引用符の有無で区別します
2. **変数の優先順位**: コマンドライン > profiles.yml > dbt_project.yml
3. **必須変数のチェック**: マクロ内で`var()`の第2引数にデフォルト値を設定しないと、未定義時にエラーになります

---

## フック（Hooks）

### 概要

フックは、dbtの実行前後や特定のタイミングで自動実行されるSQLです。データ品質チェック、ログ記録、クリーンアップなどに使用します。

### フックの種類

#### 1. pre-hook / post-hook（モデルレベル）

特定のモデルの実行前後にSQLを実行：

```sql
-- models/marts/mart_orders.sql
{{ config(
    pre_hook="
        -- 実行前のログ記録
        insert into dbt_audit.log_table 
        values ('mart_orders', 'start', getdate())
    ",
    post_hook="
        -- 実行後のログ記録
        insert into dbt_audit.log_table 
        values ('mart_orders', 'end', getdate())
    "
) }}

select
    order_id,
    customer_id,
    order_date,
    total_amount
from {{ ref('stg_orders') }}
```

#### 2. on-run-start / on-run-end（プロジェクトレベル）

`dbt run`の開始時と終了時に実行：

```yaml
# dbt_project.yml
on-run-start:
  - "create schema if not exists {{ target.schema }}"
  - "create table if not exists dbt_audit.run_log (model_name varchar, status varchar, run_time datetime)"

on-run-end:
  - "insert into dbt_audit.run_log values ('{{ invocation_id }}', 'completed', getdate())"
```

### 実践例

#### データ品質チェック（pre-hook）

```sql
-- models/marts/mart_orders.sql
{{ config(
    pre_hook="
        -- ソースデータの件数チェック
        if (select count(*) from {{ ref('stg_orders') }}) = 0
        begin
            raiserror('Source data is empty', 16, 1)
        end
    "
) }}

select * from {{ ref('stg_orders') }}
```

#### 実行時間の記録（post-hook）

```sql
-- models/marts/mart_orders.sql
{{ config(
    post_hook="
        insert into dbt_audit.model_execution_log 
        (model_name, execution_time, record_count)
        select 
            'mart_orders',
            datediff(second, @start_time, getdate()),
            count(*)
        from {{ this }}
    "
) }}
```

#### 統計情報の更新（post-hook）

```sql
-- models/marts/mart_orders.sql
{{ config(
    post_hook="
        -- テーブルの統計情報を更新（Fabricではインデックスはサポートされていないため）
        update statistics {{ this }}
    "
) }}
```

**注意**: Fabric Warehouseではインデックスはサポートされていません。インデックス作成のpost-hookは無視されます。

### マクロを使ったフック

複雑なロジックはマクロに分離：

```sql
-- macros/log_execution.sql
{% macro log_execution(model_name, action) %}
    insert into dbt_audit.execution_log 
    (model_name, action, timestamp)
    values ('{{ model_name }}', '{{ action }}', getdate())
{% endmacro %}
```

```sql
-- models/marts/mart_orders.sql
{{ config(
    pre_hook="{{ log_execution('mart_orders', 'start') }}",
    post_hook="{{ log_execution('mart_orders', 'end') }}"
) }}
```

### 注意点

1. **エラーハンドリング**: pre-hookでエラーが発生すると、モデルの実行がスキップされます
2. **実行順序**: on-run-start → pre-hook → モデル実行 → post-hook → on-run-end
3. **Fabricでの制約**: Fabric Warehouseでは、一部のシステム関数が制限される場合があります

---

## テスト（Tests）- Unit Tests

### 概要

dbtのUnit Testsは、モデルのロジックが正しく動作するかを検証する機能です。データテスト（not null、uniqueなど）とは異なり、**変換ロジックそのもの**をテストします。

### Unit Testsの基本構造

#### 1. テストファイルの作成

`tests/unit/test_mart_orders.yml`を作成：

```yaml
unit_tests:
  - name: test_calculate_total_amount
    model: mart_orders
    given:
      - input: ref('stg_orders')
        rows:
          - {order_id: 1, customer_id: 100, order_date: '2024-01-01', quantity: 2, unit_price: 500}
          - {order_id: 2, customer_id: 101, order_date: '2024-01-02', quantity: 3, unit_price: 1000}
    expect:
      rows:
        - {order_id: 1, total_amount: 1000}
        - {order_id: 2, total_amount: 3000}
```

#### 2. テスト対象のモデル

```sql
-- models/marts/mart_orders.sql
select
    order_id,
    customer_id,
    order_date,
    quantity * unit_price as total_amount
from {{ ref('stg_orders') }}
```

#### 3. テストの実行

```bash
dbt test --select test_calculate_total_amount
```

### 実践例

#### 例1: 日付フォーマット変換のテスト

```yaml
unit_tests:
  - name: test_date_formatting
    model: mart_daily_sales
    given:
      - input: ref('stg_orders')
        rows:
          - {order_id: 1, order_date: '2024-01-15 10:30:00', total_amount: 1000}
    expect:
      rows:
        - {order_date_formatted: '2024-01', total_amount: 1000}
```

モデル：

```sql
-- models/marts/mart_daily_sales.sql
select
    format(order_date, 'yyyy-MM') as order_date_formatted,
    sum(total_amount) as total_amount
from {{ ref('stg_orders') }}
group by format(order_date, 'yyyy-MM')
```

#### 例2: 条件分岐のテスト

```yaml
unit_tests:
  - name: test_customer_segment
    model: mart_customers
    given:
      - input: ref('stg_orders')
        rows:
          - {customer_id: 100, total_amount: 50000}   # プレミアム
          - {customer_id: 101, total_amount: 5000}     # レギュラー
          - {customer_id: 102, total_amount: 500}      # ライト
    expect:
      rows:
        - {customer_id: 100, segment: 'premium'}
        - {customer_id: 101, segment: 'regular'}
        - {customer_id: 102, segment: 'light'}
```

モデル：

```sql
-- models/marts/mart_customers.sql
select
    customer_id,
    case
        when total_amount >= 10000 then 'premium'
        when total_amount >= 1000 then 'regular'
        else 'light'
    end as segment
from {{ ref('stg_orders') }}
```

#### 例3: 集計ロジックのテスト

```yaml
unit_tests:
  - name: test_daily_aggregation
    model: mart_daily_sales
    given:
      - input: ref('stg_orders')
        rows:
          - {order_id: 1, order_date: '2024-01-01', total_amount: 1000}
          - {order_id: 2, order_date: '2024-01-01', total_amount: 2000}
          - {order_id: 3, order_date: '2024-01-02', total_amount: 1500}
    expect:
      rows:
        - {order_date: '2024-01-01', daily_total: 3000, order_count: 2}
        - {order_date: '2024-01-02', daily_total: 1500, order_count: 1}
```

モデル：

```sql
-- models/marts/mart_daily_sales.sql
select
    cast(order_date as date) as order_date,
    sum(total_amount) as daily_total,
    count(*) as order_count
from {{ ref('stg_orders') }}
group by cast(order_date as date)
```

### 複数の入力ソースを扱う

```yaml
unit_tests:
  - name: test_join_logic
    model: mart_order_details
    given:
      - input: ref('stg_orders')
        rows:
          - {order_id: 1, customer_id: 100}
      - input: ref('stg_customers')
        rows:
          - {customer_id: 100, customer_name: 'John Doe'}
    expect:
      rows:
        - {order_id: 1, customer_name: 'John Doe'}
```

### 注意点

1. **dbtバージョン**: Unit Testsはdbt 1.5以降で利用可能です
2. **Fabricでの対応**: Fabric Warehouseでは、Unit Testsの一部機能が制限される場合があります
3. **テストデータの管理**: テストデータは実際のデータとは分離して管理します
4. **実行時間**: Unit Testsは実際のDWHに接続せずに実行されるため、高速です

---

## タグ（Tags）

### 概要

タグは、モデルやテストにラベルを付けて、グループ化や選択実行を行う機能です。プロジェクトの規模が大きくなると、特定のモデルだけを実行したい場面が増えます。

### タグの付け方

#### 1. モデルファイル内で設定

```sql
-- models/staging/stg_orders.sql
{{ config(tags=['staging', 'orders', 'daily']) }}

select * from {{ source('ecommerce_system', 'orders') }}
```

#### 2. schema.ymlで設定

```yaml
# models/staging/schema.yml
models:
  - name: stg_orders
    description: "注文データのステージング"
    tags:
      - staging
      - orders
      - daily
```

#### 3. dbt_project.ymlで一括設定

```yaml
# dbt_project.yml
models:
  dbt_project:
    staging:
      +tags: ['staging']
    marts:
      +tags: ['marts']
```

### タグを使った選択実行

#### 特定のタグを持つモデルのみ実行

```bash
# stagingタグを持つモデルのみ実行
dbt run --select tag:staging

# ordersタグを持つモデルのみ実行
dbt run --select tag:orders

# 複数のタグを指定（AND条件）
dbt run --select tag:staging tag:daily

# 複数のタグを指定（OR条件）
dbt run --select tag:staging,tag:marts
```

#### タグを使った除外

```bash
# stagingタグを持つモデルを除外
dbt run --exclude tag:staging
```

### 実践例：レイヤー別のタグ付け

```yaml
# dbt_project.yml
models:
  dbt_project:
    staging:
      +tags: ['layer:staging']
    intermediate:
      +tags: ['layer:intermediate']
    marts:
      +tags: ['layer:marts']
```

```bash
# ステージング層のみ実行
dbt run --select tag:layer:staging

# マート層のみ実行
dbt run --select tag:layer:marts
```

### 実践例：更新頻度別のタグ付け

```sql
-- models/marts/mart_daily_sales.sql
{{ config(tags=['update:daily', 'marts']) }}
```

```sql
-- models/marts/mart_monthly_sales.sql
{{ config(tags=['update:monthly', 'marts']) }}
```

```bash
# 日次更新モデルのみ実行
dbt run --select tag:update:daily

# 月次更新モデルのみ実行
dbt run --select tag:update:monthly
```

### タグとテストの組み合わせ

```bash
# 特定のタグを持つモデルのテストのみ実行
dbt test --select tag:staging

# タグを持つモデルとそのテストを実行
dbt run --select tag:marts && dbt test --select tag:marts
```

### 注意点

1. **タグの命名規則**: プロジェクト全体で統一した命名規則を決めると管理しやすくなります
2. **タグの数**: タグを付けすぎると管理が複雑になるため、必要最小限に留めます
3. **大文字小文字**: タグは大文字小文字を区別します

---

## エクスポージャー（Exposures）

### 概要

エクスポージャーは、dbtモデルがどのように外部ツール（BIツール、ダッシュボードなど）で使用されているかを記録する機能です。モデルの影響範囲を可視化できます。

### エクスポージャーの定義

#### schema.ymlで定義

```yaml
# models/marts/schema.yml
exposures:
  - name: daily_sales_dashboard
    type: dashboard
    owner:
      name: "データ分析チーム"
      email: "analytics@example.com"
    depends_on:
      - ref('mart_daily_sales')
      - ref('mart_customer_sales')
    description: "日次売上ダッシュボード"
    url: "https://bi.example.com/dashboards/daily-sales"
    maturity: high

  - name: customer_segmentation_report
    type: notebook
    owner:
      name: "データサイエンティスト"
      email: "ds@example.com"
    depends_on:
      - ref('mart_customers')
    description: "顧客セグメント分析レポート"
    url: "https://notebook.example.com/reports/customer-seg"
    maturity: medium
```

### エクスポージャーの種類

#### dashboard

BIツールのダッシュボード：

```yaml
exposures:
  - name: sales_dashboard
    type: dashboard
    depends_on:
      - ref('mart_daily_sales')
```

#### notebook

Jupyter NotebookやDatabricks Notebook：

```yaml
exposures:
  - name: ml_training_notebook
    type: notebook
    depends_on:
      - ref('mart_customers')
```

#### application

アプリケーション：

```yaml
exposures:
  - name: recommendation_api
    type: application
    depends_on:
      - ref('mart_product_features')
```

#### analysis

分析レポート：

```yaml
exposures:
  - name: quarterly_report
    type: analysis
    depends_on:
      - ref('mart_quarterly_sales')
```

### エクスポージャーの確認

#### ドキュメント生成で確認

```bash
dbt docs generate
dbt docs serve
```

ブラウザで開くと、エクスポージャーがモデルの依存関係図に表示されます。

#### コマンドラインで確認

```bash
# エクスポージャーの一覧を表示
dbt list --resource-type exposure

# 特定のエクスポージャーに依存するモデルを表示
dbt list --select exposure:+daily_sales_dashboard
```

### 実践例：完全なエクスポージャー定義

```yaml
exposures:
  - name: executive_dashboard
    type: dashboard
    owner:
      name: "経営企画部"
      email: "strategy@example.com"
    depends_on:
      - ref('mart_daily_sales')
      - ref('mart_customer_sales')
      - ref('mart_product_sales')
    description: |
      経営層向けの統合ダッシュボード。
      日次・顧客別・商品別の売上を可視化。
    url: "https://powerbi.example.com/dashboards/executive"
    maturity: high
    tags:
      - executive
      - high-priority

  - name: customer_churn_analysis
    type: notebook
    owner:
      name: "データサイエンスチーム"
      email: "ds@example.com"
    depends_on:
      - ref('mart_customers')
      - ref('mart_orders')
    description: "顧客離脱分析用のJupyter Notebook"
    url: "https://databricks.example.com/notebooks/churn-analysis"
    maturity: medium
```

### エクスポージャーとLineage

エクスポージャーを定義すると、`dbt docs`で以下の情報が可視化されます：

1. **モデル → エクスポージャー**: どのモデルがどのツールで使われているか
2. **エクスポージャー → モデル**: エクスポージャーが依存しているモデル
3. **影響範囲**: モデルを変更した場合の影響を受けるエクスポージャー

### 注意点

1. **メンテナンス**: エクスポージャー情報は定期的に更新する必要があります
2. **URLの管理**: URLが変更された場合は、エクスポージャー定義も更新します
3. **Fabricでの対応**: Fabric Warehouseでは、エクスポージャー機能は標準でサポートされています

---

## パッケージ（Packages）

### 概要

パッケージは、他のdbtプロジェクトで作成されたマクロやモデルを再利用する機能です。コミュニティが提供するパッケージを利用することで、開発効率が向上します。

### パッケージのインストール

#### 1. packages.ymlの作成

`packages.yml`を作成：

```yaml
# packages.yml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1

  - package: calogica/dbt_expectations
    version: 0.10.1

  - package: dbt-labs/codegen
    version: 0.12.1
```

#### 2. パッケージのインストール

```bash
dbt deps
```

インストール後、`dbt_packages/`ディレクトリにパッケージがダウンロードされます。

### よく使われるパッケージ

#### tsql-utils（Fabric推奨）

**重要**: `dbt_utils`パッケージはFabric Warehouseではサポートされていません。代わりに`tsql-utils`パッケージを使用してください。

```yaml
packages:
  - git: "https://github.com/dbt-msft/tsql-utils.git"
    revision: main
```

`tsql-utils`は、Fabric Warehouse用に最適化されたマクロ集を提供します。dbt-fabricアダプターには一部のdbt-utilsマクロが含まれていますが、より多くの機能が必要な場合は`tsql-utils`パッケージをインストールしてください。

#### dbt_expectations

Great Expectations風のテスト：

```yaml
packages:
  - package: calogica/dbt_expectations
    version: 0.10.1
```

**注意**: すべてのパッケージがFabric Warehouseに対応しているわけではありません。使用前に確認が必要です。

#### dbt_expectations

Great Expectations風のテスト：

```yaml
packages:
  - package: calogica/dbt_expectations
    version: 0.10.1
```

使用例：

```yaml
models:
  - name: stg_orders
    tests:
      - dbt_expectations.expect_table_row_count_to_equal_other_table:
          compare_model: source('ecommerce_system', 'orders')
```

---

## オペレーション（Operations）

### 概要

オペレーションは、`dbt run`や`dbt test`以外のカスタム処理を実行する機能です。マクロを直接実行したり、データベース操作を行ったりする際に使用します。

### 基本的な使い方

#### 1. マクロの作成

```sql
-- macros/cleanup_old_data.sql
{% macro cleanup_old_data(days_to_keep=90) %}
    delete from {{ target.schema }}.staging_log
    where created_at < dateadd(day, -{{ days_to_keep }}, getdate())
{% endmacro %}
```

#### 2. オペレーションの実行

```bash
dbt run-operation cleanup_old_data --args '{days_to_keep: 30}'
```

### 実践例

#### 例1: データベースのクリーンアップ

```sql
-- macros/cleanup_tables.sql
{% macro cleanup_tables(schema_name, table_pattern='%') %}
    declare @sql nvarchar(max) = ''
    declare @table_name nvarchar(255)
    
    declare table_cursor cursor for
    select name
    from sys.tables
    where schema_id = schema_id('{{ schema_name }}')
      and name like '{{ table_pattern }}'
    
    open table_cursor
    fetch next from table_cursor into @table_name
    
    while @@fetch_status = 0
    begin
        set @sql = 'drop table if exists [' + '{{ schema_name }}' + '].[' + @table_name + ']'
        exec sp_executesql @sql
        fetch next from table_cursor into @table_name
    end
    
    close table_cursor
    deallocate table_cursor
{% endmacro %}
```

実行：

```bash
dbt run-operation cleanup_tables --args '{schema_name: staging, table_pattern: stg_%}'
```

#### 例2: データのバックアップ

```sql
-- macros/backup_table.sql
{% macro backup_table(table_ref, backup_suffix='_backup') %}
    create table {{ table_ref }}{{ backup_suffix }} as
    select * from {{ table_ref }}
{% endmacro %}
```

実行：

```bash
dbt run-operation backup_table --args '{table_ref: ref("mart_orders"), backup_suffix: "_20240101"}'
```
---

## リスティング機能（List）

### 概要

`dbt list`コマンドは、プロジェクト内のモデル、テスト、ソース、スナップショットなどのリソースを一覧表示する機能です。実行せずに情報を確認できるため、デバッグや確認作業に便利です。

### 基本的な使い方

#### すべてのリソースを表示

```bash
dbt list
```

出力例：

```
ecommerce_system.orders
ecommerce_system.customers
staging.stg_orders
staging.stg_customers
intermediate.int_order_summary
marts.mart_daily_sales
marts.mart_customer_sales
```

#### モデルのみ表示

```bash
dbt list --resource-type model
```

#### テストのみ表示

```bash
dbt list --resource-type test
```

#### ソースのみ表示

```bash
dbt list --resource-type source
```

### 選択オプション

#### タグでフィルタ

```bash
# 特定のタグを持つモデルを表示
dbt list --select tag:staging

# 複数のタグを指定
dbt list --select tag:staging,tag:daily
```

#### 依存関係を含める

```bash
# 特定のモデルとその依存モデルを表示
dbt list --select stg_orders+

# 特定のモデルとその上流モデルを表示
dbt list --select +mart_daily_sales

# 特定のモデルとその上下流モデルを表示
dbt list --select +mart_daily_sales+
```

---

## Analyses（分析クエリ）

### 概要

`analyses`フォルダは、探索的な分析クエリやアドホックな分析を保存するためのディレクトリです。**これらのクエリはモデルとして実行されません**が、dbtのマクロ（`ref()`、`source()`など）を使用できるため、モデル化する前の調査や検証に便利です。

### 特徴

- **実行されない**: `dbt run`では実行されません
- **コンパイル可能**: `dbt compile`でコンパイルされ、SQLを確認できます
- **マクロ使用可能**: `ref()`、`source()`、`var()`などのdbtマクロが使用できます
- **バージョン管理**: Gitで管理できるため、分析の履歴を追跡できます

### 基本的な使い方

#### 1. analysesフォルダにSQLファイルを作成

```sql
-- analyses/explore_customer_behavior.sql
-- 顧客の行動パターンを探索するためのクエリ

select
    c.customer_id,
    c.full_name,
    count(o.order_id) as order_count,
    sum(o.total_amount) as total_spent,
    avg(o.total_amount) as avg_order_value
from {{ ref('stg_customers') }} c
left join {{ ref('stg_orders') }} o
    on c.customer_id = o.customer_id
group by c.customer_id, c.full_name
having count(o.order_id) > 5
order by total_spent desc
```

#### 2. クエリのコンパイル

```bash
# すべてのanalysesをコンパイル
dbt compile

# 特定のanalysisをコンパイル
dbt compile --select analyses/explore_customer_behavior.sql
```

コンパイル後、`target/compiled/analyses/`ディレクトリにコンパイルされたSQLが保存されます。

#### 3. コンパイルされたSQLの確認と実行

コンパイルされたSQLを確認して、手動でDWHに実行します：

```bash
# コンパイルされたSQLを確認
cat target/compiled/analyses/explore_customer_behavior.sql
```

---

### 参考
- [dbt-fabric-configs](https://docs.getdbt.com/reference/resource-configs/fabric-configs)
- [dbt snapshot から学ぶ Slowly Changing Dimension](https://data.gunosy.io/entry/dbt_snapshot_and_scd)