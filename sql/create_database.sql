IF DB_ID(N'retail_project') IS NULL
BEGIN
    CREATE DATABASE retail_project;
END;
GO

USE retail_project;
GO

DROP TABLE IF EXISTS dbo.fact_retail;
DROP TABLE IF EXISTS dbo.dim_customer;
DROP TABLE IF EXISTS dbo.dim_product;
DROP TABLE IF EXISTS dbo.dim_date;
DROP TABLE IF EXISTS dbo.etl_run_log;
GO

CREATE TABLE dbo.fact_retail (
    transaction_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    customerid VARCHAR(50) NOT NULL,
    productid VARCHAR(50) NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    discountapplied DECIMAL(5,2) NOT NULL,
    totalamount DECIMAL(18,2) NOT NULL,
    transactiondateonly DATE NOT NULL
);
GO

CREATE TABLE dbo.dim_customer (
    customer_key INT NOT NULL PRIMARY KEY,
    customerid VARCHAR(50) NOT NULL,
    paymentmethod VARCHAR(50) NOT NULL,
    storelocation NVARCHAR(500) NOT NULL,
    CONSTRAINT UQ_dim_customer_business
        UNIQUE (customerid, paymentmethod, storelocation)
);
GO

CREATE TABLE dbo.dim_product (
    product_key INT NOT NULL PRIMARY KEY,
    productid VARCHAR(50) NOT NULL,
    productcategory VARCHAR(100) NOT NULL,
    CONSTRAINT UQ_dim_product_business UNIQUE (productid, productcategory)
);
GO

CREATE TABLE dbo.dim_date (
    transactiondateonly DATE NOT NULL PRIMARY KEY,
    transactionday TINYINT NOT NULL,
    transactionmonth TINYINT NOT NULL,
    transactionyear SMALLINT NOT NULL
);
GO

CREATE INDEX IX_fact_retail_customerid ON dbo.fact_retail(customerid);
CREATE INDEX IX_fact_retail_productid ON dbo.fact_retail(productid);
CREATE INDEX IX_fact_retail_customer_key ON dbo.fact_retail(customer_key);
CREATE INDEX IX_fact_retail_product_key ON dbo.fact_retail(product_key);
CREATE INDEX IX_fact_retail_date ON dbo.fact_retail(transactiondateonly);
GO

ALTER TABLE dbo.fact_retail ADD CONSTRAINT FK_fact_retail_customer
    FOREIGN KEY (customer_key) REFERENCES dbo.dim_customer(customer_key);
ALTER TABLE dbo.fact_retail ADD CONSTRAINT FK_fact_retail_product
    FOREIGN KEY (product_key) REFERENCES dbo.dim_product(product_key);
ALTER TABLE dbo.fact_retail ADD CONSTRAINT FK_fact_retail_date
    FOREIGN KEY (transactiondateonly) REFERENCES dbo.dim_date(transactiondateonly);
GO
