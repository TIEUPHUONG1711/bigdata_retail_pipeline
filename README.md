# Retail Sales BI Pipeline

An end-to-end retail data pipeline for analysis in Power BI:

```text
Raw CSV → Python ETL → SQL Server (star schema) → Power BI
```

The project processes 100,000 transactions from CSV, validates and cleans the data with Python, loads it into SQL Server using a fact/dimension model, and visualizes it in a three-page Power BI dashboard.

## Technologies

- Python 3.10+, Pandas, PyODBC, and python-dotenv
- Microsoft SQL Server and ODBC Driver 18
- Power BI Desktop and DAX

Hadoop, Hive, Sqoop, MySQL, and PySpark are not used in this version.

## Project Structure

```text
bigdata_retail_pipeline/
├── data/
│   └── Retail_Transaction_Dataset.csv
├── power_bi/
│   └── bigdata_retail_pipeline.pbix
├── python/
│   └── clean_and_load.py
├── sql/
│   ├── create_database.sql
│   └── data_quality_checks.sql
├── .env.example
├── requirements.txt
└── README.md
```

## ETL Process

The `python/clean_and_load.py` script performs the following tasks:

- Standardizes column names, whitespace, and text data.
- Converts multi-line addresses into a single line.
- Casts numeric and datetime data types.
- Removes rows with missing data, invalid types, or invalid value ranges.
- Keeps only `quantity > 0`, `price > 0`, and discounts from 0% to 100%.
- Removes only completely duplicated transactions.
- Rounds monetary values to two decimal places.
- Reconciles and recalculates `totalamount` using the formula:

```text
quantity × price × (1 - discountapplied / 100)
```

- Creates surrogate keys for customers and products.
- Loads dimensions before the fact table within one SQL transaction; everything is rolled back if loading fails.

## Data Model

The project uses a star schema with one fact table and three dimension tables.

### `fact_retail`

- `transaction_id`: auto-increment primary key; each row represents one transaction in the dataset.
- `customer_key`, `product_key`: foreign keys to the dimensions.
- `customerid`, `productid`: business IDs from the source data.
- `quantity`, `price`, `discountapplied`, `totalamount`.
- `transactiondateonly`: transaction date.

### `dim_customer`

- `customer_key`
- `customerid`
- `paymentmethod`
- `storelocation`

### `dim_product`

- `product_key`
- `productid`
- `productcategory`

### `dim_date`

- `transactiondateonly`
- `transactionday`
- `transactionmonth`
- `transactionyear`

### Surrogate Keys and Relationships

In the source data, the same `customerid` can appear with multiple payment methods/locations, and the same `productid` can be associated with multiple categories. Therefore, `customerid` and `productid` are not unique enough to be on the `1` side of a relationship.

Dimensions are identified using the following business combinations:

- Customer: (`customerid`, `paymentmethod`, `storelocation`)
- Product: (`productid`, `productcategory`)

Relationships in Power BI:

```text
dim_customer[customer_key]       1 → * fact_retail[customer_key]
dim_product[product_key]         1 → * fact_retail[product_key]
dim_date[transactiondateonly]    1 → * fact_retail[transactiondateonly]
```

Set `Cross-filter direction = Single` from dimension to fact. Do not create relationships using `customerid` or `productid`.

> Model note: `paymentmethod` and `storelocation` vary by transaction in the source data. The project currently uses surrogate keys based on combinations to preserve the data and relationships. In a production model, these two attributes could be moved to the transaction level or separated into their own dimensions depending on analytical requirements.

## DAX Measures

In Power BI, create a separate table named `Measures` and place the following measures in this table:

```DAX
Total Retail =
SUM(fact_retail[totalamount])

Total Quantity =
SUM(fact_retail[quantity])

Total Transactions =
DISTINCTCOUNT(fact_retail[transaction_id])

Average Transaction Value =
DIVIDE([Total Retail], [Total Transactions])

Total Customers =
DISTINCTCOUNT(fact_retail[customerid])

Total Products =
DISTINCTCOUNT(fact_retail[productid])

Average Price =
AVERAGE(fact_retail[price])

Average Discount =
AVERAGE(fact_retail[discountapplied])

Retail per Customer =
DIVIDE([Total Retail], [Total Customers])
```

