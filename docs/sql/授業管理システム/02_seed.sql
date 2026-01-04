-- SQL Practice Seed Data for 1on1 Learning Curriculum Management System
-- Insert deterministic data for exercises
-- For Microsoft Fabric Warehouse
-- Note: 教師は1人のため、教師テーブルは不要です

-- Students: 生徒データ
INSERT INTO [taitechWarehouseTraning].[learning_management_system].[students](student_id, name, email, enrollment_date) VALUES
  (101, '田中 一郎', 'ichiro.tanaka@example.com', '2024-01-05 09:00:00'),
  (102, '高橋 美咲', 'misaki.takahashi@example.com', '2024-01-10 10:30:00'),
  (103, '伊藤 健太', 'kenta.ito@example.com', '2024-01-15 14:00:00'),
  (104, '山本 さくら', 'sakura.yamamoto@example.com', '2024-01-20 11:15:00'),
  (105, '中村 大輔', 'daisuke.nakamura@example.com', '2024-02-01 09:30:00'),
  (106, '小林 麻衣', 'mai.kobayashi@example.com', '2024-02-05 13:45:00')
GO

-- Courses: コースデータ（月額料金含む）
INSERT INTO [taitechWarehouseTraning].[learning_management_system].[courses](course_id, title, description, monthly_price, created_at) VALUES
  (201, '英会話基礎コース', '日常会話の基礎を学ぶ', 15000.00, '2024-01-01 00:00:00'),
  (202, '英会話中級コース', 'より自然な会話表現を学ぶ', 20000.00, '2024-01-01 00:00:00'),
  (203, 'ビジネス英会話コース', 'ビジネスシーンで使える英語を学ぶ', 18000.00, '2024-01-01 00:00:00'),
  (204, 'TOEIC対策コース', 'TOEICスコアアップを目指す', 16000.00, '2024-01-01 00:00:00'),
  (205, 'プレゼンテーション英会話コース', '英語でのプレゼンテーションスキルを学ぶ', 22000.00, '2024-01-01 00:00:00')
GO

-- Enrollments: 受講登録
INSERT INTO [taitechWarehouseTraning].[learning_management_system].[enrollments](enrollment_id, student_id, course_id, enrolled_at, status) VALUES
  (301, 101, 201, '2024-01-05 09:15:00', 'active'),      -- 田中一郎: 英会話基礎
  (302, 101, 202, '2024-01-20 10:00:00', 'active'),      -- 田中一郎: 英会話中級
  (303, 102, 201, '2024-01-10 10:45:00', 'active'),      -- 高橋美咲: 英会話基礎
  (304, 102, 203, '2024-02-01 11:00:00', 'completed'),  -- 高橋美咲: ビジネス英会話（完了）
  (305, 103, 202, '2024-01-15 14:30:00', 'active'),      -- 伊藤健太: 英会話中級
  (306, 103, 204, '2024-02-10 15:00:00', 'active'),      -- 伊藤健太: TOEIC対策
  (307, 104, 201, '2024-01-20 11:30:00', 'active'),      -- 山本さくら: 英会話基礎
  (308, 105, 203, '2024-02-01 10:00:00', 'active'),      -- 中村大輔: ビジネス英会話
  (309, 105, 205, '2024-02-15 09:00:00', 'cancelled'),   -- 中村大輔: プレゼンテーション英会話（キャンセル）
  (310, 106, 201, '2024-02-05 14:00:00', 'active'),      -- 小林麻衣: 英会話基礎
  (311, 106, 202, '2024-02-20 14:30:00', 'active')      -- 小林麻衣: 英会話中級
GO

-- Lessons: 授業スケジュール（1つの受講登録に対して複数回のレッスン）
INSERT INTO [taitechWarehouseTraning].[learning_management_system].[lessons](lesson_id, enrollment_id, scheduled_at, duration_minutes, status, notes) VALUES
  (401, 301, '2024-01-08 10:00:00', 60, 'completed', '自己紹介と挨拶'),
  (402, 301, '2024-01-15 10:00:00', 60, 'completed', '基本的な文法（現在形）'),
  (403, 301, '2024-01-22 10:00:00', 60, 'completed', '日常会話の練習'),
  (404, 301, '2024-01-29 10:00:00', 60, 'scheduled', 'リスニング練習'),
  (405, 302, '2024-01-25 14:00:00', 90, 'completed', '過去形と過去分詞'),
  (406, 302, '2024-02-01 14:00:00', 90, 'scheduled', '条件文（if文）'),
  (407, 303, '2024-01-12 11:00:00', 60, 'completed', '自己紹介と挨拶'),
  (408, 303, '2024-01-19 11:00:00', 60, 'completed', '基本的な文法（現在形）'),
  (409, 303, '2024-01-26 11:00:00', 60, 'scheduled', '日常会話の練習'),
  (410, 304, '2024-02-05 11:00:00', 90, 'completed', 'ビジネスメールの書き方'),
  (411, 304, '2024-02-12 11:00:00', 90, 'completed', '会議での英語表現'),
  (412, 305, '2024-01-18 15:00:00', 90, 'completed', '過去形と過去分詞'),
  (413, 305, '2024-01-25 15:00:00', 90, 'completed', '現在完了形'),
  (414, 305, '2024-02-01 15:00:00', 90, 'scheduled', '条件文（if文）'),
  (415, 306, '2024-02-12 16:00:00', 60, 'completed', 'TOEICリスニング基礎'),
  (416, 306, '2024-02-19 16:00:00', 60, 'scheduled', 'TOEICリーディング基礎'),
  (417, 307, '2024-01-23 12:00:00', 60, 'completed', '自己紹介と挨拶'),
  (418, 307, '2024-01-30 12:00:00', 60, 'scheduled', '基本的な文法（現在形）'),
  (419, 308, '2024-02-05 13:00:00', 90, 'completed', 'ビジネスメールの書き方'),
  (420, 308, '2024-02-12 13:00:00', 90, 'scheduled', '会議での英語表現'),
  (421, 310, '2024-02-08 15:00:00', 60, 'completed', '自己紹介と挨拶'),
  (422, 310, '2024-02-15 15:00:00', 60, 'scheduled', '基本的な文法（現在形）'),
  (423, 311, '2024-02-22 15:00:00', 90, 'scheduled', '過去形と過去分詞')
