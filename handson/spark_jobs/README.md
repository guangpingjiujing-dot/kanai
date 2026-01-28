# Sparkジョブ

このディレクトリには、ELTパイプラインのExtract（抽出）とLoad（読み込み）を担当するSparkジョブが含まれています。

## ファイル構成

- `fetch_products.py`: 商品管理システムから商品マスターデータを取得し、Fabric Warehouseにロードするジョブ

## 前提条件

- Python 3.8以上
- Apache Spark 3.x
- Microsoft SQL Server JDBC Driver（Fabric Warehouse接続用）

## セットアップ

### 1. 必要なパッケージのインストール

```bash
pip install pyspark
```

### 2. 環境変数の設定

FabricのSparkジョブ（Notebook）で環境変数を使用するには、以下の方法があります：

#### 方法1: Spark設定で環境変数を設定（推奨）

FabricのSparkジョブ設定で、Spark設定に環境変数を追加します：

**Spark設定の追加方法：**
1. FabricのSparkジョブ（Notebook）を開く
2. 設定（Settings）を開く
3. 「Spark設定」セクションで、以下の形式で環境変数を追加：

```
spark.executorEnv.FABRIC_WAREHOUSE_CONNECTION=t5txzdn46dvuniywcpm5owcawm-bxibaf7eydnu5edyx5dy3yentq.datawarehouse.fabric.microsoft.com
spark.executorEnv.FABRIC_WAREHOUSE_DATABASE=taitechWarehouseTraning
spark.executorEnv.FABRIC_WAREHOUSE_SCHEMA=staging
```

**ServicePrincipal認証を使用する場合（dbtと同じ認証方法）：**

```
spark.executorEnv.AZURE_TENANT_ID=your-tenant-id
spark.executorEnv.AZURE_CLIENT_ID=your-client-id
spark.executorEnv.AZURE_CLIENT_SECRET=your-client-secret
```

**注意：**
- ServicePrincipal認証を使用する場合、`AZURE_TENANT_ID`、`AZURE_CLIENT_ID`、`AZURE_CLIENT_SECRET`を設定してください
- これらの設定がない場合、マネージドアイデンティティ認証を試みます
- ローカル環境で実行する場合のみ、ユーザー名/パスワードが必要な場合があります

**注意：**
- `FABRIC_WAREHOUSE_CONNECTION`には、Fabric Warehouseの完全なエンドポイント（例：`t5txzdn46dvuniywcpm5owcawm-bxibaf7eydnu5edyx5dy3yentq.datawarehouse.fabric.microsoft.com`）をそのまま設定できます
- このエンドポイントは、Fabricのワークスペース設定から取得できます

または、コード内でSpark設定を追加：

```python
spark.conf.set("spark.executorEnv.FABRIC_WAREHOUSE_CONNECTION", "t5txzdn46dvuniywcpm5owcawm-bxibaf7eydnu5edyx5dy3yentq.datawarehouse.fabric.microsoft.com")
spark.conf.set("spark.executorEnv.FABRIC_WAREHOUSE_DATABASE", "taitechWarehouseTraning")
spark.conf.set("spark.executorEnv.FABRIC_WAREHOUSE_SCHEMA", "staging")
# 注意: Fabric内で実行する場合、認証は自動処理されるため、USER/PASSWORDは不要
```

#### 方法2: Spark conf経由で設定値を渡す

Spark confから設定値を取得する方法（コード内で使用）：

```python
from pyspark.sql import SparkSession

# Spark confから設定値を取得
warehouse_server = spark.conf.get("spark.custom.warehouse.connection", "default-value")
warehouse_database = spark.conf.get("spark.custom.warehouse.database", "default-value")
```

#### 方法3: ローカル実行時の環境変数設定

ローカル環境で実行する場合（開発・テスト用）：

```bash
# Linux/Mac
export FABRIC_WAREHOUSE_CONNECTION="t5txzdn46dvuniywcpm5owcawm-bxibaf7eydnu5edyx5dy3yentq.datawarehouse.fabric.microsoft.com"
export FABRIC_WAREHOUSE_DATABASE="taitechWarehouseTraning"
export FABRIC_WAREHOUSE_SCHEMA="staging"
# ローカル実行時のみ必要（Fabric内では不要）
# export FABRIC_WAREHOUSE_USER="your-username"
# export FABRIC_WAREHOUSE_PASSWORD="your-password"
```

```powershell
# Windows PowerShell
$env:FABRIC_WAREHOUSE_CONNECTION="t5txzdn46dvuniywcpm5owcawm-bxibaf7eydnu5edyx5dy3yentq.datawarehouse.fabric.microsoft.com"
$env:FABRIC_WAREHOUSE_DATABASE="taitechWarehouseTraning"
$env:FABRIC_WAREHOUSE_SCHEMA="staging"
# ローカル実行時のみ必要（Fabric内では不要）
# $env:FABRIC_WAREHOUSE_USER="your-username"
# $env:FABRIC_WAREHOUSE_PASSWORD="your-password"
```

**Fabric Warehouseエンドポイントの取得方法：**
- Fabricワークスペースの設定から、Warehouseの接続文字列を取得できます
- エンドポイントの形式：`<workspace-id>-<warehouse-id>.datawarehouse.fabric.microsoft.com`
- この完全なエンドポイントを`FABRIC_WAREHOUSE_CONNECTION`に設定してください

**認証について：**
- **Fabric内でSparkジョブを実行する場合**: 認証は自動的に処理されるため、ユーザー名/パスワードは**不要**です
- **ローカル環境で実行する場合**: ユーザー名/パスワードが必要な場合があります（Azure AD認証など）

**その他の注意事項：**
- FabricのSparkジョブでは、方法1（Spark設定）が推奨されます
- `spark.executorEnv.*` 形式で設定した環境変数は、すべてのExecutorで利用可能になります

## 実行方法

### fetch_products.py

商品マスターデータのmockデータを生成し、Fabric Warehouseにロードします。

```bash
spark-submit \
  --packages com.microsoft.sqlserver:mssql-jdbc:12.4.2.jre8 \
  fetch_products.py
```

または、PySparkシェルから実行：

```bash
python fetch_products.py
```

## データソース

### 商品管理システム（fetch_products.py）

- **データソース**: 商品管理システム（mockデータ）
- **出力テーブル**: `staging.products`
- **データ内容**:
  - `product_id`: 商品ID
  - `product_name`: 商品名
  - `category_id`: カテゴリーID
  - `category_name`: カテゴリ名
  - `service_id`: サービスID
  - `service_name`: サービス名

## 注意事項

- このスクリプトは開発・学習用のmockデータを生成します
- 本番環境では、実際のデータソースからデータを取得するように修正してください
- Fabric Warehouseへの接続には、適切な認証情報が必要です
- ServicePrincipal認証を使用する場合は、JDBC接続文字列を調整する必要があります

## トラブルシューティング

### JDBC Driverが見つからない場合

Sparkの実行時にJDBC Driverのパッケージを指定してください：

```bash
spark-submit \
  --packages com.microsoft.sqlserver:mssql-jdbc:12.4.2.jre8 \
  fetch_products.py
```

### 接続エラーが発生する場合

- 環境変数が正しく設定されているか確認してください
- Fabric Warehouseの接続情報（サーバー名、データベース名）が正しいか確認してください
- ファイアウォール設定で、接続元のIPアドレスが許可されているか確認してください
