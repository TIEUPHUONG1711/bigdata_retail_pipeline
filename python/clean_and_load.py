"""Clean the raw retail CSV and load a SQL Server retail star schema."""

from __future__ import annotations

import argparse
import os
import re
from pathlib import Path

import pandas as pd
import pyodbc
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "data" / "Retail_Transaction_Dataset.csv"

COLUMN_NAMES = {
    "CustomerID": "customer_id",
    "ProductID": "product_id",
    "Quantity": "quantity",
    "Price": "price",
    "TransactionDate": "transaction_date",
    "PaymentMethod": "payment_method",
    "StoreLocation": "store_location",
    "ProductCategory": "product_category",
    "DiscountApplied(%)": "discount_applied",
    "TotalAmount": "source_total_amount",
}

TRANSACTION_COLUMNS = [
    "customer_id",
    "product_id",
    "quantity",
    "price",
    "transaction_date",
    "payment_method",
    "store_location",
    "product_category",
    "discount_applied",
    "total_amount",
]


def clean(raw: pd.DataFrame) -> tuple[pd.DataFrame, dict[str, int]]:
    """Return normalized rows and reconciliation statistics."""
    missing = set(COLUMN_NAMES) - set(raw.columns)
    if missing:
        raise ValueError(f"CSV is missing columns: {', '.join(sorted(missing))}")

    data = raw.rename(columns=COLUMN_NAMES)[list(COLUMN_NAMES.values())].copy()
    input_count = len(data)

    text_columns = [
        "customer_id",
        "product_id",
        "payment_method",
        "store_location",
        "product_category",
    ]
    for column in text_columns:
        data[column] = data[column].astype("string").str.strip()

    data["store_location"] = data["store_location"].map(
        lambda value: re.sub(r"\s+", " ", value).strip() if pd.notna(value) else value
    )

    for column in ["quantity", "price", "discount_applied", "source_total_amount"]:
        data[column] = pd.to_numeric(data[column], errors="coerce")

    data["transaction_date"] = pd.to_datetime(
        data["transaction_date"], format="%m/%d/%Y %H:%M", errors="coerce"
    )

    valid = (
        data[text_columns].notna().all(axis=1)
        & data[text_columns].ne("").all(axis=1)
        & data[["quantity", "price", "discount_applied", "transaction_date"]]
        .notna()
        .all(axis=1)
        & (data["quantity"] > 0)
        & (data["quantity"] % 1 == 0)
        & (data["price"] > 0)
        & data["discount_applied"].between(0, 100)
    )
    data = data.loc[valid].copy()
    data["quantity"] = data["quantity"].astype("int64")

    # Reconcile the source using its original precision before normalizing money.
    source_expected_total = (
        data["quantity"] * data["price"] * (1 - data["discount_applied"] / 100)
    )
    total_mismatch_count = int(
        (
            data["source_total_amount"].isna()
            | ((data["source_total_amount"] - source_expected_total).abs() > 0.01)
        ).sum()
    )

    # The loaded total is derived from the same rounded components stored in SQL.
    data["price"] = data["price"].round(2)
    data["discount_applied"] = data["discount_applied"].round(2)
    data["total_amount"] = (
        data["quantity"] * data["price"] * (1 - data["discount_applied"] / 100)
    ).round(2)

    before_deduplication = len(data)
    data = data.drop_duplicates(subset=TRANSACTION_COLUMNS, keep="first")
    rejected_count = input_count - before_deduplication
    duplicate_count = before_deduplication - len(data)
    stats = {
        "raw_rows": input_count,
        "clean_rows": len(data),
        "rejected_rows": rejected_count,
        "duplicate_rows": duplicate_count,
        "total_mismatch_rows": total_mismatch_count,
    }
    return data[TRANSACTION_COLUMNS], stats


