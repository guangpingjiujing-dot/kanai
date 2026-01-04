-- SQL Practice Schema (DDL) for 1on1 Learning Curriculum Management System
-- For Microsoft Fabric Warehouse

-- Clean up existing objects
IF OBJECT_ID('[taitechWarehouseTraning].[learning_management_system].[reviews]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[learning_management_system].[reviews]
GO

IF OBJECT_ID('[taitechWarehouseTraning].[learning_management_system].[video_submissions]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[learning_management_system].[video_submissions]
GO

IF OBJECT_ID('[taitechWarehouseTraning].[learning_management_system].[lessons]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[learning_management_system].[lessons]
GO

IF OBJECT_ID('[taitechWarehouseTraning].[learning_management_system].[enrollments]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[learning_management_system].[enrollments]
GO

IF OBJECT_ID('[taitechWarehouseTraning].[learning_management_system].[courses]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[learning_management_system].[courses]
GO

IF OBJECT_ID('[taitechWarehouseTraning].[learning_management_system].[students]', 'U') IS NOT NULL
    DROP TABLE [taitechWarehouseTraning].[learning_management_system].[students]
GO

-- Students: 生徒テーブル
CREATE TABLE [taitechWarehouseTraning].[learning_management_system].[students]
(
  student_id INT,
  name VARCHAR(200),
  email VARCHAR(200),
  enrollment_date DATETIME2(6)
)
GO

-- Courses: コーステーブル（月額料金含む）
CREATE TABLE [taitechWarehouseTraning].[learning_management_system].[courses]
(
  course_id INT,
  title VARCHAR(200),
  description VARCHAR(4000),
  monthly_price DECIMAL(10,2), -- 月額料金
  created_at DATETIME2(6)
)
GO

-- Enrollments: 受講登録（生徒とコースの関係）
CREATE TABLE [taitechWarehouseTraning].[learning_management_system].[enrollments]
(
  enrollment_id INT,
  student_id INT,
  course_id INT,
  enrolled_at DATETIME2(6),
  status VARCHAR(20) -- 'active', 'completed', 'cancelled'
)
GO

-- Lessons: 授業スケジュール（1つの受講登録に対して複数回のレッスン）
CREATE TABLE [taitechWarehouseTraning].[learning_management_system].[lessons]
(
  lesson_id INT,
  enrollment_id INT,
  scheduled_at DATETIME2(6),
  duration_minutes INT,
  status VARCHAR(20), -- 'scheduled', 'completed', 'cancelled'
  notes VARCHAR(4000)
)
GO

-- Video Submissions: ビデオ提出
CREATE TABLE [taitechWarehouseTraning].[learning_management_system].[video_submissions]
(
  submission_id INT,
  lesson_id INT,
  title VARCHAR(200),
  video_url VARCHAR(500),
  submitted_at DATETIME2(6),
  status VARCHAR(20) -- 'submitted', 'reviewed', 'revised'
)
GO

-- Reviews: レビュー（教師によるビデオ提出へのレビュー）
CREATE TABLE [taitechWarehouseTraning].[learning_management_system].[reviews]
(
  review_id INT,
  submission_id INT,
  rating INT, -- 1-5の評価
  feedback VARCHAR(4000),
  reviewed_at DATETIME2(6)
)
GO


