LOAD DATA LOCAL INFILE 'data/Retail_Transaction_Dataset.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(CustomerID,ProductID,Quantity,Price,TransactionDate,PaymentMethod,StoreLocation,ProductCategory,DiscountApplied,TotalAmount
);
UPDATE transactions
SET StoreLocation = REPLACE(StoreLocation, '\n', ' ');

