# Data Source

This project uses 12 monthly sales transaction CSV files for the year 2025.
Raw files are not included in this repository due to size constraints.

## Schema

| Column | Type | Description |
|---|---|---|
| OrderID | STRING | Unique identifier for each order |
| CustomerID | STRING | Unique identifier for each customer |
| OrderDate | DATE | Date the order was placed |
| ProductType | STRING | Category or type of product ordered |
| OrderValue | FLOAT | Monetary value of the order |