`Total Transactions` uses `transaction_id` to clearly represent the grain of the fact table. With the current data, the result is equivalent to `COUNTROWS(fact_retail)`.

## Power BI Dashboard

Report file: `power_bi/bigdata_retail_pipeline.pbix`.

### Page 1 — Sales Overview

The overview page answers the question: How is the business currently performing?

- KPI cards: Total Retail, Total Transactions, Total Quantity, and Average Transaction Value.
- Line chart: Monthly Retail Trend using `dim_date[transactiondateonly]` and Total Retail.
- Bar chart: Sales by Product, sorted by Total Retail in descending order.
- Bar chart: Top 10 Store Locations by Total Retail.
- Donut chart: Sales by Payment Method.
- Slicers: Year, Product Category, and Store Location.

Because `transactionmonth` in the database is a month number from 1–12, it can be used directly to preserve the correct order. If month names are displayed using a calculated column, the month names must be sorted by the numeric month column.

### Page 2 — Product Performance

The product analysis page answers the question: Which products/categories stand out in terms of revenue, quantity, and discount levels?

- KPI cards: Total Products, Total Retail, Total Quantity, and Average Price.
- Bar chart: Retail by Product.
- Column/bar chart: Quantity by Product.
- Donut or bar chart: Retail by Product Category.
- Bar chart: Average Discount by Product.
- Slicers: Year, Product Category, and Product ID.

Product charts should be sorted in descending order by the corresponding measure; Top N can be applied when needed to improve readability.

### Page 3 — Customer & Store Analysis

The customer/store analysis page answers the question: Which customers, store locations, and payment methods contribute the most?

- KPI cards: Total Customers, Total Retail, Retail per Customer, and Total Transactions.
- Bar chart: Top 10 Store Locations by Total Retail.
- Donut chart: Retail by Payment Method.
- Bar chart: Customers by Store, using distinct count of customers.
- Store Performance table: Store Location, Total Retail, Total Transactions, Total Quantity, Total Customers, and Retail per Customer.
- Slicers: Year, Store Location, and Payment Method.

The three pages form an analytical flow from overview to business drivers:

```text
Sales Overview → Product Performance → Customer & Store Analysis
```

## Installation

Requirements: Python 3.10+, SQL Server, and ODBC Driver 18 for SQL Server.

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Fill in the SQL Server configuration in `.env`. The project supports Windows Authentication through `SQL_TRUSTED_CONNECTION=yes` or SQL Server Authentication using a username/password. Do not commit the `.env` file because it may contain login credentials.

## Running the Pipeline

1. Run `sql/create_database.sql` in SQL Server Management Studio.

   The script creates the database if it does not already exist, then drops and recreates the project tables. Existing data in these tables will be replaced.

2. Validate and clean the data without loading it into SQL Server:

```powershell
python python/clean_and_load.py --dry-run
```

3. Clean and load the data:

```powershell
python python/clean_and_load.py
```

4. Run `sql/data_quality_checks.sql` to check row count, duplicate business keys, missing foreign keys, and the `totalamount` formula.

## Connecting Power BI

In Power BI Desktop, select **Get Data → SQL Server**:

```text
Server: localhost
Database: retail_project
Authentication: Windows
Data connectivity mode: Import
```

Import `fact_retail`, `dim_customer`, `dim_product`, and `dim_date`, then verify the relationships using surrogate keys as described above.

## Validation Results

Results from running `--dry-run` on the current dataset:

| Metric | Result |
|---|---:|
| Raw rows | 100,000 |
| Clean rows | 100,000 |
| Rejected rows | 0 |
| Duplicate rows | 0 |
| Source total mismatches | 0 |

| Table | Row Count |
|---|---:|
| `fact_retail` | 100,000 |
| `dim_customer` | 100,000 |
| `dim_product` | 16 |
| `dim_date` | 366 |

No fact records have missing relationships with dimensions after loading and running the data-quality checks.