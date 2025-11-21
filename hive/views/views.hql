-- =====================================================================
-- School Big Data Project - Dashboard Views
-- These views are meant for the UI/Backend team to query easily
-- without needing to understand the star schema structure.
-- =====================================================================

USE school_clean;

-- =====================================================================
-- 1. Student Grade History (per-student timeline)
-- =====================================================================

CREATE OR REPLACE VIEW vw_student_grade_history AS
SELECT
    ds.student_id,
    ds.first_name AS student_first_name,
    ds.last_name  AS student_last_name,
    dc.class_name,
    dsem.semester_name,
    dsem.year,
    dd.date_value AS attendance_date,
    fa.grade
FROM fact_attendance fa
JOIN dim_students  ds   ON fa.student_key  = ds.student_key
JOIN dim_classes   dc   ON fa.class_key    = dc.class_key
JOIN dim_semesters dsem ON fa.semester_key = dsem.semester_key
JOIN dim_date      dd   ON fa.date_key     = dd.date_key
ORDER BY ds.student_id, dd.date_value;


-- =====================================================================
-- 2. Average Grade by Class
-- Good for Class Performance charts
-- =====================================================================

CREATE OR REPLACE VIEW vw_avg_grade_by_class AS
SELECT
    dc.class_id,
    dc.class_name,
    dsem.semester_name,
    dsem.year,
    AVG(fa.grade) AS avg_grade,
    COUNT(*)      AS num_records
FROM fact_attendance fa
JOIN dim_classes   dc   ON fa.class_key    = dc.class_key
JOIN dim_semesters dsem ON fa.semester_key = dsem.semester_key
GROUP BY dc.class_id, dc.class_name, dsem.semester_name, dsem.year
ORDER BY dsem.year, dsem.semester_name, dc.class_name;


-- =====================================================================
-- 3. Average Grade by Gender
-- =====================================================================

CREATE OR REPLACE VIEW vw_avg_grade_by_gender AS
SELECT
    ds.gender,
    AVG(fa.grade) AS avg_grade,
    COUNT(*)      AS num_records
FROM fact_attendance fa
JOIN dim_students ds ON fa.student_key = ds.student_key
GROUP BY ds.gender
ORDER BY ds.gender;


-- =====================================================================
-- 4. Average Grade by Nationality
-- Useful for demographic dashboards
-- =====================================================================

CREATE OR REPLACE VIEW vw_avg_grade_by_nationality AS
SELECT
    ds.nationality,
    AVG(fa.grade) AS avg_grade,
    COUNT(*)      AS num_records
FROM fact_attendance fa
JOIN dim_students ds ON fa.student_key = ds.student_key
GROUP BY ds.nationality
ORDER BY avg_grade DESC;


-- =====================================================================
-- 5. Grades by Semester (trend line)
-- =====================================================================

CREATE OR REPLACE VIEW vw_grade_trends AS
SELECT
    dsem.semester_name,
    dsem.year,
    AVG(fa.grade) AS avg_grade,
    COUNT(*)      AS num_records
FROM fact_attendance fa
JOIN dim_semesters dsem ON fa.semester_key = dsem.semester_key
GROUP BY dsem.semester_name, dsem.year
ORDER BY dsem.year, dsem.semester_name;


-- =====================================================================
-- 6. Student Ranking (per semester)
-- =====================================================================

CREATE OR REPLACE VIEW vw_student_ranking AS
SELECT
    ds.student_id,
    ds.first_name,
    ds.last_name,
    dsem.semester_name,
    dsem.year,
    AVG(fa.grade) AS avg_grade
FROM fact_attendance fa
JOIN dim_students  ds   ON fa.student_key  = ds.student_key
JOIN dim_semesters dsem ON fa.semester_key = dsem.semester_key
GROUP BY ds.student_id, ds.first_name, ds.last_name, dsem.semester_name, dsem.year
ORDER BY dsem.year, dsem.semester_name, avg_grade DESC;


-- =====================================================================
-- 7. Class Ranking (best classes overall)
-- =====================================================================

CREATE OR REPLACE VIEW vw_class_ranking AS
SELECT
    dc.class_id,
    dc.class_name,
    AVG(fa.grade) AS avg_grade,
    COUNT(*)      AS num_records
FROM fact_attendance fa
JOIN dim_classes dc ON fa.class_key = dc.class_key
GROUP BY dc.class_id, dc.class_name
ORDER BY avg_grade DESC;


-- =====================================================================
-- 8. Daily Grade Activity (per date)
-- Good for time-series charts
-- =====================================================================

CREATE OR REPLACE VIEW vw_daily_grades AS
SELECT
    dd.date_value,
    dd.year,
    dd.month,
    dd.day,
    AVG(fa.grade) AS avg_grade,
    COUNT(*)      AS num_records
FROM fact_attendance fa
JOIN dim_date dd ON fa.date_key = dd.date_key
GROUP BY dd.date_value, dd.year, dd.month, dd.day
ORDER BY dd.date_value;


-- =====================================================================
-- END OF FILE
-- =====================================================================
