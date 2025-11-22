-- MySQL compatible (tested on MySQL 8+)
-- Run this file in MySQL Workbench / CLI: SOURCE database.sql; or paste sections one by one.

-- 1) Create database
DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

-- 2) Create tables
-- Categories
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(255)
);

-- Products
CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  stock INT DEFAULT 0,
  category_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Users / Customers
CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100),
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Addresses (one user can have many addresses)
CREATE TABLE addresses (
  address_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  street VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  zip VARCHAR(20),
  country VARCHAR(100) DEFAULT 'India',
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Orders
CREATE TABLE orders (
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(50) DEFAULT 'PLACED',
  total_amount DECIMAL(10,2) DEFAULT 0,
  shipping_address_id INT,
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id)
);

-- Order Items
CREATE TABLE order_items (
  order_item_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  price_each DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Reviews (optional)
CREATE TABLE reviews (
  review_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  user_id INT NOT NULL,
  rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Payments (simple)
CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_method VARCHAR(50),
  status VARCHAR(50) DEFAULT 'SUCCESS',
  paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- 3) Insert sample data (small dataset)
INSERT INTO categories (name, description) VALUES
('Mobiles', 'Smartphones and accessories'),
('Laptops', 'Laptop computers and accessories'),
('Home Appliances', 'Kitchen and home appliances');

INSERT INTO products (name, description, price, stock, category_id) VALUES
('SuperPhone X', '5.5 inch display, 64GB', 14999.00, 50, 1),
('BudgetPhone Z', '6.0 inch display, 32GB', 7999.00, 100, 1),
('WorkBook 14', 'Lightweight laptop, 8GB RAM', 35999.00, 30, 2),
('AirFry 3L', 'Electric air fryer', 4999.00, 20, 3);

INSERT INTO users (first_name, last_name, email, phone) VALUES
('Velidi', 'Narasimham', 'velidi@example.com', '9876543210'),
('Anita', 'Kumar', 'anita.k@example.com', '9123456780');

INSERT INTO addresses (user_id, street, city, state, zip, country) VALUES
(1, '12 MG Road', 'Hyderabad', 'Telangana', '500001', 'India'),
(2, '45 Green St', 'Bengaluru', 'Karnataka', '560001', 'India');

-- 4) Example transaction: place an order (basic)
-- We'll place an order for user 1: 1 x SuperPhone X and 2 x AirFry

START TRANSACTION;

INSERT INTO orders (user_id, status, shipping_address_id)
VALUES (1, 'PLACED', 1);

-- Get last inserted order id (MySQL session variable)
SET @order_id = LAST_INSERT_ID();

-- Add order items
INSERT INTO order_items (order_id, product_id, quantity, price_each)
VALUES
(@order_id, 1, 1, (SELECT price FROM products WHERE product_id = 1)),
(@order_id, 4, 2, (SELECT price FROM products WHERE product_id = 4));

-- Calculate total and update order
UPDATE orders
SET total_amount = (
  SELECT SUM(quantity * price_each) FROM order_items WHERE order_id = @order_id
)
WHERE order_id = @order_id;

-- Reduce stock (simple)
UPDATE products p
JOIN order_items oi ON p.product_id = oi.product_id
SET p.stock = p.stock - oi.quantity
WHERE oi.order_id = @order_id;

-- Record a payment
INSERT INTO payments (order_id, amount, payment_method, status)
VALUES (@order_id, (SELECT total_amount FROM orders WHERE order_id = @order_id), 'CARD', 'SUCCESS');

COMMIT;

-- 5) Sample SELECT queries (useful for demonstrating skills)

-- a) List all products with category name
SELECT p.product_id, p.name, p.price, p.stock, c.name AS category
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id;

-- b) Orders with user and total
SELECT o.order_id, CONCAT(u.first_name, ' ', u.last_name) AS customer, o.order_date, o.total_amount, o.status
FROM orders o
JOIN users u ON o.user_id = u.user_id
ORDER BY o.order_date DESC;

-- c) Order details (items) for a specific order
SELECT oi.order_item_id, p.name, oi.quantity, oi.price_each, (oi.quantity * oi.price_each) AS line_total
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE oi.order_id = @order_id;

-- d) Top-selling products (quantity)
SELECT p.product_id, p.name, SUM(oi.quantity) AS total_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.name
ORDER BY total_sold DESC;

-- e) Low stock products
SELECT product_id, name, stock FROM products WHERE stock <= 10;

-- f) Average rating per product (if reviews exist)
SELECT p.product_id, p.name, AVG(r.rating) AS avg_rating
FROM products p
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.name;

-- g) Example subquery: users who bought a specific product (product_id = 1)
SELECT DISTINCT u.user_id, u.first_name, u.email
FROM users u
JOIN orders o ON u.user_id = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.product_id = 1;

-- 6) Helpful views (optional)
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT o.order_id, o.order_date, CONCAT(u.first_name,' ',u.last_name) AS customer, o.total_amount, o.status
FROM orders o
JOIN users u ON o.user_id = u.user_id;

-- 7) Clean up (optional)
-- DROP VIEW IF EXISTS vw_order_summary;
-- DROP TABLE IF EXISTS order_items, orders, payments, reviews, addresses, users, products, categories;
