-- Window Function Basics for 1on1 Learning Curriculum Management System
-- Uses tables defined in sql/01_ddl.sql and seeded by sql/02_seed.sql
-- Each example focuses on a single window-function concept with minimal extra clauses.
-- For Microsoft Fabric Warehouse

/* ------------------------------------------------------------------
   1) ROW_NUMBER: 全体に連番を振る
   授業スケジュールが早い順に、ROW_NUMBER() でシンプルな連番を付与。
------------------------------------------------------------------ */
SELECT
  ROW_NUMBER() OVER (ORDER BY scheduled_at) AS seq_no,
  lesson_id,
  enrollment_id,
  scheduled_at
FROM [taitechWarehouseTraning].[learning_management_system].[lessons]
ORDER BY seq_no;

/* ------------------------------------------------------------------
   2) ROW_NUMBER + PARTITION: 受講登録ごとに連番
   PARTITION BY enrollment_id を指定すると、受講登録単位で番号がリセットされる。
------------------------------------------------------------------ */
SELECT
  enrollment_id,
  lesson_id,
  scheduled_at,
  ROW_NUMBER() OVER (
    PARTITION BY enrollment_id
    ORDER BY scheduled_at, lesson_id
  ) AS lesson_seq
FROM [taitechWarehouseTraning].[learning_management_system].[lessons]
ORDER BY enrollment_id, lesson_seq;

/* ------------------------------------------------------------------
   3) RANK: コース内で月額料金順位を付けるｓ
   同じ月額料金のコースは同順位になる（順位に飛び番が生じる）。
------------------------------------------------------------------ */
SELECT
  course_id,
  title,
  monthly_price,
  RANK() OVER (
    ORDER BY monthly_price DESC
  ) AS price_rank
FROM [taitechWarehouseTraning].[learning_management_system].[courses]
ORDER BY price_rank, course_id;

/* ------------------------------------------------------------------
   4) DENSE_RANK: 途切れない順位
   月額料金が同額でも順位の飛び番が発生しないバージョン。
------------------------------------------------------------------ */
SELECT
  course_id,
  title,
  monthly_price,
  DENSE_RANK() OVER (
    ORDER BY monthly_price DESC
  ) AS dense_price_rank
FROM [taitechWarehouseTraning].[learning_management_system].[courses]
ORDER BY dense_price_rank, course_id;

/* ------------------------------------------------------------------
   5) SUM OVER: 生徒ごとの受講コース合計月額料金を各受講登録に表示
   集計結果を別クエリにしなくても、同じ行に受講登録と合計を並べられる。
------------------------------------------------------------------ */
SELECT
  enrollment_id,
  student_id,
  course_id,
  (SELECT monthly_price FROM [taitechWarehouseTraning].[learning_management_system].[courses] WHERE [taitechWarehouseTraning].[learning_management_system].[courses].course_id = [taitechWarehouseTraning].[learning_management_system].[enrollments].course_id) AS course_monthly_price,
  SUM((SELECT monthly_price FROM [taitechWarehouseTraning].[learning_management_system].[courses] WHERE [taitechWarehouseTraning].[learning_management_system].[courses].course_id = [taitechWarehouseTraning].[learning_management_system].[enrollments].course_id)) OVER (
    PARTITION BY student_id
  ) AS student_total_monthly_price
FROM [taitechWarehouseTraning].[learning_management_system].[enrollments]
WHERE status = 'active'
ORDER BY student_id, enrollment_id;

/* ------------------------------------------------------------------
   6) AVG + PARTITION: レビュー評価の平均
   すべてのレビュー評価を平均し、ウィンドウで計算。
------------------------------------------------------------------ */
SELECT
  r.review_id,
  r.rating,
  AVG(r.rating) OVER () AS overall_avg_rating
FROM [taitechWarehouseTraning].[learning_management_system].[reviews] r
ORDER BY r.review_id;

/* ------------------------------------------------------------------
   7) SUM OVER with ORDER BY: 生徒ごとの累積受講月額料金
   受講登録日時順に、累積で受講月額料金を計算。
------------------------------------------------------------------ */
SELECT
  e.enrollment_id,
  e.student_id,
  s.name AS student_name,
  c.title AS course_title,
  c.monthly_price AS course_monthly_price,
  e.enrolled_at,
  SUM(c.monthly_price) OVER (
    PARTITION BY e.student_id
    ORDER BY e.enrolled_at, e.enrollment_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_total_monthly_price
FROM [taitechWarehouseTraning].[learning_management_system].[enrollments] e
JOIN [taitechWarehouseTraning].[learning_management_system].[students] s ON s.student_id = e.student_id
JOIN [taitechWarehouseTraning].[learning_management_system].[courses] c ON c.course_id = e.course_id
WHERE e.status != 'cancelled'
ORDER BY e.student_id, e.enrolled_at;

/* ------------------------------------------------------------------
   8) COUNT OVER: コースごとの受講者数を各受講登録に表示
   コースごとの受講者数をウィンドウ関数で計算。
------------------------------------------------------------------ */
SELECT
  e.enrollment_id,
  e.student_id,
  e.course_id,
  c.title AS course_title,
  COUNT(*) OVER (
    PARTITION BY e.course_id
  ) AS course_enrollment_count
FROM [taitechWarehouseTraning].[learning_management_system].[enrollments] e
JOIN [taitechWarehouseTraning].[learning_management_system].[courses] c ON c.course_id = e.course_id
WHERE e.status = 'active'
ORDER BY e.course_id, e.enrollment_id;

