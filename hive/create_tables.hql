<<<<<<< HEAD

=======
-- =====================================================================
-- School Big Data Project - Hive DDL & ETL
-- RAW (external) → CLEAN (managed) → STAR SCHEMA (dimensions + fact)
-- Database: school_clean
-- =====================================================================

-----------------------------------------------------------------------
-- 0. DATABASES
-----------------------------------------------------------------------

-- Raw tables live in `default` (external)
-- Clean + warehouse tables live in `school_clean`

CREATE DATABASE IF NOT EXISTS school_clean;

-- Just to be explicit later:
-- USE school_clean;


-----------------------------------------------------------------------
-- 1. RAW EXTERNAL TABLES  (CSV in HDFS: /school/raw/...)
-----------------------------------------------------------------------
-- These assume your CSVs match the column orders used below.
-- Adjust column names/types if your files differ.

-- 1.1 raw_teachers
DROP TABLE IF EXISTS default.raw_teachers;

CREATE EXTERNAL TABLE default.raw_teachers (
    teacher_id  STRING,
    first_name  STRING,
    last_name   STRING,
    gender      STRING,
    nationality STRING,
    hire_date   STRING,
    subject     STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ",",
    "quoteChar"     = "\""
)
LOCATION '/school/raw/teachers/';


-- 1.2 raw_semesters
-- CSV columns: semester_id, semester_name, start_datetime, end_datetime, year
DROP TABLE IF EXISTS default.raw_semesters;

CREATE EXTERNAL TABLE default.raw_semesters (
    semester_id    STRING,
    semester_name  STRING,
    start_datetime STRING,
    end_datetime   STRING,
    year           STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ",",
    "quoteChar"     = "\""
)
LOCATION '/school/raw/semesters/';


-- 1.3 raw_attendance
-- CSV columns: attendance_id, student_id, class_id, date, grade
DROP TABLE IF EXISTS default.raw_attendance;

CREATE EXTERNAL TABLE default.raw_attendance (
    attendance_id   STRING,
    student_id      STRING,
    class_id        STRING,
    attendance_date STRING,
    grade           STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ",",
    "quoteChar"     = "\""
)
LOCATION '/school/raw/attendance/';


-- 1.4 raw_students
-- Assumed CSV: student_id, first_name, last_name, gender, nationality,
--              birthdate (yyyy-MM-dd), grade_level, class_name
DROP TABLE IF EXISTS default.raw_students;

CREATE EXTERNAL TABLE default.raw_students (
    student_id   STRING,
    first_name   STRING,
    last_name    STRING,
    gender       STRING,
    nationality  STRING,
    birthdate    STRING,
    grade_level  STRING,
    class_name   STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ",",
    "quoteChar"     = "\""
)
LOCATION '/school/raw/students/';


-- 1.5 raw_classes
-- Assumed CSV: class_id, class_name, grade_level, teacher_id
DROP TABLE IF EXISTS default.raw_classes;

CREATE EXTERNAL TABLE default.raw_classes (
    class_id    STRING,
    class_name  STRING,
    grade_level STRING,
    teacher_id  STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    "separatorChar" = ",",
    "quoteChar"     = "\""
)
LOCATION '/school/raw/classes/';


-----------------------------------------------------------------------
-- 2. CLEAN MANAGED TABLES (PARQUET)  in school_clean
-----------------------------------------------------------------------

USE school_clean;

-- 2.1 teachers_clean
DROP TABLE IF EXISTS teachers_clean;

CREATE TABLE teachers_clean (
    teacher_id   STRING,
    first_name   STRING,
    last_name    STRING,
    gender       STRING,
    nationality  STRING,
    hire_date    DATE,
    subject      STRING
)
STORED AS PARQUET;

INSERT OVERWRITE TABLE teachers_clean
SELECT
    teacher_id,
    first_name,
    last_name,
    gender,
    nationality,
    CAST(hire_date AS DATE) AS hire_date,
    subject
FROM default.raw_teachers;


-- 2.2 semesters_clean
DROP TABLE IF EXISTS semesters_clean;

CREATE TABLE semesters_clean (
    semester_id   STRING,
    semester_name STRING,
    start_date    DATE,
    end_date      DATE,
    year          INT
)
STORED AS PARQUET;

INSERT OVERWRITE TABLE semesters_clean
SELECT
    semester_id,
    semester_name,
    TO_DATE(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(start_datetime, 'yyyy-MM-dd\'T\'HH:mm:ss')
        )
    ) AS start_date,
    TO_DATE(
        FROM_UNIXTIME(
            UNIX_TIMESTAMP(end_datetime, 'yyyy-MM-dd\'T\'HH:mm:ss')
        )
    ) AS end_date,
    CAST(year AS INT) AS year
FROM default.raw_semesters;


-- 2.3 attendance_clean
DROP TABLE IF EXISTS attendance_clean;

CREATE TABLE attendance_clean (
    attendance_id   INT,
    student_id      INT,
    class_id        INT,
    attendance_date DATE,
    grade           INT
)
STORED AS PARQUET;

INSERT OVERWRITE TABLE attendance_clean
SELECT
    CAST(attendance_id   AS INT),
    CAST(student_id      AS INT),
    CAST(class_id        AS INT),
    CAST(attendance_date AS DATE),
    CAST(grade           AS INT)
FROM default.raw_attendance;


-- 2.4 students_clean
DROP TABLE IF EXISTS students_clean;

