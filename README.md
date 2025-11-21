# Big Data Retail Project

## Dataset
- Retail Transactions Dataset từ Kaggle
- Fields: Transaction_ID, Customer_ID, Date, Product, Total_Items, Total_Cost, Payment_Method, Store_Type, City

## Project Pipeline
1. MySQL: tạo bảng và load CSV
2. Sqoop: import MySQL → Hive/HDFS
3. Hive: tạo table, transform dữ liệu
4. PySpark: clean dữ liệu, build fact table, aggregate
5. Power BI: tạo dashboard từ Hive tables

## Folder Structure
- mysql/: create/load SQL scripts
- sqoop/: import scripts
- hive/: Hive create/transform scripts
- pyspark/: cleaning, fact, agg scripts
- powerbi/: dashboard.pbix
