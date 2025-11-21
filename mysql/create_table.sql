CREATE DATABASE IF NOT EXISTS retail_project;
USE retail_project;
CREATE TABLE IF NOT EXISTS transactions (
    CustomerID VARCHAR(50),
    ProductID CHAR(1), 
    Quantity INT,
    Price DECIMAL(10,2),
    TransactionDate VARCHAR(50),
    PaymentMethod VARCHAR(20), 
    StoreLocation TEXT, 
    ProductCategory VARCHAR(50),
    DiscountApplied DECIMAL(5,2),
    TotalAmount DECIMAL(10,2) 
);

