-- ---------------------------------
-- Retail_Data_Analysis_Project
-- ---------------------------------

-- This project uses the Superstore dataset.
-- Data is first imported into a raw table (superstore_raw)
-- Then dimension tables and fact tables are created.

-- Workflow
-- 1st Import CSV into superstore_raw
-- 2nd Data Exploration
-- 3rd Data Cleaning
-- 4th Create Dimension Tables
-- 5th Create Fact Table
-- 6th Create Relationships


-- ---------------------------------
-- Create Database
-- ---------------------------------

CREATE DATABASE retail_analysis;
USE retail_analysis;


-- ---------------------------------
-- Data Exploration
-- ---------------------------------

-- Check column names and data types
DESCRIBE superstore_raw;

-- Preview dataset
SELECT * 
FROM superstore_raw 
LIMIT 10;

-- Check total number of rows
SELECT COUNT(*) 
FROM superstore_raw;

-- Check NULL values
SELECT 
COUNT(*) - COUNT(`Order ID`) AS null_order_id,
COUNT(*) - COUNT(`Customer ID`) AS null_customer_id,
COUNT(*) - COUNT(`Product ID`) AS null_product_id,
COUNT(*) - COUNT(Sales) AS null_sales
FROM superstore_raw;



-- ---------------------------------
-- Data Cleaning
-- ---------------------------------

-- Rename column
ALTER TABLE superstore_raw
CHANGE `row id` row_id INT;



-- ------------------------------------------------
-- Create Dimension Tables
-- ------------------------------------------------


-- Customers Dimension
-- -------------------

CREATE TABLE customers AS
SELECT DISTINCT
    `Customer ID` AS customer_id,
    `Customer Name` AS customer_name,
    Segment
FROM superstore_raw;

-- Change datatype
ALTER TABLE customers
MODIFY customer_id VARCHAR(50);

-- Add Primary Key
ALTER TABLE customers
ADD PRIMARY KEY (customer_id);



-- Products Dimension
-- ------------------

-- DISTINCT doesn't remove duplicates because
-- the same product_id can have multiple product names

CREATE TABLE products AS
SELECT
    `Product ID` AS product_id,
    MAX(`Product Name`) AS product_name,
    MAX(Category) AS category,
    MAX(`Sub-Category`) AS sub_category
FROM superstore_raw
GROUP BY `Product ID`;

-- Change datatype
ALTER TABLE products
MODIFY product_id VARCHAR(50);

-- Add Primary Key
ALTER TABLE products
ADD PRIMARY KEY (product_id);



-- Locations Dimension
-- -------------------

CREATE TABLE locations AS
SELECT DISTINCT
    Country,
    City,
    State,
    Region,
    `Postal Code` AS postal_code
FROM superstore_raw;



-- ------------------------------------------------
-- Create Fact Table
-- ------------------------------------------------


-- Orders Fact Table
-- -----------------

CREATE TABLE orders AS
SELECT
    row_id,
    `Order ID` AS order_id,
    STR_TO_DATE(`Order Date`, '%m/%d/%Y') AS order_date,
    STR_TO_DATE(`Ship Date`, '%m/%d/%Y') AS ship_date,
    `Ship Mode` AS ship_mode,
    `Customer ID` AS customer_id,
    `Product ID` AS product_id,
    Sales,
    Quantity,
    Discount,
    Profit
FROM superstore_raw;



-- ------------------------------------------------
-- Add Additional Columns
-- ------------------------------------------------


-- Add region column
ALTER TABLE orders
ADD COLUMN region VARCHAR(50);

-- Populate region data
UPDATE orders o
JOIN superstore_raw s
ON o.row_id = s.row_id
SET o.region = s.Region;



-- ------------------------------------------------
-- Modify Data Types
-- ------------------------------------------------

ALTER TABLE orders
MODIFY order_id VARCHAR(50),
MODIFY customer_id VARCHAR(50),
MODIFY product_id VARCHAR(50);



-- ------------------------------------------------
-- Add Keys and Relationships
-- ------------------------------------------------


-- Add Primary Key to orders
ALTER TABLE orders
ADD PRIMARY KEY (row_id);


-- Add Foreign Keys

ALTER TABLE orders
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

ALTER TABLE orders
ADD CONSTRAINT fk_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);


-- ---------------------------------
-- End of Schema
-- ---------------------------------