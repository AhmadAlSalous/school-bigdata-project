# 🏫 School Big Data Project  
### Hadoop • Hive • Spark • Star Schema • Data Warehouse • Dashboard-ready Views

This project implements an end-to-end **Big Data Analytics system** for a school using:

- Hadoop (HDFS)
- Hive (Data Warehouse + Star Schema)
- Spark (ETL + Transformations)
- HBase (Storage for future real-time access)
- A UI Dashboard (built by a separate frontend team)

The system transforms raw CSV datasets into a fully modeled **data warehouse** designed for analytics, reporting, and dashboards.

---

# 📌 Project Goals

✔ Build a scalable Data Warehouse for school analytics  
✔ Clean and transform raw datasets using Hive/Spark  
✔ Implement a **Star Schema** for fast analytics  
✔ Generate **Hive SQL views** for the UI dashboard team  
✔ Provide API-ready schema and documentation  
✔ Visualize KPIs such as:  
- Student performance trends  
- Class/teacher performance  
- Semester-level insights  
- Gender/nationality-based performance  
- Daily grade/activity trends  

---

# 🏗 Architecture Overview

         +-------------------+
         |     Raw CSV       |
         | (students, grades |
         |  classes, etc.)   |
         +---------+---------+
                   |
                   v
          +------------------+
          |       HDFS       |
          | /school/raw/...  |
          +---------+--------+
                    |
                    v
    +--------------------------------+
    |            Hive RAW            |
    | (External tables from CSV)     |
    +----------------+---------------+
                     |
                     v
    +--------------------------------+
    |          Hive CLEAN            |
    |  (typed, validated tables)     |
    +----------------+---------------+
                     |
                     v
    +--------------------------------+
    |         STAR SCHEMA            |
    | dim_students, dim_classes,     |
    | dim_teachers, dim_semesters,   |
    | dim_date, fact_attendance      |
    +----------------+---------------+
                     |
                     v
    +--------------------------------+
    |        Hive Dashboard Views    |
    |   (avg grade by class, trends) |
    +--------------------------------+
                     |
                     v
    +--------------------------------+
    |           UI Dashboard         |
    +--------------------------------+

---
                   +---------------------------+
                   |       Frontend UI         |
                   |  (React / Vue / HTML)     |
                   +-------------+-------------+
                                 |
                                 |  (HTTP JSON API)
                                 v
                   +---------------------------+
                   |        Backend API         |
                   |   Flask / FastAPI (Python) |
                   |   Runs on your machine     |
                   +-------------+--------------+
                                 |
                                 | (Reads Parquet/CSV)
                                 v
      +----------------------------------------------------------+
      |                     Data Warehouse (DW)                  |
      |   HiveStar Schema   |   Clean Parquet Tables   |  CSVs   |
      |   (fact + dims)     |   (exports for UI team)            |
      +----------------------------------------------------------+
                                 |
                                 | (HDFS raw → Hive raw)
                                 v
                        HDFS Raw Zone (/school/raw/)


# 📦 Datasets Used

### 1. Students  
- student_id  
- first_name, last_name  
- gender  
- nationality  
- birthdate  
- grade_level  
- class_name  

### 2. Teachers  
- teacher_id  
- first_name, last_name  
- nationality  
- subject  
- hire_date  

### 3. Classes  
- class_id  
- class_name  
- grade_level  
- teacher_id  

### 4. Semesters  
- semester_id  
- semester_name  
- start_date  
- end_date  
- year  

### 5. Attendance / Grades  
- attendance_id  
- student_id  
- class_id  
- attendance_date  
- grade  

---

# 🗄 Star Schema

### **Dimensions**
- `dim_students`
- `dim_teachers`
- `dim_classes`
- `dim_semesters`
- `dim_date`

### **Fact Table**
- `fact_attendance`

This schema enables high-performance analytics and dashboard queries.

---

# 🧹 ETL Pipeline (Hive)

The full ETL is implemented in:

hive/create_tables.hql

Steps:

1. Load raw tables (external)  
2. Create clean, typed tables (managed)  
3. Build dimensions  
4. Generate surrogate keys  
5. Populate fact table  

This script can be run with:

```bash
hive -f hive/create_tables.hql
