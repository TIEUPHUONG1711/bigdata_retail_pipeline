USE retail_project;
GO

SELECT 'fact_retail' AS table_name, COUNT_BIG(*) AS row_count FROM dbo.fact_retail
UNION ALL
SELECT 'dim_customer', COUNT_BIG(*) FROM dbo.dim_customer
UNION ALL
SELECT 'dim_product', COUNT_BIG(*) FROM dbo.dim_product
UNION ALL
SELECT 'dim_date', COUNT_BIG(*) FROM dbo.dim_date;
GO

SELECT transactiondateonly, COUNT_BIG(*) AS duplicate_count
FROM dbo.dim_date
GROUP BY transactiondateonly
HAVING COUNT_BIG(*) > 1;
GO

SELECT customerid, paymentmethod, storelocation, COUNT_BIG(*) AS duplicate_count
FROM dbo.dim_customer
GROUP BY customerid, paymentmethod, storelocation
HAVING COUNT_BIG(*) > 1;
GO

SELECT productid, productcategory, COUNT_BIG(*) AS duplicate_count
FROM dbo.dim_product
GROUP BY productid, productcategory
HAVING COUNT_BIG(*) > 1;
GO

SELECT
    SUM(CASE WHEN c.customer_key IS NULL THEN 1 ELSE 0 END) AS missing_customer,
    SUM(CASE WHEN p.product_key IS NULL THEN 1 ELSE 0 END) AS missing_product,
    SUM(CASE WHEN d.transactiondateonly IS NULL THEN 1 ELSE 0 END) AS missing_date
FROM dbo.fact_retail AS f
LEFT JOIN dbo.dim_customer AS c ON c.customer_key = f.customer_key
LEFT JOIN dbo.dim_product AS p ON p.product_key = f.product_key
LEFT JOIN dbo.dim_date AS d ON d.transactiondateonly = f.transactiondateonly;
GO

SELECT *
FROM dbo.fact_retail
WHERE ABS(totalamount - ROUND(quantity * price * (1 - discountapplied / 100.0), 2)) > 0.01;
GO
