-- CRMシステム（営業システム）サンプルデータ
-- スキーマ: crm_system
-- 正規化されたテーブル構造

-- スキーマ作成
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'crm_system')
BEGIN
    EXEC('CREATE SCHEMA crm_system')
END

-- ============================================
-- 0. 既存テーブルの削除（再作成用）
-- ============================================

-- トランザクションデータテーブルを先に削除（外部キー制約がある場合に備えて）
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'opportunity_events' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    DROP TABLE crm_system.opportunity_events
END

-- マスターデータテーブルを削除
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'customers' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    DROP TABLE crm_system.customers
END

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'branches' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    DROP TABLE crm_system.branches
END

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'sales_persons' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    DROP TABLE crm_system.sales_persons
END

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'stages' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    DROP TABLE crm_system.stages
END

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'channels' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    DROP TABLE crm_system.channels
END

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'regions' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    DROP TABLE crm_system.regions
END

-- ============================================
-- 1. マスターデータテーブル（正規化）
-- ============================================

-- 営業担当者マスター
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'sales_persons' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    CREATE TABLE crm_system.sales_persons (
        sales_person_id VARCHAR(50),
        sales_person_name VARCHAR(100),
        phone_number VARCHAR(20),
        email VARCHAR(100),
        manager_id VARCHAR(50)
    )
END

-- チャネルマスター
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'channels' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    CREATE TABLE crm_system.channels (
        channel_id VARCHAR(50),
        channel_name VARCHAR(100)
    )
END

-- 顧客マスター（正規化：channel_nameを削除、channel_idのみ）
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'customers' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    CREATE TABLE crm_system.customers (
        customer_id VARCHAR(50),
        customer_name VARCHAR(100),
        account_name VARCHAR(100),
        phone_number VARCHAR(20),
        email VARCHAR(100),
        representative_name VARCHAR(100),
        channel_id VARCHAR(50),
        manager_name VARCHAR(100)
    )
END

-- 地域マスター
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'regions' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    CREATE TABLE crm_system.regions (
        region_id VARCHAR(50),
        region_name VARCHAR(100)
    )
END

-- 支店マスター（正規化：region_nameを削除、region_idのみ）
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'branches' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    CREATE TABLE crm_system.branches (
        branch_id VARCHAR(50),
        branch_name VARCHAR(100),
        region_id VARCHAR(50)
    )
END

-- ステージマスター
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'stages' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    CREATE TABLE crm_system.stages (
        stage_id VARCHAR(50),
        stage_name VARCHAR(100),
        stage_order INT
    )
END

-- ============================================
-- 2. トランザクションデータテーブル
-- ============================================

-- 営業機会イベントテーブル
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'opportunity_events' AND schema_id = SCHEMA_ID('crm_system'))
BEGIN
    CREATE TABLE crm_system.opportunity_events (
        event_id VARCHAR(50),
        sales_person_id VARCHAR(50),
        customer_id VARCHAR(50),
        product_id VARCHAR(50),
        branch_id VARCHAR(50),
        event_timestamp DATETIME2(0),
        stage_id VARCHAR(50),
        expected_amount DECIMAL(15, 2),
        contract_amount DECIMAL(15, 2)
    )
END

-- ============================================
-- 3. サンプルデータのINSERT
-- ============================================

-- 営業担当者マスターのサンプルデータ
INSERT INTO crm_system.sales_persons (sales_person_id, sales_person_name, phone_number, email, manager_id) VALUES
('SP001', '山田太郎', '090-1234-5678', 'yamada@example.com', 'SP010'),
('SP002', '佐藤花子', '090-2345-6789', 'sato@example.com', 'SP010'),
('SP003', '鈴木一郎', '090-3456-7890', 'suzuki@example.com', 'SP010'),
('SP004', '田中次郎', '090-4567-8901', 'tanaka@example.com', 'SP011'),
('SP005', '伊藤三郎', '090-5678-9012', 'ito@example.com', 'SP011'),
('SP010', '高橋部長', '090-1111-2222', 'takahashi@example.com', NULL),
('SP011', '中村部長', '090-3333-4444', 'nakamura@example.com', NULL);

-- チャネルマスターのサンプルデータ
INSERT INTO crm_system.channels (channel_id, channel_name) VALUES
('CH001', '直接営業'),
('CH002', '代理店'),
('CH003', 'Web');

