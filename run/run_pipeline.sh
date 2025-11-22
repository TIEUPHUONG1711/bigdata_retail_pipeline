#!/bin/bash
# run_pipeline.sh
# Script tự động chạy pipeline: MySQL → Hive → Sqoop → PySpark

set -e  # dừng script nếu có lỗi

echo "=== 1️⃣ Start MySQL service ==="
service mysql start

echo "=== 2️⃣ Load dữ liệu MySQL ==="
mysql -u root -e "SOURCE /home/hadoop/bigdata_retail_pipeline/mysql/create_table.sql;"
mysql -u root -e "SOURCE /home/hadoop/bigdata_retail_pipeline/mysql/load_data.sql;"
echo " Dữ liệu MySQL đã load xong"
mysql -u root -e "SELECT COUNT(*) FROM retail_project.transactions;"
mysql -u root -e "SELECT * FROM retail_project.transactions LIMIT 5;"

echo "=== 3️⃣ Start HiveServer2 ==="
$HIVE_HOME/bin/hiveserver2 &

# Đợi HiveServer2 khởi động
sleep 10

echo "=== 4️⃣ Tạo bảng Hive ==="
beeline -u jdbc:hive2://localhost:10000/default -n hadoop -e "!run /home/hadoop/bigdata_retail_pipeline/hive/create_hive_tables.hql"
echo " Bảng Hive đã tạo xong"

echo "=== 5️⃣ Chạy Sqoop import từ MySQL → Hive ==="
bash /home/hadoop/bigdata_retail_pipeline/sqoop/import_to_hive.sh

echo " Kiểm tra dữ liệu trong Hive (transactions_raw)"
beeline -u jdbc:hive2://localhost:10000/default -n hadoop -e "SELECT COUNT(*) FROM transactions_raw;"
beeline -u jdbc:hive2://localhost:10000/default -n hadoop -e "SELECT * FROM transactions_raw LIMIT 5;"

echo "=== 6️⃣ Chạy PySpark để làm sạch dữ liệu và tạo fact/dim tables ==="
spark-submit --master local[*] --conf spark.sql.catalogImplementation=hive /home/hadoop/bigdata_retail_pipeline/pyspark_sparksql/pyspark_cleaning.py

echo " Pipeline hoàn tất!"
echo "Bây giờ bạn có thể mở Power BI và kết nối Hive để tạo dashboard."

