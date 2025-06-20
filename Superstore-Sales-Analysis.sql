CREATE TABLE superstore (
    row_id INTEGER,
    order_id VARCHAR(20),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(20),
    customer_id VARCHAR(10),
    customer_name VARCHAR(50),
    segment VARCHAR(20),
    country VARCHAR(30),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    region VARCHAR(10),
    product_id VARCHAR(20),
    category VARCHAR(20),
    sub_category VARCHAR(20),
    product_name VARCHAR(200),
    sales NUMERIC(10, 2),
    quantity INTEGER,
    discount NUMERIC(5, 2),
    profit NUMERIC(10, 4)
);


SELECT * FROM superstore;

--Advanced Sales Performance & Operational Insights on a Retail Superstore

--Phase 1 : Understand the Data

SELECT * FROM superstore
LIMIT 10;


--Counting total rows
SELECT COUNT(*) AS total_rows FROM superstore;

--Phase 2: Data Cleaning

---step 1: check missing data
SELECT 
    COUNT(*) FILTER (WHERE row_id IS NULL) AS null_row_id,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE order_date IS NULL) AS null_order_date,
    COUNT(*) FILTER (WHERE ship_date IS NULL) AS null_ship_date,
    COUNT(*) FILTER (WHERE ship_mode IS NULL) AS null_ship_mode,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_name IS NULL) AS null_customer_name,
    COUNT(*) FILTER (WHERE segment IS NULL) AS null_segment,
    COUNT(*) FILTER (WHERE country IS NULL) AS null_country,
    COUNT(*) FILTER (WHERE city IS NULL) AS null_city,
    COUNT(*) FILTER (WHERE state IS NULL) AS null_state,
    COUNT(*) FILTER (WHERE postal_code IS NULL) AS null_postal_code,
    COUNT(*) FILTER (WHERE region IS NULL) AS null_region,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE category IS NULL) AS null_category,
    COUNT(*) FILTER (WHERE sub_category IS NULL) AS null_sub_category,
    COUNT(*) FILTER (WHERE product_name IS NULL) AS null_product_name,
    COUNT(*) FILTER (WHERE sales IS NULL) AS null_sales,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS null_quantity,
    COUNT(*) FILTER (WHERE discount IS NULL) AS null_discount,
    COUNT(*) FILTER (WHERE profit IS NULL) AS null_profit
FROM superstore;

SELECT COUNT(*) 
FROM superstore
WHERE customer_name LIKE ' %' OR customer_name LIKE '% ';

---step 2: Check for Duplicates
SELECT row_id, COUNT(*) 
FROM superstore
GROUP BY row_id
HAVING COUNT(*) > 1;

SELECT order_id, product_id, COUNT(*)
FROM superstore
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

---Step 3: Check for Negative Values in sales, quantity, or profit
SELECT * 
FROM superstore
WHERE sales < 0 OR quantity < 0 OR profit < 0;

---step 4:We have to  ensure ship_date >= order_date
SELECT * 
FROM superstore
WHERE ship_date < order_date;

---STEP 5: We will Handle NULL Values step wise
SELECT * 
FROM superstore
WHERE row_id IS NULL 
   OR order_id IS NULL 
   OR order_date IS NULL 
   OR ship_date IS NULL 
   OR ship_mode IS NULL 
   OR customer_id IS NULL 
   OR customer_name IS NULL 
   OR segment IS NULL 
   OR country IS NULL 
   OR city IS NULL 
   OR state IS NULL 
   OR postal_code IS NULL 
   OR region IS NULL 
   OR product_id IS NULL 
   OR category IS NULL 
   OR sub_category IS NULL 
   OR product_name IS NULL 
   OR sales IS NULL 
   OR quantity IS NULL 
   OR discount IS NULL 
   OR profit IS NULL;

