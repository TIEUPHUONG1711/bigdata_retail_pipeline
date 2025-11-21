# Big Data Retail Project

## Dataset
- Retail Transactions Dataset từ Kaggle
- Fields: CustomerID, ProductID, Quantity, Price, TransactionDate, PaymentMethod, StoreLocation, ProductCategory, DiscountApplied(%), TotalAmount


## Project Pipeline
1. MySQL: tạo bảng và load CSV
2. Sqoop: import MySQL → Hive/HDFS
3. Hive: lưu dữ liệu sau khi đã làm sạch
4. PySpark: clean dữ liệu, build fact table, aggregate
5. Power BI: tạo dashboard từ Hive tables

## Folder Structure
- mysql/: create_table.sql, load_data.sql
- sqoop/: import_to_hive.sh
- hive/: create_hive_tables.hql
- pyspark_sparksql/: pyspark_cleaning.py
- power_bi/: bigdata_retail_pipeline.pbix

## HƯỚNG DẪN CHẠY
Yêu cầu
- MySQL 8.0+, Hive
- Python 3.8+
- PySpark, sparksql
- Sqoop
- Docker
  
1. Clone repo:
git clone https://github.com/TIEUPHUONG1711/bigdata_retail_pipeline.git
cd bigdata_retail_pipeline

2. Chạy mysql để load dữ liệu:
mysql -u root -p						
SOURCE /home/hadoop/bigdata_retail_pipeline/mysql/create_tables.sql;						
SOURCE /home/hadoop/bigdata_retail_pipeline/mysql/load_data.sql;
* có thể test để kiểm tra:				
SELECT COUNT(*) FROM retail_project.transactions;						
SELECT * FROM retail_project.transactions LIMIT 5;

3. Chạy hive để tạo database lưu trữ dữ liệu:
$HIVE_HOME/bin/hiveserver2 &
beeline -u jdbc:hive2://localhost:10000/default -n hadoop					
!run /home/hadoop/bigdata_retail_pipeline/hive/create_hive_tables.hql
				
5. Chạy sqoop để import dữ liệu từ mysql vào hive:
bash /home/hadoop/bigdata_retail_pipeline/sqoop/import_to_hive.sh						
beeline -u jdbc:hive2://localhost:10000/default -n hadoop (chạy hive để kiểm tra dữ liệu)
* có thể test để kiểm tra:			
SELECT COUNT(*) FROM transactions_raw;						
SELECT * FROM transactions_raw LIMIT 5;

6. Chạy pyspark_sparksql để làm sạch dữ liệu, tạo các bảng fact và dim:
spark-submit \				
--master local[*] \				
--conf spark.sql.catalogImplementation=hive \				
/home/hadoop/bigdata_retail_pipeline/pyspark_sparksql/pyspark_cleaning.py

7. Kết nối với Hive trên máy ảo và POWER BI trên máy window để tạo dashboard