def build_model(data: pd.DataFrame) -> dict[str, pd.DataFrame]:
    """Build the four tables required by the reporting model."""
    customers = (
        data[["customer_id", "payment_method", "store_location"]]
        .drop_duplicates()
        .sort_values(["customer_id", "payment_method", "store_location"])
        .reset_index(drop=True)
    )
    customers.insert(0, "customer_key", customers.index + 1)

    products = (
        data[["product_id", "product_category"]]
        .drop_duplicates()
        .sort_values(["product_id", "product_category"])
        .reset_index(drop=True)
    )
    products.insert(0, "product_key", products.index + 1)

    dates = pd.DataFrame({"transactiondateonly": data["transaction_date"].dt.date.unique()})
    dates = dates.sort_values("transactiondateonly").reset_index(drop=True)
    parsed_dates = pd.to_datetime(dates["transactiondateonly"])
    dates["transactionday"] = parsed_dates.dt.day
    dates["transactionmonth"] = parsed_dates.dt.month
    dates["transactionyear"] = parsed_dates.dt.year

    fact = data.merge(
        customers,
        on=["customer_id", "payment_method", "store_location"],
        how="left",
        validate="many_to_one",
    ).merge(
        products,
        on=["product_id", "product_category"],
        how="left",
        validate="many_to_one",
    )
    fact["transactiondateonly"] = fact["transaction_date"].dt.date
    fact = fact.rename(
        columns={
            "customer_id": "customerid",
            "product_id": "productid",
            "discount_applied": "discountapplied",
            "total_amount": "totalamount",
        }
    )
    fact = fact[
        [
            "customer_key",
            "product_key",
            "customerid",
            "productid",
            "quantity",
            "price",
            "discountapplied",
            "totalamount",
            "transactiondateonly",
        ]
    ]

    return {
        "dim_customer": customers.rename(
            columns={
                "customer_id": "customerid",
                "payment_method": "paymentmethod",
                "store_location": "storelocation",
            }
        ),
        "dim_product": products.rename(
            columns={"product_id": "productid", "product_category": "productcategory"}
        ),
        "dim_date": dates,
        "fact_retail": fact,
    }


def connection_string() -> str:
    required = ["SQL_SERVER", "SQL_DATABASE"]
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        raise RuntimeError(f"Missing environment variables: {', '.join(missing)}")

    driver = os.getenv("SQL_DRIVER", "ODBC Driver 18 for SQL Server")
    trust = os.getenv("SQL_TRUST_CERTIFICATE", "yes")
    port = os.getenv("SQL_PORT", "").strip()
    server = os.environ["SQL_SERVER"]
    server_address = f"{server},{port}" if port else server
    base = (
        f"DRIVER={{{driver}}};SERVER={server_address};"
        f"DATABASE={os.environ['SQL_DATABASE']};TrustServerCertificate={trust};"
    )
    if os.getenv("SQL_TRUSTED_CONNECTION", "no").lower() in {"yes", "true", "1"}:
        return base + "Trusted_Connection=yes"

    credentials = ["SQL_USERNAME", "SQL_PASSWORD"]
    missing_credentials = [name for name in credentials if not os.getenv(name)]
    if missing_credentials:
        raise RuntimeError(
            f"Missing environment variables: {', '.join(missing_credentials)}"
        )
    return base + (
        f"UID={os.environ['SQL_USERNAME']};PWD={os.environ['SQL_PASSWORD']};Encrypt=yes"
    )


def insert_frame(cursor: pyodbc.Cursor, table: str, data: pd.DataFrame) -> None:
    columns = ", ".join(data.columns)
    placeholders = ", ".join("?" for _ in data.columns)
    sql = f"INSERT INTO dbo.{table} ({columns}) VALUES ({placeholders})"
    cursor.fast_executemany = True
    cursor.executemany(sql, list(data.itertuples(index=False, name=None)))


def replace_model(model: dict[str, pd.DataFrame]) -> None:
    with pyodbc.connect(connection_string(), autocommit=False) as connection:
        cursor = connection.cursor()
        cursor.execute("DELETE FROM dbo.fact_retail")
        cursor.execute("DELETE FROM dbo.dim_customer")
        cursor.execute("DELETE FROM dbo.dim_product")
        cursor.execute("DELETE FROM dbo.dim_date")
        insert_frame(cursor, "dim_customer", model["dim_customer"])
        insert_frame(cursor, "dim_product", model["dim_product"])
        insert_frame(cursor, "dim_date", model["dim_date"])
        insert_frame(cursor, "fact_retail", model["fact_retail"])
        connection.commit()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument(
        "--dry-run", action="store_true", help="Clean and report without loading SQL Server"
    )
    args = parser.parse_args()

    load_dotenv(ROOT / ".env")
    raw = pd.read_csv(args.input, dtype={"CustomerID": "string", "ProductID": "string"})
    cleaned, stats = clean(raw)
    model = build_model(cleaned)
    print(f"Raw rows: {stats['raw_rows']:,}")
    print(f"Clean rows: {stats['clean_rows']:,}")
    print(f"Rejected rows: {stats['rejected_rows']:,}")
    print(f"Duplicate rows: {stats['duplicate_rows']:,}")
    print(f"Source total mismatches: {stats['total_mismatch_rows']:,}")
    for table, frame in model.items():
        print(f"{table}: {len(frame):,} rows")

    if not args.dry_run:
        replace_model(model)
        print("Loaded dim_customer, dim_product, dim_date and fact_retail")


if __name__ == "__main__":
    main()
