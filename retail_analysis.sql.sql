# create new database and import csv file

CREATE DATABASE retail_analysis;
USE retail_analysis;

# check columns and datatype of each columns
DESCRIBE superstore_raw;

# check dataset
SELECT * FROM superstore_raw LIMIT 10;

# check total no. of columns
SELECT COUNT(*) FROM superstore_raw;

# check null values
SELECT 
COUNT(*) - COUNT(`Order ID`) AS null_order_id,
COUNT(*) - COUNT(`Customer ID`) AS null_customer_id,
COUNT(*) - COUNT(`Product ID`) AS null_product_id,
COUNT(*) - COUNT(Sales) AS null_sales
FROM superstore_raw;


# alter superstore_raw table
alter table superstore_raw
change `row id` row_id  int;

# create customer dimansion table from raw data

CREATE TABLE customers AS
SELECT DISTINCT
    `Customer ID` AS customer_id,
    `Customer Name` AS customer_name,
    Segment
FROM superstore_raw;

# change datatype of customer_id
alter table customers 
modify customer_id varchar(50);

# add customer_id as a primary key
alter table customers
add primary key (customer_id);



# create product dimansion table from raw data

/* CREATE TABLE products AS
SELECT DISTINCT
    `Product ID` AS product_id,
    `Product Name` AS product_name,
    Category,
    `Sub-Category` AS sub_category
FROM superstore_raw;*/    

# by this technic duplicate not remove because same product id have 2 or more product name 


# another way of creating product dim table

CREATE TABLE products AS
SELECT
    `Product ID` AS product_id,
    MAX(`Product Name`) AS product_name,
    MAX(Category) AS category,
    MAX(`Sub-Category`) AS sub_category
FROM superstore_raw
GROUP BY `Product ID`;


# change datatype of product id
alter table products
modify product_id varchar(50);


# add product _id as a primary key
alter table products
add primary key (product_id);


# create location dimansion table from raw data
create table locations as
select distinct
	country,
    city,
    state,
    region,
    `postal code` as postal_code
    from superstore_raw;

     
     


#create order fact table from raw dataset

CREATE TABLE orders AS
SELECT
	`Row ID` AS row_id,
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




# add region column and add data in it

ALTER TABLE orders
ADD COLUMN region VARCHAR(50);

UPDATE orders o
JOIN superstore_raw s
    ON o.row_id = s.row_id
SET o.region = s.Region;





# change datatype of order_id ,product_id and customer_id of orders tables

alter table orders
	modify order_id varchar(50),
    MODIFY customer_id VARCHAR(50),
    modify product_id varchar(50);
        
        
# add primary key in orders table

ALTER TABLE orders
ADD PRIMARY KEY (row_id);


# Add Primary Key to Dimension Tables
alter table customers
add primary key (customer_id);


# add foreign key in order table

ALTER TABLE orders
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

ALTER TABLE orders
ADD CONSTRAINT fk_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);








# calculate kpi's

SELECT 
    ROUND(SUM(Sales),2) AS total_revenue,
    ROUND(SUM(Profit),2) AS total_profit,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS profit_margin_pct
FROM orders;


# yearly revenue trends

SELECT 
    YEAR(order_date) AS order_year,
    ROUND(SUM(Sales),2) AS yearly_revenue
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year;


# region-wise revenue
SELECT 
    s.Region,
    ROUND(SUM(o.Sales),2) AS revenue
FROM orders o
JOIN superstore_raw s 
    ON o.row_id = s.Row_ID
GROUP BY s.Region
ORDER BY revenue DESC;


# customer revenue rank
SELECT 
    customer_id,
    ROUND(SUM(Sales),2) AS customer_revenue,
    RANK() OVER (ORDER BY SUM(Sales) DESC) AS revenue_rank
FROM orders
GROUP BY customer_id
ORDER BY revenue_rank
LIMIT 10;



with customer_revenue as(
select customer_id,
	  sum(sales) as total_revenue
      from orders
      group by customer_id
      )
      
select customer_id,
	  round(total_revenue,2) as total_revenue,
      round(total_revenue/sum(total_revenue) over()*100,2) as contribution_pct
      from customer_revenue
      order by total_revenue desc
      limit 5;


# category level profitablity