CREATE TABLE students_clean (
    student_id   STRING,
    first_name   STRING,
    last_name    STRING,
    gender       STRING,
    nationality  STRING,
    birthdate    DATE,
    grade_level  INT,
    class_name   STRING
)
STORED AS PARQUET;

INSERT OVERWRITE TABLE students_clean
SELECT
    student_id,
    first_name,
    last_name,
    gender,
    nationality,
    CAST(birthdate AS DATE)       AS birthdate,
    CAST(grade_level AS INT)      AS grade_level,
    class_name
FROM default.raw_students;


-- 2.5 classes_clean
DROP TABLE IF EXISTS classes_clean;

CREATE TABLE classes_clean (
    class_id    STRING,
    class_name  STRING,
    grade_level INT,
    teacher_id  STRING
)
STORED AS PARQUET;

INSERT OVERWRITE TABLE classes_clean
SELECT
    class_id,
    class_name,
    CAST(grade_level AS INT) AS grade_level,
    teacher_id
FROM default.raw_classes;


-----------------------------------------------------------------------
-- 3. STAR SCHEMA - DIMENSION TABLES
-----------------------------------------------------------------------

-- 3.1 dim_students
DROP TABLE IF EXISTS dim_students;

CREATE TABLE dim_students (
    student_key     INT,
    student_id      STRING,
    first_name      STRING,
    last_name       STRING,
    gender          STRING,
    nationality     STRING,
    birthdate       DATE,
    grade_level     INT,
    class_name      STRING
)
STORED AS PARQUET;

INSERT OVERWRITE TABLE dim_students
SELECT
    ROW_NUMBER() OVER (ORDER BY student_id) AS student_key,
    student_id,
    first_name,
    last_name,
    gender,
    nationality,
    birthdate,
    grade_level,
    class_name
FROM students_clean;


-- 3.2 dim_teachers
DROP TABLE IF EXISTS dim_teachers;

CREATE TABLE dim_teachers (
    teacher_key     INT,
    teacher_id      STRING,
    first_name      STRING,
    last_name       STRING,
    gender          STRING,
    nationality     STRING,
    subject         STRING,
    hire_date       DATE
)
STORED AS PARQUET;

INSERT OVERWRITE TABLE dim_teachers
SELECT
    ROW_NUMBER() OVER (ORDER BY teacher_id) AS teacher_key,
    teacher_id,
    first_name,
    last_name,
    gender,
    nationality,
    subject,
    hire_date
FROM teachers_clean;


-- 3.3 dim_classes
DROP TABLE IF EXISTS dim_classes;

CREATE TABLE dim_classes (
    class_key       INT,
    class_id        STRING,
    class_name      STRING,
    grade_level     INT,
    teacher_id      STRING
)
STORED AS PARQUET;

INSERT OVERWRITE TABLE dim_classes
SELECT
    ROW_NUMBER() OVER (ORDER BY class_id) AS class_key,
    class_id,
    class_name,
    grade_level,
    teacher_id
FROM classes_clean;


-- 3.4 dim_semesters
DROP TABLE IF EXISTS dim_semesters;

CREATE TABLE dim_semesters (
    semester_key    INT,
    semester_id     STRING,
    semester_name   STRING,
    start_date      DATE,
    end_date        DATE,
    year            INT
)
STORED AS PARQUET;

INSERT OVERWRITE TABLE dim_semesters
SELECT
    ROW_NUMBER() OVER (ORDER BY semester_id) AS semester_key,
    semester_id,
    semester_name,
    start_date,
    end_date,
    year
FROM semesters_clean;


-- 3.5 dim_date (from attendance dates)
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    date_key        INT,
    date_value      DATE,
    year            INT,
    month           INT,
    day             INT,
    day_of_week     STRING
)
STORED AS PARQUET;

INSERT OVERWRITE TABLE dim_date
SELECT
    ROW_NUMBER() OVER (ORDER BY date_value) AS date_key,
    date_value,
    YEAR(date_value)                      AS year,
    MONTH(date_value)                     AS month,
    DAY(date_value)                       AS day,
    DATE_FORMAT(date_value, 'EEEE')       AS day_of_week
FROM (
    SELECT DISTINCT attendance_date AS date_value
    FROM attendance_clean
) d;


-----------------------------------------------------------------------
-- 4. STAR SCHEMA - FACT TABLE (Option A: without teacher_key)
-----------------------------------------------------------------------

DROP TABLE IF EXISTS fact_attendance;

CREATE TABLE fact_attendance (
    attendance_id   INT,
    student_key     INT,
    class_key       INT,
    semester_key    INT,
    date_key        INT,
    grade           INT
)
STORED AS PARQUET;

INSERT OVERWRITE TABLE fact_attendance
SELECT
    a.attendance_id,
    ds.student_key,
    dc.class_key,
    dsem.semester_key,
    dd.date_key,
    a.grade
FROM attendance_clean a
LEFT JOIN dim_students ds
    ON CAST(a.student_id AS STRING) = ds.student_id
LEFT JOIN dim_classes dc
    ON CAST(a.class_id AS STRING) = dc.class_id
LEFT JOIN dim_semesters dsem
    ON a.attendance_date BETWEEN dsem.start_date AND dsem.end_date
LEFT JOIN dim_date dd
    ON a.attendance_date = dd.date_value;

-- =====================================================================
-- END OF FILE
-- =====================================================================
>>>>>>> c7208d4 (Add Hive DW schema and star schema setup)
