# Retail Sales BI Pipeline

Pipeline dữ liệu bán lẻ end-to-end phục vụ phân tích trên Power BI:

```text
Raw CSV → Python ETL → SQL Server (star schema) → Power BI
```

Project xử lý 100.000 giao dịch từ CSV, kiểm tra và làm sạch dữ liệu bằng Python, nạp dữ liệu vào SQL Server theo mô hình fact/dimension, sau đó trực quan hóa bằng dashboard Power BI gồm 3 trang.

## Công nghệ sử dụng

- Python 3.10+, Pandas, PyODBC và python-dotenv
- Microsoft SQL Server và ODBC Driver 18
- Power BI Desktop và DAX

Hadoop, Hive, Sqoop, MySQL và PySpark không được sử dụng trong phiên bản này.

## Cấu trúc project

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

## Quy trình ETL

Script `python/clean_and_load.py` thực hiện:

- Chuẩn hóa tên cột, khoảng trắng và dữ liệu text.
- Chuyển địa chỉ nhiều dòng thành một dòng.
- Ép kiểu dữ liệu số và ngày giờ.
- Loại các dòng thiếu dữ liệu, sai kiểu hoặc sai miền giá trị.
- Chỉ giữ `quantity > 0`, `price > 0` và discount từ 0 đến 100%.
- Chỉ loại các giao dịch trùng hoàn toàn.
- Làm tròn dữ liệu tiền tệ về hai chữ số thập phân.
- Đối chiếu và tính lại `totalamount` theo công thức:

```text
quantity × price × (1 - discountapplied / 100)
```

- Tạo surrogate key cho customer và product.
- Nạp dimension trước fact trong một SQL transaction; rollback toàn bộ nếu load thất bại.

## Mô hình dữ liệu

Project sử dụng star schema gồm một fact table và ba dimension table.

### `fact_retail`

- `transaction_id`: khóa chính tự tăng; mỗi dòng là một giao dịch trong dataset.
- `customer_key`, `product_key`: khóa ngoại tới dimension.
- `customerid`, `productid`: business ID từ dữ liệu nguồn.
- `quantity`, `price`, `discountapplied`, `totalamount`.
- `transactiondateonly`: ngày giao dịch.

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

### Surrogate key và relationships

Trong dữ liệu nguồn, cùng một `customerid` có thể xuất hiện với nhiều payment method/location và cùng một `productid` có thể đi cùng nhiều category. Vì vậy, `customerid` và `productid` không đủ duy nhất để làm phía `1` của relationship.

Dimension được xác định theo các tổ hợp nghiệp vụ:

- Customer: (`customerid`, `paymentmethod`, `storelocation`)
- Product: (`productid`, `productcategory`)

Relationships trong Power BI:

```text
dim_customer[customer_key]        1 → * fact_retail[customer_key]
dim_product[product_key]          1 → * fact_retail[product_key]
dim_date[transactiondateonly]     1 → * fact_retail[transactiondateonly]
```

Đặt `Cross-filter direction = Single` từ dimension sang fact. Không tạo relationship bằng `customerid` hoặc `productid`.

> Lưu ý mô hình: `paymentmethod` và `storelocation` thay đổi theo giao dịch trong dữ liệu nguồn. Project hiện dùng surrogate key theo tổ hợp để bảo toàn dữ liệu và relationship. Trong mô hình production, hai thuộc tính này có thể được đưa về transaction-level hoặc tách thành dimension riêng tùy yêu cầu phân tích.

## DAX measures

Trong Power BI, tạo một bảng riêng tên `Measures` và đặt các measure sau vào bảng này:

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

`Total Transactions` dùng `transaction_id` để thể hiện rõ grain của fact table. Với dữ liệu hiện tại, kết quả tương đương `COUNTROWS(fact_retail)`.

## Dashboard Power BI

File report: `power_bi/bigdata_retail_pipeline.pbix`.

### Page 1 — Sales Overview

Trang tổng quan trả lời câu hỏi: tình hình kinh doanh hiện tại như thế nào?

