# dbt Handson Project

このプロジェクトは、CRMシステムのデータをスタースキーマに変換するdbtプロジェクトです。

## プロジェクト構成

### データソース
- **CRMシステム（営業システム）**: `crm_system`スキーマ
  - `sales_persons`: 営業担当者マスター
  - `customers`: 顧客マスター
  - `branches`: 支店マスター
  - `stages`: ステージマスター
  - `opportunity_events`: 営業機会イベント（トランザクションデータ）

- **商品管理システム**: `source_products`スキーマ
  - `products`: 商品マスター（`fetch_products.py`で生成されるデータ）

### モデル構造

#### Staging層 (`models/staging/`)
- `stg_crm_sales_persons`: 営業担当者データのステージング
- `stg_crm_customers`: 顧客データのステージング
- `stg_crm_branches`: 支店データのステージング
- `stg_crm_stages`: ステージデータのステージング
- `stg_crm_opportunity_events`: 営業機会イベントデータのステージング
- `stg_products`: 商品データのステージング（商品管理システムから）

#### Intermediate層 (`models/intermediate/`)
- **ディメンションテーブル**:
  - `dim_sales_person`: 営業担当者ディメンション
  - `dim_customer`: 顧客ディメンション
  - `dim_branch`: 支店ディメンション
  - `dim_stage`: ステージディメンション
  - `dim_product`: 商品ディメンション（商品管理システムから取得）
  - `dim_date`: 日付ディメンション（seedから生成）

- **ファクトテーブル**:
  - `fact_opportunity_events`: 営業イベントファクトテーブル

#### Mart層 (`models/mart/`)
- **分析用マートテーブル**:
  - `mart_yoy_comparison`: 前年比比較マートテーブル（月次）
  - `mart_funnel_long`: ファネル分析マートテーブル（ロング形式）

## セットアップ

### 1. 環境変数の設定

以下の環境変数を設定してください：
- `FABRIC_WAREHOUSE_CONNECTION`: Fabric Warehouseの接続文字列
- `AZURE_TENANT_ID`: AzureテナントID
- `AZURE_CLIENT_ID`: AzureクライアントID
- `AZURE_CLIENT_SECRET`: Azureクライアントシークレット

### 2. dim_dateのseedデータ生成

`seeds/dim_date_seed.csv`は2020年から2030年までのサンプルデータのみが含まれています。
完全なデータを生成するには、以下のコマンドを実行してください：

```bash
cd seeds
python generate_dim_date.py
```

### 3. dbtの実行

```bash
# seedデータのロード
dbt seed

# モデルの実行
dbt run

# テストの実行
dbt test

# ドキュメントの生成
dbt docs generate
dbt docs serve
```

## 注意事項

- **商品管理システムのスキーマ名**: `sources.yml`では`source_products`スキーマを想定しています。`fetch_products.py`を実行する際は、`FABRIC_WAREHOUSE_SCHEMA`環境変数を`source_products`に設定してください。
- **商品データのロード**: 商品データは`fetch_products.py`を実行してFabric Warehouseにロードする必要があります。このスクリプトを実行すると、`source_products.products`テーブルに商品マスターデータが作成されます。
- `dim_date_seed.csv`は2020年から2030年までのサンプルデータのみが含まれています。必要に応じて`generate_dim_date.py`を実行して完全なデータを生成してください。
