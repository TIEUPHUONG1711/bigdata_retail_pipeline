#!/bin/bash

sqoop import \
  --connect jdbc:mysql://localhost/retail_project \
  --username root \
  --password 123456 \
  --table transactions \
  --hive-import \
  --create-hive-table \
  --hive-database retail \
  --hive-table transactions_raw \
  --num-mappers 1