---STEP 6:We will trim Extra Spaces from Text Fields
UPDATE superstore
SET 
    customer_id = TRIM(customer_id),
    customer_name = TRIM(customer_name),
    segment = TRIM(segment),
    country = TRIM(country),
    city = TRIM(city),
    state = TRIM(state),
    region = TRIM(region),
    product_id = TRIM(product_id),
    category = TRIM(category),
    sub_category = TRIM(sub_category),
    product_name = TRIM(product_name),
    ship_mode = TRIM(ship_mode);

---step 7: Data Validation – Outliers & Logical Errors
---7.1-> we will check for future dates (sales,shipping in the future would be invalid)
SELECT * 
FROM superstore
WHERE order_date > CURRENT_DATE OR ship_date > CURRENT_DATE;

---7.2-> we will Check if ship_date is before order_date (it's illogical)
SELECT * 
FROM superstore
WHERE ship_date < order_date;

---7.3->we will Check if their any negative values in sales, quantity, discount, profit
SELECT * 
FROM superstore
WHERE sales < 0 OR quantity < 0 OR discount < 0 OR profit < 0;

--step 8:We will start data transformation from here
---8.1:we will extract Order Year, Order Month, Order Weekday
SELECT 
    order_id,
    order_date,
    EXTRACT(YEAR FROM order_date) AS order_year,
    TO_CHAR(order_date, 'Month') AS order_month,
    TO_CHAR(order_date, 'Day') AS order_weekday
FROM superstore
LIMIT 5;

---8.2:We will calculate Profit Margin
SELECT 
    order_id,
    sales,
    profit,
    ROUND((profit / NULLIF(sales, 0)) * 100, 2) AS profit_margin_percent
FROM superstore
LIMIT 5;

---8.3:We will create profit category here
SELECT 
    order_id,
    profit,
    CASE 
        WHEN profit > 100 THEN 'High Profit'
        WHEN profit BETWEEN 0 AND 100 THEN 'Low Profit'
        ELSE 'Loss'
    END AS profit_category
FROM superstore
LIMIT 5;

--step 9:We’ll now start answering business-style questions 
--and extract meaningful insights from the data.

---9.1:Top 5 customer by total_profit
WITH customer_profit AS (
    SELECT 
        customer_id,
        customer_name,
        SUM(profit) AS total_profit
    FROM superstore
    GROUP BY customer_id, customer_name
)
SELECT *
FROM customer_profit
ORDER BY total_profit DESC
LIMIT 5;


---9.2:yearly sales trend
SELECT 
    EXTRACT(YEAR FROM order_date) AS order_year,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM superstore
GROUP BY order_year
ORDER BY order_year;

---9.3:Rank products by sales in each category
SELECT 
    category,
    sub_category,
    product_name,
    SUM(sales) AS total_sales,
    RANK() OVER (PARTITION BY category ORDER BY SUM(sales) DESC) AS sales_rank
FROM superstore
GROUP BY category, sub_category, product_name
ORDER BY category, sales_rank;

---9.4:Repeated customers
SELECT 
    customer_id,
    customer_name,
    COUNT(DISTINCT order_id) AS total_orders
FROM superstore
GROUP BY customer_id, customer_name
HAVING COUNT(DISTINCT order_id) > 5
ORDER BY total_orders DESC;


--step 10:Hypothesis-Driven Business Analysis

--- Hypothesis 1:High discounts lead to lower profits
SELECT 
    ROUND(discount, 2) AS discount_rate,
    ROUND(AVG(profit), 2) AS avg_profit,
    COUNT(*) AS transactions
FROM superstore
GROUP BY ROUND(discount, 2)
ORDER BY discount_rate;


--- Hypothesis 2:Furniture has the lowest profit margin among all categories
SELECT 
    category,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_percent
FROM superstore
GROUP BY category
ORDER BY profit_margin_percent;


--- Hypothesis 3:Orders from the West region are the most profitable
SELECT 
    region,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(*) AS orders
FROM superstore
GROUP BY region
ORDER BY total_profit DESC;


---Hypothesis 4:The Consumer segment brings in the most revenue
SELECT 
    segment,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM superstore
GROUP BY segment
ORDER BY total_sales DESC;


--- Hypothesis 5:Most orders are shipped using Standard Class
SELECT 
    ship_mode,
    COUNT(*) AS total_orders,
    ROUND(SUM(sales), 2) AS total_sales
FROM superstore
GROUP BY ship_mode
ORDER BY total_orders DESC;


---Hypothesis 6: Sub-category 'Tables' causes the most loss
SELECT 
    sub_category,
    ROUND(SUM(profit), 2) AS total_profit
FROM superstore
GROUP BY sub_category
ORDER BY total_profit;


--step 11:We will artificially Normalize the Data (Create Multiple Tables)

---1. orders
CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(20),
    customer_id VARCHAR(10)
);