- KPI cards: Total Retail, Total Transactions, Total Quantity và Average Transaction Value.
- Line chart: Monthly Retail Trend theo `dim_date[transactiondateonly]` và Total Retail.
- Bar chart: Sales by Product, sắp xếp Total Retail giảm dần.
- Bar chart: Top 10 Store Locations theo Total Retail.
- Donut chart: Sales by Payment Method.
- Slicers: Year, Product Category và Store Location.

Vì `transactionmonth` trong database là số tháng từ 1–12, có thể dùng trực tiếp để giữ đúng thứ tự. Nếu hiển thị tên tháng bằng một calculated column, cần sort tên tháng theo cột số tháng.

### Page 2 — Product Performance

Trang phân tích sản phẩm trả lời câu hỏi: sản phẩm/category nào tạo doanh thu, sản lượng và mức discount nổi bật?

- KPI cards: Total Products, Total Retail, Total Quantity và Average Price.
- Bar chart: Retail by Product.
- Column/bar chart: Quantity by Product.
- Donut hoặc bar chart: Retail by Product Category.
- Bar chart: Average Discount by Product.
- Slicers: Year, Product Category và Product ID.

Các chart theo product nên được sort giảm dần theo measure tương ứng; có thể áp dụng Top N khi cần tăng khả năng đọc.

### Page 3 — Customer & Store Analysis

Trang phân tích customer/store trả lời câu hỏi: customer, store location và payment method nào đóng góp nhiều nhất?

- KPI cards: Total Customers, Total Retail, Retail per Customer và Total Transactions.
- Bar chart: Top 10 Store Locations theo Total Retail.
- Donut chart: Retail by Payment Method.
- Bar chart: Customers by Store, dùng distinct count customer.
- Store Performance table: Store Location, Total Retail, Total Transactions, Total Quantity, Total Customers và Retail per Customer.
- Slicers: Year, Store Location và Payment Method.

Ba trang tạo thành luồng phân tích từ tổng quan đến các business driver:

```text
Sales Overview → Product Performance → Customer & Store Analysis
```

## Cài đặt

Yêu cầu: Python 3.10+, SQL Server và ODBC Driver 18 for SQL Server.

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Điền cấu hình SQL Server trong `.env`. Project hỗ trợ Windows Authentication qua `SQL_TRUSTED_CONNECTION=yes` hoặc SQL Server Authentication bằng username/password. Không commit file `.env` vì có thể chứa thông tin đăng nhập.

## Chạy pipeline

1. Chạy `sql/create_database.sql` trong SQL Server Management Studio.

   Script tạo database nếu chưa tồn tại, sau đó drop và tạo lại các bảng của project. Dữ liệu hiện có trong các bảng này sẽ bị thay thế.

2. Kiểm tra và làm sạch dữ liệu mà chưa load vào SQL Server:

```powershell
python python/clean_and_load.py --dry-run
```

3. Làm sạch và nạp dữ liệu:

```powershell
python python/clean_and_load.py
```

4. Chạy `sql/data_quality_checks.sql` để kiểm tra row count, duplicate business keys, missing foreign keys và công thức `totalamount`.

## Kết nối Power BI

Trong Power BI Desktop, chọn **Get Data → SQL Server**:

```text
Server: localhost
Database: retail_project
Authentication: Windows
Data connectivity mode: Import
```

Import `fact_retail`, `dim_customer`, `dim_product` và `dim_date`, sau đó kiểm tra relationships theo surrogate key như mô tả ở trên.

## Kết quả kiểm tra

Kết quả chạy `--dry-run` trên dataset hiện tại:

| Chỉ số | Kết quả |
|---|---:|
| Raw rows | 100.000 |
| Clean rows | 100.000 |
| Rejected rows | 0 |
| Duplicate rows | 0 |
| Source total mismatches | 0 |

| Bảng | Số dòng |
|---|---:|
| `fact_retail` | 100.000 |
| `dim_customer` | 100.000 |
| `dim_product` | 16 |
| `dim_date` | 366 |

Không có fact record bị mất liên kết với dimension sau khi load và chạy data-quality checks.


