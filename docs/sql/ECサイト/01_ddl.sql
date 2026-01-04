-- SQL Practice Schema (DDL)
-- For Microsoft Fabric Warehouse

-- Clean up existing objects
IF OBJECT_ID('[taitechWarehouseTraning].[ecommerce_system].[payments]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[ecommerce_system].[payments]
GO

IF OBJECT_ID('[taitechWarehouseTraning].[ecommerce_system].[order_items]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[ecommerce_system].[order_items]
GO

IF OBJECT_ID('[taitechWarehouseTraning].[ecommerce_system].[orders]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[ecommerce_system].[orders]
GO

IF OBJECT_ID('[taitechWarehouseTraning].[ecommerce_system].[products]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[ecommerce_system].[products]
GO

IF OBJECT_ID('[taitechWarehouseTraning].[ecommerce_system].[categories]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[ecommerce_system].[categories]
GO

IF OBJECT_ID('[taitechWarehouseTraning].[ecommerce_system].[customers]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[ecommerce_system].[customers]
GO

-- Master data: product categories
CREATE TABLE [taitechWarehouseTraning].[ecommerce_system].[categories]
(
  category_id INT,
  name VARCHAR(100)
)
GO

-- Customers
CREATE TABLE [taitechWarehouseTraning].[ecommerce_system].[customers]
(
  customer_id INT,
  full_name VARCHAR(200),
  email VARCHAR(200),
  city VARCHAR(100),
  created_at DATETIME2(6)
)
GO

-- Products
CREATE TABLE [taitechWarehouseTraning].[ecommerce_system].[products]
(
  product_id INT,
  name VARCHAR(200),
  category_id INT,
  price DECIMAL(10,2),
  created_at DATETIME2(6)
)
GO

-- Orders
CREATE TABLE [taitechWarehouseTraning].[ecommerce_system].[orders]
(
  order_id INT,
  customer_id INT,
  order_date DATETIME2(6),
  status VARCHAR(20)
)
GO

-- Order line items
CREATE TABLE [taitechWarehouseTraning].[ecommerce_system].[order_items]
(
  order_id INT,
  product_id INT,
  quantity INT,
  unit_price DECIMAL(10,2)
)
GO

-- Payments (some orders may be unpaid / partially paid for practice)
CREATE TABLE [taitechWarehouseTraning].[ecommerce_system].[payments]
(
  payment_id INT,
  order_id INT,
  amount DECIMAL(10,2),
  payment_date DATETIME2(6),
  method VARCHAR(20)
)
GO