SELECT 
    p.category,
    ROUND(SUM(o.Sales),2) AS total_sales,
    ROUND(SUM(o.Profit),2) AS total_profit,
    ROUND((SUM(o.Profit)/SUM(o.Sales))*100,2) AS margin_pct
FROM orders o
JOIN products p 
    ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY margin_pct DESC;



# sub-category wise profitablity

SELECT 
    p.sub_category,
    ROUND(SUM(o.Sales),2) AS total_sales,
    ROUND(SUM(o.Profit),2) AS total_profit,
    ROUND((SUM(o.Profit)/SUM(o.Sales))*100,2) AS margin_pct
FROM orders o
JOIN products p 
    ON o.product_id = p.product_id
GROUP BY p.sub_category
ORDER BY margin_pct ASC
LIMIT 5;


# check discount impact 
SELECT 
    ROUND(discount,2) AS discount_level,
    ROUND(AVG(Profit),2) AS avg_profit,
    COUNT(*) AS transaction_count
FROM orders
GROUP BY discount_level
ORDER BY discount_level;


# profit ranking by category

SELECT 
    category,
    total_profit,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT 
        p.category,
        round(SUM(o.Profit),2) AS total_profit
    FROM orders o
    JOIN products p 
        ON o.product_id = p.product_id
    GROUP BY p.category
) t;


# avg discount of category
SELECT 
    p.category,
    ROUND(AVG(o.discount),2) AS avg_discount
FROM orders o
JOIN products p
    ON o.product_id = p.product_id
GROUP BY p.category;

# check yearly revenue increment
SELECT 
    YEAR(order_date) AS order_year,
    ROUND(SUM(Sales),2) AS yearly_sales,
    ROUND(SUM(Profit),2) AS yearly_profit,
    ROUND((SUM(Profit)/SUM(Sales))*100,2) AS margin_pct
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year;




# monthly revenue trends
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    ROUND(SUM(Sales),2) AS monthly_sales
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;


# month over month growth

WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,
        SUM(Sales) AS monthly_sales
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)

SELECT 
    order_month,
    ROUND(monthly_sales,2) AS monthly_sales,
    ROUND(
        (monthly_sales - LAG(monthly_sales) OVER (ORDER BY order_month))
        / LAG(monthly_sales) OVER (ORDER BY order_month) * 100,
        2
    ) AS mom_growth_pct
FROM monthly_revenue;