---Populate the  data into orders table
INSERT INTO orders (order_id, order_date, ship_date, ship_mode, customer_id)S
SELECT DISTINCT order_id, order_date, ship_date, ship_mode, customer_id
FROM superstore;

SELECT * FROM orders;

---2. customers
CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(50),
    segment VARCHAR(20),
    country VARCHAR(30),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    region VARCHAR(10)
);

---Populate the  data into customers table
SELECT customer_id, COUNT(*) AS count
FROM (
    SELECT DISTINCT customer_id, customer_name, segment, country, city, state, postal_code, region
    FROM superstore
) AS unique_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


INSERT INTO customers (customer_id, customer_name, segment, country, city, state, postal_code, region)
SELECT DISTINCT ON (customer_id)
       customer_id, customer_name, segment, country, city, state, postal_code, region
FROM superstore
ORDER BY customer_id, order_date DESC; 
---3. products
CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    category VARCHAR(20),
    sub_category VARCHAR(20),
    product_name VARCHAR(200)
);

---Populate the  data into products table
INSERT INTO products (product_id, category, sub_category, product_name)
SELECT DISTINCT ON (product_id)
       product_id, category, sub_category, product_name
FROM superstore
ORDER BY product_id;


---4. sales_facts
CREATE TABLE sales_facts (
    row_id INTEGER PRIMARY KEY,
    order_id VARCHAR(20),
    product_id VARCHAR(20),
    sales NUMERIC(10, 2),
    quantity INTEGER,
    discount NUMERIC(5, 2),
    profit NUMERIC(10, 4),
    FOREIGN KEY(order_id) REFERENCES orders(order_id),
    FOREIGN KEY(product_id) REFERENCES products(product_id)
);

---Populate the  data into sales_fact table
INSERT INTO sales_facts (row_id, order_id, product_id, sales, quantity, discount, profit)
SELECT row_id, order_id, product_id, sales, quantity, discount, profit
FROM superstore;


---checking if it's done
SELECT 'orders' AS table_name, COUNT(*) FROM orders
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sales_facts', COUNT(*) FROM sales_facts;


--Let's Recap
----Cleaned and validated the data
----Transformed and normalized it into a star schema (orders, customers, products, sales_facts)
----Loaded it successfully into PostgreSQL

--Now, it’s time to drive this project toward a business problem

---------------Project Problem Statement------------------

--“Optimizing Profitability and Operational Efficiency for an E-commerce Retailer”

---Based on the Superstore dataset, our goal is to identify where the company is losing money,
---how to optimize shipping and product strategies, 
---which customer segments to target to maximize profit and operational efficiency.

--Hypothesis 1
---"There are product sub-categories with consistently negative profit margins — these should be re-evaluated."

SELECT 
    p.sub_category,
    COUNT(sf.order_id) AS total_orders,
    SUM(sf.sales) AS total_sales,
    SUM(sf.profit) AS total_profit
FROM 
    sales_facts sf
