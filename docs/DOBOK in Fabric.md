## データセキュリティ(Data Security)

- アクセスコントロールのレベル
  - workspace レベル
  - item レベル
    - DWH
    - レイクハウス
  - object レベル
    - テーブル
  - row レベル、column レベル、動的データマスキング
- アクセス付与の対象
  - 個人
  - Microsoft 365 group
  - Entra ID セキュリティグループ
- アクセス付与するロール
  - Admin
    - workspace レベル、 item レベルの両方でフルアクセス権限
  - Member
    - workspace レベルの管理権限が Contributor に比べて多い。
    - item レベルの権限は Contributor と同じ
  - Contributor
    - workspace レベルの管理権限が Member に比べて少ない。
    - item レベルの権限は Member と同じ
  - Viewer
    - workspace レベルの管理権限がない
    - item レベルでも権限が少ない
- アクセス付与の方法
  - UI (手動)
  - API (自動)

## データ統合と相互運用性(Data Integration & Interoperability)

- データ統合の選択肢
  - ingestion
    - data pipeline (≒Data Factory /Apache Airflow /Dagster /Digdag)
      - データオーケストレーションツール
        - Dataflow Gen2
        - Notebook
        - Stored procedures(in Fabric Datawarehouse, Azure SQL)
        - KQL script
        - webhooks
        - Azure functions
        - etc.
    - dataflow
      - 軽量な Power Query ELT ツール
      - NO or Low code
    - Fabric notebook
      - Spark エンジン上のノートブック(PySpark/ SparkSQL)
  - mirroring
    - Fabric 内にレプリカが作成され CDC をつかって同期される
      - snowflake
      - cosmos DB
      - Azure SQL
  - shortcuts
    - External shortcut
      - 外部データソース(AWS S3 や ADLS など)への参照
    - Internal shortcut
      - Fabric 内の item から Fabric 内の item への参照
        - 基本的には DWH から Lakehouse への参照。2 重管理を避けるため

## データストレージとオペレーション

- 以下のいずれも Delta Lake(≒ iceberg)形式のためタイムトラベルやトランザクションに対応
  - Lakehouse
    - 半構造化データや非構造化データと、構造化データの統合
    - spark エンジン(PySpark/ SparkSQL /etc.)と参照のみの T-SQL
    - アクセスコントロールの粒度は低い
  - DWH
    - 構造化データ用
    - 読み書きできる T-SQL → DBT が使える
    - アクセスコントロールの粒度は高い
  - KQL Database
    - リアルタイムなストリームデータ用

https://speakerdeck.com/yuzutas0/20211210?slide=89
https://docs.google.com/spreadsheets/d/1g6Q3vJJbeQICe0-DyfUgn9tPQ6tRfQ5tE_6QVpUlDxQ/edit?gid=0#gid=0

| 英名                                     | 和名                                                  |
| ---------------------------------------- | ----------------------------------------------------- |
| Data Governance                          | データガバナンス                                      |
| Data Architecture                        | データアーキテクチャ                                  |
| Data Modeling & Design                   | データモデリングとデザイン                            |
| Data Storage & Operations                | データストレージとオペレーション                      |
| Data Security                            | データセキュリティ                                    |
| Data Integration & Interoperability      | データ統合と相互運用性                                |
| Documents & Content Management           | ドキュメントとコンテンツ管理                          |
| Reference & Master Data                  | 参照データとマスターデータ                            |
| Data Warehousing & Business Intelligence | データウェアハウジングと <br>ビジネスインテリジェンス |
| Metadata                                 | メタデータ                                            |
| Data Quality                             | データ品質                                            |
