-- ---------------------------------
-- Retail_Data_Analysis_Project
-- ---------------------------------
-- Analytical SQL queries for revenue,
-- profitability, customer behavior,
-- and regional performance.


-- ------------------------------------------------
-- Database Validation
-- ------------------------------------------------

SHOW DATABASES;

USE retail_analysis;

SHOW TABLES;

SELECT * FROM orders;



-- ------------------------------------------------
-- Key Business KPIs
-- ------------------------------------------------

-- calculate kpi's

SELECT 
    ROUND(SUM(Sales),2) AS total_revenue,
    ROUND(SUM(Profit),2) AS total_profit,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS profit_margin_pct
FROM orders;



-- ------------------------------------------------
-- Time-Based Revenue Analysis
-- ------------------------------------------------

-- yearly revenue trends

SELECT 
    YEAR(order_date) AS order_year,
    ROUND(SUM(Sales),2) AS yearly_revenue
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year;



-- monthly revenue trends

SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    ROUND(SUM(Sales),2) AS monthly_sales
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;



-- ------------------------------------------------
-- Regional Performance
-- ------------------------------------------------

-- region-wise revenue

SELECT 
    s.Region,
    ROUND(SUM(o.Sales),2) AS revenue
FROM orders o
JOIN superstore_raw s 
    ON o.row_id = s.Row_ID
GROUP BY s.Region
ORDER BY revenue DESC;



-- region wise sales

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



-- ------------------------------------------------
-- Customer Analysis
-- ------------------------------------------------

-- customer revenue rank

SELECT 
    customer_id,
    ROUND(SUM(Sales),2) AS customer_revenue,
    RANK() OVER (ORDER BY SUM(Sales) DESC) AS revenue_rank
FROM orders
GROUP BY customer_id
ORDER BY revenue_rank
LIMIT 10;



-- customer revenue contribution

WITH customer_revenue AS(
SELECT customer_id,
       SUM(sales) AS total_revenue
FROM orders
GROUP BY customer_id
)

SELECT customer_id,
       ROUND(total_revenue,2) AS total_revenue,
       ROUND(total_revenue/SUM(total_revenue) OVER()*100,2) AS contribution_pct
FROM customer_revenue
ORDER BY total_revenue DESC
LIMIT 5;



-- top 20% customer contributions

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

SELECT 
    COUNT(*) AS top_customer_count,
    ROUND(SUM(total_revenue),2) AS total_revenue,
    ROUND(
        SUM(total_revenue) /
        (SELECT SUM(Sales) FROM orders) * 100,
        2
    ) AS contribution_pct
FROM ranked_customers
WHERE revenue_rank <= total_customers * 0.2;



-- Customer Lifetime Revenue

SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS total_order,
    ROUND(SUM(sales),2) AS lifetime_revenue
FROM orders
GROUP BY customer_id
ORDER BY lifetime_revenue DESC;



-- ------------------------------------------------
-- Customer Segmentation Analysis
-- ------------------------------------------------

-- Revenue vs Profit Segmentation

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



-- ------------------------------------------------
-- Product Performance Analysis
-- ------------------------------------------------

-- category level profitability

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



-- sub-category wise profitability

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



-- profit ranking by category

SELECT 
    category,
    total_profit,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT 
        p.category,
        ROUND(SUM(o.Profit),2) AS total_profit
    FROM orders o
    JOIN products p 
        ON o.product_id = p.product_id
    GROUP BY p.category
) t;



-- ------------------------------------------------
-- Discount Analysis
-- ------------------------------------------------

-- check discount impact

SELECT 
    ROUND(discount,2) AS discount_level,
    ROUND(AVG(Profit),2) AS avg_profit,
    COUNT(*) AS transaction_count
FROM orders
GROUP BY discount_level
ORDER BY discount_level;



-- avg discount of category

SELECT 
    p.category,
    ROUND(AVG(o.discount),2) AS avg_discount
FROM orders o
JOIN products p
    ON o.product_id = p.product_id
GROUP BY p.category;



-- ------------------------------------------------
-- Growth & Variance Analysis
-- ------------------------------------------------

-- yearly performance

SELECT 
    YEAR(order_date) AS order_year,
    ROUND(SUM(Sales),2) AS yearly_sales,
    ROUND(SUM(Profit),2) AS yearly_profit,
    ROUND((SUM(Profit)/SUM(Sales))*100,2) AS margin_pct
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year;



-- month over month growth

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



-- running total

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



-- variance analysis

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



-- ------------------------------------------------
-- Risk Analysis
-- ------------------------------------------------

-- Detect Negative Margin Transactions

SELECT 
    COUNT(*) AS loss_transactions,
    ROUND(SUM(Sales),2) AS loss_revenue,
    ROUND(SUM(Profit),2) AS total_loss
FROM orders
WHERE Profit < 0;



-- ------------------------------------------------
-- Regional Ranking
-- ------------------------------------------------

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

SELECT 
    region,
    ROUND(total_sales,2) AS total_sales,
    ROUND(total_profit,2) AS total_profit,
    ROUND((total_profit/total_sales)*100,2) AS margin_pct,
    RANK() OVER(ORDER BY total_profit DESC) AS profit_rank
FROM region_performance;



-- sub-category contribution in each region

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



-- ------------------------------------------------
-- Target vs Actual Sales
-- ------------------------------------------------

WITH yearly_data AS (
SELECT
    YEAR(order_date) AS order_year,
    SUM(sales) AS yearly_sales
FROM orders
GROUP BY YEAR(order_date)
)

SELECT 
    order_year,
    ROUND(yearly_sales,2) AS actual_sales,
    ROUND(LAG(yearly_sales) OVER(ORDER BY order_year) *1.10,2) AS target_sales,
    ROUND(
        yearly_sales - 
        (LAG(yearly_sales) OVER (ORDER BY order_year) * 1.10),
        2
    ) AS variance
FROM yearly_data;



-- ------------------------------------------------
-- Region Revenue & Profit Ranking
-- ------------------------------------------------

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


-- ---------------------------------
-- End of Analysis Queries
-- ---------------------------------