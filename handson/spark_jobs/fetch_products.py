"""
商品管理システムから商品マスターデータを取得し、Fabric WarehouseにロードするSparkジョブ

このスクリプトは、商品管理システムのmockデータを生成し、
Fabric Warehouseのproductsテーブルにロードします。
"""

from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, LongType
from pyspark.sql.functions import col, lit
import random


def get_config(spark):
    """
    Spark設定から接続情報を取得
    
    FabricのSparkジョブでは、Spark設定で環境変数を設定します。
    設定方法: spark.executorEnv.FABRIC_WAREHOUSE_CONNECTION=value
    
    Args:
        spark: SparkSessionオブジェクト
    
    Returns:
        dict: 接続情報の辞書
    """
    def get_value(spark_key):
        """Spark設定から値を取得"""
        # spark.executorEnv.* から取得
        executor_env_value = spark.conf.get(f"spark.executorEnv.{spark_key}", None)
        if executor_env_value:
            return executor_env_value
        
        # spark.conf.* から取得
        conf_value = spark.conf.get(spark_key, None)
        if conf_value:
            return conf_value
        
        # 値が見つからない場合はエラー
        raise ValueError(f"必須設定値が見つかりません: spark.executorEnv.{spark_key}")
    
    config = {
        "server": get_value("FABRIC_WAREHOUSE_CONNECTION"),
        "database": get_value("FABRIC_WAREHOUSE_DATABASE"),
        "schema": get_value("FABRIC_WAREHOUSE_SCHEMA"),
        # ServicePrincipal認証用の設定
        "tenant_id": get_value("AZURE_TENANT_ID"),
        "client_id": get_value("AZURE_CLIENT_ID"),
        "client_secret": get_value("AZURE_CLIENT_SECRET"),
    }
    
    return config


def create_mock_products_data(spark):
    """
    商品マスターのmockデータを生成
    
    Returns:
        DataFrame: 商品マスターデータのDataFrame
    """
    # mockデータの定義
    # カテゴリーとサービスの組み合わせ
    categories = [
        (1, "クラウドサービス"),
        (2, "セキュリティ"),
        (3, "データ分析"),
        (4, "開発ツール"),
        (5, "インフラストラクチャ"),
    ]
    
    services = [
        (1, "基本プラン"),
        (2, "スタンダードプラン"),
        (3, "プレミアムプラン"),
        (4, "エンタープライズプラン"),
    ]
    
    # 商品名のテンプレート
    product_templates = [
        "{category} - {service}",
        "{category}ソリューション - {service}",
        "{category}パッケージ - {service}",
    ]
    
    # mockデータを生成
    products_data = []
    product_id = 1
    
    for category_id, category_name in categories:
        for service_id, service_name in services:
            # 各カテゴリー×サービスの組み合わせに対して1-3個の商品を生成
            num_products = random.randint(1, 3)
            for _ in range(num_products):
                template = random.choice(product_templates)
                product_name = template.format(
                    category=category_name,
                    service=service_name
                )
                
                products_data.append({
                    "product_id": product_id,
                    "product_name": product_name,
                    "category_id": category_id,
                    "category_name": category_name,
                    "service_id": service_id,
                    "service_name": service_name,
                })
                product_id += 1
    
    # DataFrameのスキーマを定義
    schema = StructType([
        StructField("product_id", LongType(), False),
        StructField("product_name", StringType(), False),
        StructField("category_id", LongType(), True),
        StructField("category_name", StringType(), True),
        StructField("service_id", LongType(), True),
        StructField("service_name", StringType(), True),
    ])
    
    # DataFrameを作成
    products_df = spark.createDataFrame(
        [tuple(row.values()) for row in products_data],
        schema=schema
    )
    
    return products_df


def load_to_fabric_warehouse(spark, df, table_name, schema_name, config):
    """
    DataFrameをFabric Warehouseにロード
    
    Args:
        spark: SparkSessionオブジェクト
        df: ロードするDataFrame
        table_name: テーブル名
        schema_name: スキーマ名
        config: 接続情報の辞書
    """
    # JDBC接続URLと認証設定
    # ServicePrincipal認証を使用（dbtのprofiles.ymlと同じ方法）
    jdbc_url = f"jdbc:sqlserver://{config['server']}:1433;database={config['database']};authentication=ActiveDirectoryServicePrincipal;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.fabric.microsoft.com;tenantId={config['tenant_id']}"
    connection_properties = {
        "driver": "com.microsoft.sqlserver.jdbc.SQLServerDriver",
        "user": config["client_id"],  # client_idをuserとして使用
        "password": config["client_secret"],  # client_secretをpasswordとして使用
    }
    
    # テーブル名
    full_table_name = f"{schema_name}.{table_name}"
    
    # Fabric WarehouseではNVARCHARがサポートされていないため、
    # VARCHARを使用する
    # カラム名とデータ型のマッピング（Fabric Warehouse対応）
    create_table_column_types = (
        "product_id BIGINT, "
        "product_name VARCHAR(200), "
        "category_id BIGINT, "
        "category_name VARCHAR(100), "
        "service_id BIGINT, "
        "service_name VARCHAR(200)"
    )
    
    # DataFrameをFabric Warehouseに書き込み
    # mode("overwrite")により、既存のテーブルは上書きされます
    # SQL Server/Fabric Warehouseでは、テーブル名にスキーマを含める必要があります
    df.write \
        .mode("overwrite") \
        .option("createTableColumnTypes", create_table_column_types) \
        .jdbc(
            url=jdbc_url,
            table=f"{schema_name}.{table_name}",  # スキーマ名を含めたテーブル名を指定
            properties=connection_properties
        )
    
    print(f"✓ {full_table_name} に {df.count()} 件のデータをロードしました")


def main():
    """
    メイン処理
    """
    # SparkSessionを作成
    spark = SparkSession.builder \
        .appName("FetchProducts") \
        .config("spark.jars.packages", "com.microsoft.sqlserver:mssql-jdbc:12.4.2.jre8") \
        .getOrCreate()
    
    try:
        # 接続情報を取得（Spark設定から）
        config = get_config(spark)
        
        print("=" * 60)
        print("商品マスターデータの取得とロードを開始します")
        print("=" * 60)
        
        # mockデータを生成
        print("\n1. mockデータを生成中...")
        products_df = create_mock_products_data(spark)
        print(f"   ✓ {products_df.count()} 件の商品データを生成しました")
        
        # データのサンプルを表示
        print("\n2. 生成されたデータのサンプル:")
        products_df.show(10, truncate=False)
        
        # Fabric Warehouseにロード
        print(f"\n3. Fabric Warehouse ({config['database']}.{config['schema']}) にロード中...")
        load_to_fabric_warehouse(
            spark,
            products_df,
            table_name="products",
            schema_name=config["schema"],
            config=config
        )
        
        print("\n" + "=" * 60)
        print("処理が正常に完了しました")
        print("=" * 60)
        
    except Exception as e:
        print(f"\nエラーが発生しました: {e}")
        raise
    
    finally:
        spark.stop()


if __name__ == "__main__":
    main()
