from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_timestamp
from pyspark.sql.functions import year,month,dayofmonth,to_date

spark = SparkSession.builder \
    .appName("Retail Cleaning") \
    .enableHiveSupport() \
    .config("spark.sql.legacy.timeParserPolicy", "LEGACY") \
    .getOrCreate()

spark.sql("use retail")
a = spark.sql("select * from transactions_raw").cache()
a = a.filter((a.quantity >0) & (a.price >0))
a = a.withColumn("transactiondate", to_timestamp("transactiondate", "M/d/yyyy HH:mm"))		
a = a.dropna()
a = a.dropDuplicates(["customerid","productid","transactiondate"])
a = a.withColumn("TransactionYear",year("transactiondate")).withColumn("TransactionMonth",month("transactiondate")).withColumn("TransactionDay",dayofmonth("transactiondate")).withColumn("TransactionDateonly",to_date("transactiondate"))

a = a.drop("transactiondate")

a.write.saveAsTable("retail.transactions_done")

fact_retail = a.select("customerid","productid","quantity","price","discountapplied","totalamount","TransactionDateonly")

fact_retail.write.saveAsTable("retail.fact_retail")

dim_customer = a.select("customerid","paymentmethod","storelocation")

dim_customer.write.saveAsTable("retail.dim_customer")

dim_product = a.select("productid","productcategory")

dim_product.write.saveAsTable("retail.dim_product")

dim_date = a.select("TransactionDateonly","TransactionYear","TransactionMonth","TransactionDay").distinct()

dim_date.write.saveAsTable("retail.dim_date")