JOIN 
    products p ON sf.product_id = p.product_id
GROUP BY 
    p.sub_category
HAVING 
    SUM(sf.profit) < 0
ORDER BY 
    total_profit ASC;

--Confirmed. Some sub-categories are causing losses despite high sales.

--Business insights
---Tables have generated over ₹2 lakh in sales but incurred ₹17,725 in losses — this is a major red flag.
---Bookcases and Supplies also show consistent losses despite decent sales volume.


-- Recommended Actions:
---Audit pricing strategies, supplier contracts, or shipping costs for these sub-categories.
---Consider removal or bundling to reduce isolated losses.
---These could be products with high return rates, or heavy shipping costs.


--Hyposthesis 2
---"Discounts improve profit margins."
---Do higher discounts actually lead to more profit? Or are we losing money by over-discounting?


--- Step-by-step Plan:
---1. We will group orders by discount range
---2.For each range,we will calculate: Average Sales,Average Profit,Total Orders
---3.We will view the relationship between Discount % and Profit

SELECT 
  CASE 
    WHEN discount = 0 THEN '0%'
    WHEN discount > 0 AND discount <= 0.1 THEN '0.1 - 0.1'
    WHEN discount > 0.1 AND discount <= 0.2 THEN '0.1 - 0.2'
    WHEN discount > 0.2 AND discount <= 0.3 THEN '0.2 - 0.3'
    WHEN discount > 0.3 AND discount <= 0.4 THEN '0.3 - 0.4'
    ELSE '>0.4'
  END AS discount_range,
  COUNT(*) AS total_orders,
  ROUND(AVG(sales), 2) AS avg_sales,
  ROUND(AVG(profit), 2) AS avg_profit,
  ROUND(SUM(profit), 2) AS total_profit
FROM sales_facts
GROUP BY discount_range
ORDER BY discount_range;


--Conclusion:
---0% to 20% discount ranges give positive average and total profit.
---Above 20%, the profit becomes negative, even though sales are higher.
---Especially >40% discount leads to heavy losses.


--Recommended Actions:
---Discounts beyond 20% do not improve profitability. They actually harm it.
---Controlled, small discounts can increase profit modestly.


-- Hypothesis 3:
---"High shipping delays negatively impact profit."
---We want to check whether orders with long delays (Ship Date - Order Date) result in lower or negative profit.


--Step-by-step approach:
---Step 1: We will calculate Shipping Delay in Days
SELECT 
    order_id,
    order_date,
    ship_date,
    profit,
    (ship_date - order_date) AS delay_days
FROM orders
JOIN sales_facts USING(order_id);

---Step 2:We will categorize delays into Bucket  and analyze impact
SELECT 
    CASE 
        WHEN ship_date - order_date = 0 THEN '0 Days'
        WHEN ship_date - order_date BETWEEN 1 AND 2 THEN '1-2 Days'
        WHEN ship_date - order_date BETWEEN 3 AND 4 THEN '3-4 Days'
        WHEN ship_date - order_date BETWEEN 5 AND 6 THEN '5-6 Days'
        ELSE '7+ Days'
    END AS delay_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(profit), 2) AS avg_profit,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
JOIN sales_facts USING(order_id)
GROUP BY delay_bucket
ORDER BY delay_bucket;

--Interpretation:
---No consistent negative impact with increased delay:
---Even 5–6 day delays maintain good average profit (₹27.29).
---3–4 days delay has the lowest avg profit, but not dramatically worse.
---7+ days still performs reasonably (₹32.74).

--Conclusion: Hypothesis 3 is rejected.
---Increased shipping delay does not clearly reduce profit. 
---In fact, profits are fairly stable across delay ranges.


-- Hypothesis 4:
---“The impact of discount on profit varies significantly across sub-categories..”


--Objective:
---To find which sub-categories are hurt or helped most by giving discounts.
---We will group data by sub-category and discount range, then analyze total sales, profit, and average profit per order.