GO

-- Video Submissions: ビデオ提出
INSERT INTO [taitechWarehouseTraning].[learning_management_system].[video_submissions](submission_id, lesson_id, title, video_url, submitted_at, status) VALUES
  (501, 401, '自己紹介の練習', 'https://example.com/videos/501', '2024-01-09 18:00:00', 'reviewed'),
  (502, 402, '現在形の会話練習', 'https://example.com/videos/502', '2024-01-16 19:30:00', 'reviewed'),
  (503, 403, '日常会話の実践', 'https://example.com/videos/503', '2024-01-23 20:00:00', 'reviewed'),
  (504, 405, '過去形の会話練習', 'https://example.com/videos/504', '2024-01-26 21:00:00', 'reviewed'),
  (505, 407, '自己紹介の練習', 'https://example.com/videos/505', '2024-01-13 17:00:00', 'reviewed'),
  (506, 408, '現在形の会話練習', 'https://example.com/videos/506', '2024-01-20 18:30:00', 'reviewed'),
  (507, 410, 'ビジネスメールの作成', 'https://example.com/videos/507', '2024-02-06 19:00:00', 'reviewed'),
  (508, 411, '会議での発言練習', 'https://example.com/videos/508', '2024-02-13 20:00:00', 'reviewed'),
  (509, 412, '過去形の会話練習1', 'https://example.com/videos/509', '2024-01-19 21:00:00', 'reviewed'),
  (510, 413, '現在完了形の会話練習', 'https://example.com/videos/510', '2024-01-26 22:00:00', 'reviewed'),
  (511, 415, 'TOEICリスニング問題の復習', 'https://example.com/videos/511', '2024-02-13 19:00:00', 'reviewed'),
  (512, 417, '自己紹介の練習', 'https://example.com/videos/512', '2024-01-24 18:00:00', 'reviewed'),
  (513, 419, 'ビジネスメールの作成', 'https://example.com/videos/513', '2024-02-06 20:00:00', 'reviewed'),
  (514, 421, '自己紹介の練習', 'https://example.com/videos/514', '2024-02-09 17:30:00', 'submitted'),
  (515, 423, '過去形の会話練習', 'https://example.com/videos/515', '2024-02-23 19:00:00', 'submitted')
GO

-- Reviews: レビュー（教師によるビデオ提出へのレビュー）
INSERT INTO [taitechWarehouseTraning].[learning_management_system].[reviews](review_id, submission_id, rating, feedback, reviewed_at) VALUES
  (601, 501, 4, '自己紹介の内容は良くできています。発音をもう少し練習しましょう。', '2024-01-10 09:00:00'),
  (602, 502, 5, '現在形の使い方が完璧です。自然な会話ができています。', '2024-01-17 09:00:00'),
  (603, 503, 4, '日常会話の基本は理解できています。もっと長い文章で話す練習をしましょう。', '2024-01-24 09:00:00'),
  (604, 504, 5, '過去形の理解が深まっています。時制の使い分けが良いです。', '2024-01-27 09:00:00'),
  (605, 505, 3, '自己紹介の基礎は理解できていますが、発音とイントネーションをもう少し練習が必要です。', '2024-01-14 09:00:00'),
  (606, 506, 4, '現在形の使い方が良くなってきました。', '2024-01-21 09:00:00'),
  (607, 507, 5, 'ビジネスメールの書き方が非常に良くできています。', '2024-02-07 09:00:00'),
  (608, 508, 5, '会議での発言が自然です。実践的な表現も良いです。', '2024-02-14 09:00:00'),
  (609, 509, 4, '過去形の基礎は理解できています。', '2024-01-20 09:00:00'),
  (610, 510, 5, '現在完了形の使い方が完璧です。', '2024-01-27 09:00:00'),
  (611, 511, 4, 'リスニングの理解は問題なくできています。次はリーディングを学びましょう。', '2024-02-14 09:00:00'),
  (612, 512, 3, '自己紹介の基礎は理解できていますが、発音をもう少し練習が必要です。', '2024-01-25 09:00:00'),
  (613, 513, 4, 'ビジネスメールの作成が良くできています。', '2024-02-07 09:00:00')
GO

