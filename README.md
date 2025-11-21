# Big Data Retail Project

## Dataset
- Retail Transactions Dataset từ Kaggle
- Fields: Transaction_ID, Customer_ID, Date, Product, Total_Items, Total_Cost, Payment_Method, Store_Type, City

## Project Pipeline
1. MySQL: tạo bảng và load CSV
2. Sqoop: import MySQL → Hive/HDFS
3. Hive: lưu dữ liệu sau khi đã làm sạch
4. PySpark: clean dữ liệu, build fact table, aggregate
5. Power BI: tạo dashboard từ Hive tables

## Folder Structure
- mysql/: create/load SQL scripts
- sqoop/: import scripts
- hive/: 
- pyspark/: cleaning, fact, agg scripts
- powerbi/: dashboard.pbix