SELECT
    sub_category,
    CASE 
        WHEN discount = 0 THEN '0%'
        WHEN discount > 0 AND discount <= 0.1 THEN '0-10%'
        WHEN discount > 0.1 AND discount <= 0.2 THEN '10-20%'
        WHEN discount > 0.2 AND discount <= 0.3 THEN '20-30%'
        WHEN discount > 0.3 AND discount <= 0.4 THEN '30-40%'
        WHEN discount > 0.4 THEN '>40%'
    END AS discount_range,
    COUNT(*) AS total_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit), 2) AS avg_profit_per_order
FROM sales_facts sf
JOIN products p ON sf.product_id = p.product_id
GROUP BY sub_category, discount_range
ORDER BY sub_category, discount_range;


--Conclusion:
---"The impact of discount on profit varies significantly across sub-categories."

--Sub-categories severely hurt by higher discounts:

--Interpretation:
---For these sub-categories, high discounts backfire.
---Likely due to low margins or high fixed costs → discounting shrinks or erases profitability.


--Sub-categories thriving even without discounts:

--Interpretation:
---These are premium items with higher profit margins.
---Selling at full price is still highly profitable.
---No need for aggressive discounting; strategy should focus on value-selling or bundling.


--Mixed Signals:
---Storage: Good profit at 0% (₹25,528.17), but negative at 10–20% (₹-4,249.35).
---Supplies: At 10–20%, profit goes negative despite moderate sales.
---Accessories: Healthy profit at 0%, but steep drop in avg. profit/order when discounting.



--Recommendation for Stakeholders:

---1.Avoid high discounts on:
-----Tables, Bookcases, Binders, Machines (especially >30%)
---2.Push full-price strategies for:
-----Copiers, Chairs, Phones, Machines
---3.Reassess discounting strategy by sub-category.
-----Dynamic discounting based on historical profitability.
---4.Explore bundles, subscriptions, or loyalty pricing for low-margin categories.



--Hypothesis 5: 
---"Some cities or regions generate high sales but are not profitable."
---Here we will identify high-revenue but low-margin or even loss-making geographies.

SELECT 
    c.city,
    c.state,
    c.region,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(sf.sales), 2) AS total_sales,
    ROUND(SUM(sf.profit), 2) AS total_profit,
    ROUND(SUM(sf.profit) / NULLIF(SUM(sf.sales), 0), 2) AS profit_margin
FROM 
    sales_facts sf
JOIN 
    orders o ON sf.order_id = o.order_id
JOIN 
    customers c ON o.customer_id = c.customer_id
GROUP BY 
    c.city, c.state, c.region
ORDER BY 
    total_sales DESC
LIMIT 50;


--Conclusion:
---Some cities generate high sales but are not profitable.

--These cities are either:
----1.Over-discounted
----2.Logistically inefficient
----3.Targeting wrong customer segments
----4.Prone to high return/refund rates



--Recommended Actions:
---For cities with negative profit (Monroe, Burlington, Santa Barbara, Springfield):
-----Audit discounting practices – Are we giving >40% discounts too often?
-----Inspect return rate – Are products getting returned too often?
-----Operational costs – Are delivery, warehousing or taxes eating margins?

---For cities with low margins (<5%) (Houston, Charlotte, Dublin):
-----Run campaign-specific margin audits
-----Bundle high-margin items with popular products
-----Consider price adjustments on best-sellers in those regions


--Conclusion: We failed to reject our hypothesis
----Yes, several cities are generating high sales but either low or negative profits.
----This needs further logistics, pricing, and promotion-level auditing to improve profitability in those hotspots.



--What We've Done So Far:
----1.Unprofitable Sub-Categories
----2.Impact of Discount on Profitability
----3.Impact of Shipping Time on Profit
----4.Sub-Category and Discount Relationship
----5.City-Level Profitability Insights