-- 顧客マスターのサンプルデータ（正規化：channel_nameを削除）
INSERT INTO crm_system.customers (customer_id, customer_name, account_name, phone_number, email, representative_name, channel_id, manager_name) VALUES
('CUST001', '株式会社テック', 'テック', '03-1234-5678', 'info@tech.co.jp', '山本代表', 'CH001', '山田太郎'),
('CUST002', 'デジタルソリューション株式会社', 'デジタルソリューション', '03-2345-6789', 'contact@digital.co.jp', '田村代表', 'CH001', '佐藤花子'),
('CUST003', 'イノベーション株式会社', 'イノベーション', '03-3456-7890', 'info@innovation.co.jp', '佐々木代表', 'CH002', '鈴木一郎'),
('CUST004', 'グローバル商事株式会社', 'グローバル商事', '03-4567-8901', 'sales@global.co.jp', '渡辺代表', 'CH001', '田中次郎'),
('CUST005', 'システム開発株式会社', 'システム開発', '03-5678-9012', 'info@system.co.jp', '中島代表', 'CH003', '伊藤三郎'),
('CUST006', 'データ分析株式会社', 'データ分析', '03-6789-0123', 'contact@data.co.jp', '小林代表', 'CH001', '山田太郎'),
('CUST007', 'クラウドサービス株式会社', 'クラウドサービス', '03-7890-1234', 'info@cloud.co.jp', '加藤代表', 'CH002', '佐藤花子');

-- 地域マスターのサンプルデータ
INSERT INTO crm_system.regions (region_id, region_name) VALUES
('REG001', '関東'),
('REG002', '関西'),
('REG003', '中部'),
('REG004', '九州'),
('REG005', '北海道');

-- 支店マスターのサンプルデータ（正規化：region_nameを削除）
INSERT INTO crm_system.branches (branch_id, branch_name, region_id) VALUES
('BR001', '東京本社', 'REG001'),
('BR002', '大阪支店', 'REG002'),
('BR003', '名古屋支店', 'REG003'),
('BR004', '福岡支店', 'REG004'),
('BR005', '札幌支店', 'REG005');

-- ステージマスターのサンプルデータ
INSERT INTO crm_system.stages (stage_id, stage_name, stage_order) VALUES
('STG001', 'リード獲得', 1),
('STG002', '見積作成', 2),
('STG003', '提案', 3),
('STG004', '商談', 4),
('STG005', '契約', 5),
('STG006', '失注', 99);

-- 営業機会イベントのサンプルデータ
INSERT INTO crm_system.opportunity_events (event_id, sales_person_id, customer_id, product_id, branch_id, event_timestamp, stage_id, expected_amount, contract_amount) VALUES
('EVT001', 'SP001', 'CUST001', 'PROD001', 'BR001', '2024-01-15 10:00:00', 'STG001', 5000000.00, NULL),
('EVT002', 'SP001', 'CUST001', 'PROD001', 'BR001', '2024-01-20 14:30:00', 'STG002', 5000000.00, NULL),
('EVT003', 'SP001', 'CUST001', 'PROD001', 'BR001', '2024-02-01 09:15:00', 'STG003', 5000000.00, NULL),
('EVT004', 'SP001', 'CUST001', 'PROD001', 'BR001', '2024-02-15 11:00:00', 'STG004', 5000000.00, NULL),
('EVT005', 'SP001', 'CUST001', 'PROD001', 'BR001', '2024-03-01 15:30:00', 'STG005', 5000000.00, 4800000.00),
('EVT006', 'SP002', 'CUST002', 'PROD002', 'BR001', '2024-01-20 10:30:00', 'STG001', 3000000.00, NULL),
('EVT007', 'SP002', 'CUST002', 'PROD002', 'BR001', '2024-02-05 13:00:00', 'STG002', 3000000.00, NULL),
('EVT008', 'SP002', 'CUST002', 'PROD002', 'BR001', '2024-02-20 16:00:00', 'STG003', 3000000.00, NULL),
('EVT009', 'SP002', 'CUST002', 'PROD002', 'BR001', '2024-03-10 10:00:00', 'STG006', 3000000.00, NULL),
('EVT010', 'SP003', 'CUST003', 'PROD003', 'BR002', '2024-02-01 09:00:00', 'STG001', 8000000.00, NULL),
('EVT011', 'SP003', 'CUST003', 'PROD003', 'BR002', '2024-02-15 14:00:00', 'STG002', 8000000.00, NULL),
('EVT012', 'SP003', 'CUST003', 'PROD003', 'BR002', '2024-03-01 11:30:00', 'STG003', 8000000.00, NULL),
('EVT013', 'SP004', 'CUST004', 'PROD001', 'BR003', '2024-02-10 10:00:00', 'STG001', 4500000.00, NULL),
('EVT014', 'SP004', 'CUST004', 'PROD001', 'BR003', '2024-02-25 15:00:00', 'STG002', 4500000.00, NULL),
('EVT015', 'SP005', 'CUST005', 'PROD002', 'BR001', '2024-03-05 09:30:00', 'STG001', 2500000.00, NULL),
('EVT016', 'SP001', 'CUST006', 'PROD003', 'BR001', '2024-03-10 10:00:00', 'STG001', 6000000.00, NULL),
('EVT017', 'SP002', 'CUST007', 'PROD001', 'BR002', '2024-03-12 14:00:00', 'STG001', 3500000.00, NULL),
('EVT018', 'SP003', 'CUST001', 'PROD002', 'BR001', '2024-03-15 11:00:00', 'STG002', 4000000.00, NULL);