# running total
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    ROUND(SUM(Sales),2) AS monthly_sales,
    ROUND(
        SUM(SUM(Sales)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')),
        2
    ) AS running_total
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;



# region wise sales
SELECT 
    s.Region,
    ROUND(SUM(o.Sales),2) AS region_sales,
    ROUND(
        SUM(o.Sales) / SUM(SUM(o.Sales)) OVER() * 100,
        2
    ) AS contribution_pct
FROM orders o
JOIN superstore_raw s 
    ON o.row_id = s.Row_ID
GROUP BY s.Region
ORDER BY region_sales DESC;



# variance analyics

WITH yearly_data AS (
    SELECT 
        YEAR(order_date) AS order_year,
        SUM(Sales) AS yearly_sales
    FROM orders
    GROUP BY YEAR(order_date)
)

SELECT 
    order_year,
    ROUND(yearly_sales,2) AS yearly_sales,
    ROUND(
        yearly_sales - LAG(yearly_sales) OVER (ORDER BY order_year),
        2
    ) AS absolute_variance,
    ROUND(
        (yearly_sales - LAG(yearly_sales) OVER (ORDER BY order_year))
        / LAG(yearly_sales) OVER (ORDER BY order_year) * 100,
        2
    ) AS yoy_growth_pct
FROM yearly_data
ORDER BY order_year;





#  top 20% customer contributions

WITH customer_revenue AS (
    SELECT 
        customer_id,
        SUM(Sales) AS total_revenue
    FROM orders
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT 
        customer_id,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        COUNT(*) OVER () AS total_customers
    FROM customer_revenue
    )
    select 
		count(*) as top_customer_count,
        round(sum(total_revenue),2) as total_revenue,
		round(
        SUM(total_revenue) /
        (SELECT SUM(Sales) FROM orders) * 100,
        2
    ) AS contribution_pct
        from ranked_customers
        WHERE revenue_rank <= total_customers * 0.2;
        
        
        
# Revenue vs Profit Segmentation

WITH customer_metrics AS (
    SELECT 
        customer_id,
        SUM(Sales) AS total_revenue,
        SUM(Profit) AS total_profit
    FROM orders
    GROUP BY customer_id
)

SELECT 
    CASE 
        WHEN total_revenue >= 
             (SELECT AVG(total_revenue) FROM customer_metrics)
         AND total_profit >= 
             (SELECT AVG(total_profit) FROM customer_metrics)
        THEN 'High Revenue - High Profit'

        WHEN total_revenue >= 
             (SELECT AVG(total_revenue) FROM customer_metrics)
         AND total_profit < 
             (SELECT AVG(total_profit) FROM customer_metrics)
        THEN 'High Revenue - Low Profit'

        WHEN total_revenue < 
             (SELECT AVG(total_revenue) FROM customer_metrics)
         AND total_profit >= 
             (SELECT AVG(total_profit) FROM customer_metrics)
        THEN 'Low Revenue - High Profit'

        ELSE 'Low Revenue - Low Profit'
    END AS customer_segment,
    COUNT(*) AS customer_count
FROM customer_metrics
GROUP BY customer_segment;



# Detect Negative Margin Transactions

SELECT 
    COUNT(*) AS loss_transactions,
    ROUND(SUM(Sales),2) AS loss_revenue,
    ROUND(SUM(Profit),2) AS total_loss
FROM orders
WHERE Profit < 0;



# Customer Lifetime Revenue

select
	customer_id,
    count(distinct order_id) as total_order,
    round(sum(sales),2) as lifetime_revenue
from orders
group by customer_id
order by lifetime_revenue desc;




    

# Store-Level Ranking

WITH region_performance AS (
    SELECT 
        s.Region,
        SUM(o.Sales) AS total_sales,
        SUM(o.Profit) AS total_profit
    FROM orders o
    JOIN superstore_raw s
        ON o.row_id = s.`row_id`
    GROUP BY s.Region
)
select 
	region,
	round(total_sales,2) as total_sales,
    round(total_profit,2) as total_profit,
    round((total_profit/total_sales)*100,2) as margin_pct,
    rank() over(order by total_profit desc) as profit_rank
from region_performance;


# sub-category contribution in each region

WITH subcat_region AS (
    SELECT 
        s.Region,
        p.sub_category,
        SUM(o.Sales) AS total_sales
    FROM orders o
    JOIN products p 
        ON o.product_id = p.product_id
    JOIN superstore_raw s
        ON o.row_id = s.`row_id`
    GROUP BY s.Region, p.sub_category
)

SELECT 
    Region,
    sub_category,
    ROUND(total_sales,2) AS total_sales,
    ROUND(
        total_sales /
        SUM(total_sales) OVER (PARTITION BY Region) * 100,
        2
    ) AS region_contribution_pct
FROM subcat_region
ORDER BY Region, region_contribution_pct DESC;



# target vs actual 
with yearly_data as (
	select
		year(order_date) as order_year,
		sum(sales) as yearly_sales
	from orders
	group by year(order_date)
	)
select order_year,
	round(yearly_sales,2) as actual_sales,
    round( lag(yearly_sales) over(order by order_year) *1.10,2) as target_sales,
    ROUND(
        yearly_sales - 
        (LAG(yearly_sales) OVER (ORDER BY order_year) * 1.10),
        2
    ) AS variance
FROM yearly_data;



WITH region_metrics AS (
    SELECT 
        s.Region,
        SUM(o.Sales) AS total_sales,
        SUM(o.Profit) AS total_profit
    FROM orders o
    JOIN superstore_raw s
        ON o.row_id = s.`row_id`
    GROUP BY s.Region
)

SELECT 
    Region,
    ROUND(total_sales,2) AS total_sales,
    ROUND(total_profit,2) AS total_profit,
    ROUND((total_profit/total_sales)*100,2) AS margin_pct,
    RANK() OVER (ORDER BY total_sales DESC) AS revenue_rank,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM region_metrics;




SHOW DATABASES;
USE retail_analysis;
SHOW TABLES;


select * from orders;
