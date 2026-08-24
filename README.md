# Retail Sales BI Pipeline

Project xây dựng pipeline dữ liệu bán lẻ phục vụ phân tích trên Power BI:

```text
Raw CSV → Python ETL → SQL Server → Power BI
```

## Tổng quan

- Dữ liệu nguồn: 100.000 giao dịch bán lẻ trong file CSV.
- Python đọc, kiểm tra, làm sạch và nạp dữ liệu.
- SQL Server lưu dữ liệu theo mô hình fact/dimension.
- Power BI kết nối SQL Server để xây dựng dashboard và DAX measures.

Các công nghệ Hadoop, Hive, Sqoop, MySQL và PySpark không được sử dụng trong
phiên bản này.

## Cấu trúc project

```text
bigdata_retail_pipeline/
├── data/
│   └── Retail_Transaction_Dataset.csv
├── python/
│   └── clean_and_load.py
├── sql/
│   ├── create_database.sql
│   └── data_quality_checks.sql
├── .env.example
├── requirements.txt
└── README.md
```

## Quy tắc làm sạch

Python thực hiện:

- Chuẩn hóa tên cột và khoảng trắng trong dữ liệu text.
- Chuyển địa chỉ nhiều dòng thành một dòng.
- Chuyển đúng kiểu số và ngày giờ.
- Loại dòng thiếu dữ liệu, sai kiểu hoặc sai miền giá trị.
- Chỉ giữ `quantity > 0`, `price > 0` và discount từ 0 đến 100.
- Chỉ loại những giao dịch trùng hoàn toàn.
- Làm tròn dữ liệu tiền tệ về hai chữ số thập phân.
- Đối chiếu và tính lại `totalamount` từ quantity, price và discount.
- Rollback toàn bộ transaction SQL nếu quá trình load thất bại.

## Mô hình dữ liệu

### fact_retail

Bảng fact trung tâm lưu 100.000 giao dịch:

- `transaction_id`
- `customer_key`
- `product_key`
- `customerid`
- `productid`
- `quantity`
- `price`
- `discountapplied`
- `totalamount`
- `transactiondateonly`

### dim_customer

- `customer_key`
- `customerid`
- `paymentmethod`
- `storelocation`

### dim_product

- `product_key`
- `productid`
- `productcategory`

### dim_date

- `transactiondateonly`
- `transactionday`
- `transactionmonth`
- `transactionyear`

## Surrogate key và relationships

Trong dữ liệu nguồn, một `customerid` có thể đi cùng nhiều payment/location và
một `productid` có thể thuộc nhiều category. Vì vậy không sử dụng hai ID này làm
phía `1` của relationship.

`customer_key` và `product_key` được tạo cho từng tổ hợp thuộc tính duy nhất.
Relationships trong Power BI:

```text
dim_customer[customer_key]          1 → * fact_retail[customer_key]
dim_product[product_key]            1 → * fact_retail[product_key]
dim_date[transactiondateonly]       1 → * fact_retail[transactiondateonly]
```

Đặt `Cross-filter direction = Single` từ dimension sang fact. Không tạo
relationship bằng `customerid` hoặc `productid`.

## Cài đặt

Yêu cầu: Python 3.10+, SQL Server và ODBC driver dành cho SQL Server.

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Điền cấu hình SQL Server trong `.env`. Project hỗ trợ Windows Authentication
qua `SQL_TRUSTED_CONNECTION=yes` hoặc SQL Server Authentication bằng username
và password.

## Chạy pipeline

Chạy `sql/create_database.sql` trong SQL Server Management Studio trước. Script
này tạo lại bốn bảng nên dữ liệu hiện có trong các bảng sẽ bị thay thế.

Kiểm tra dữ liệu mà chưa load SQL Server:

```powershell
python python/clean_and_load.py --dry-run
```

Làm sạch và nạp dữ liệu:

```powershell
python python/clean_and_load.py
```

Chạy `sql/data_quality_checks.sql` để kiểm tra số dòng, duplicate, foreign key
và công thức `totalamount`.

## Kết nối Power BI

Chọn **Get Data → SQL Server** và nhập:

```text
Server: localhost
Database: retail_project
Authentication: Windows
Data connectivity mode: Import
```

Import bốn bảng `fact_retail`, `dim_customer`, `dim_product`, `dim_date`, sau đó
tạo relationships bằng surrogate key như mô tả ở trên.

Kết quả load đã kiểm tra:

| Bảng | Số dòng |
|---|---:|
| `fact_retail` | 100.000 |
| `dim_customer` | 100.000 |
| `dim_product` | 16 |
| `dim_date` | 366 |

Không có fact record bị mất liên kết với dimension.
