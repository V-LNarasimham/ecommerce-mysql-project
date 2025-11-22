# Ecommerce SQL Project (MySQL)

## Overview
This is a beginner-to-medium level E-commerce database implemented in MySQL. It demonstrates designing schema, creating tables, relationships, inserting sample data, performing transactional order creation, and writing useful queries and views.

## Features
- Tables: categories, products, users, addresses, orders, order_items, reviews, payments
- Sample dataset for quick testing
- Transactional order creation with stock update and payment record
- Useful SELECT queries: joins, aggregates, subqueries
- A sample view for quick order summary

## How to run
1. Install MySQL (MySQL 8+ recommended) or use MySQL Workbench.
2. Open MySQL Workbench or CLI and change to the folder containing `database.sql`.
3. Run the script:
   - In MySQL Workbench: File → Open SQL Script → Run (Execute).
   - Or in terminal:
     ```bash
     mysql -u your_user -p < database.sql
     ```
4. Connect to the database and run sample queries:
   ```sql
   USE ecommerce_db;
   SELECT * FROM products;
   SELECT * FROM vw_order_summary;
   ```

## Author
Velidi Lakshmi Narasimham
