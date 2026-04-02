USE Olist;
DROP TABLE IF EXISTS #MoM_performance;

-- Q1: How are orders, revenue, and average order value trending over time?

-- 1.1 order count MoM
WITH order_count AS (
    SELECT
    DATETRUNC(month, order_purchase_timestamp) AS month_year,
    COUNT(*) AS total_orders
FROM orders
WHERE LOWER(order_status) = 'delivered'
GROUP BY DATETRUNC(month, order_purchase_timestamp)
),

order_value AS (
    SELECT 
    o.order_purchase_timestamp,
    SUM(p.payment_value) AS order_value
FROM orders o
INNER JOIN order_payments p  
ON o.order_id = p.order_id  
WHERE LOWER(o.order_status) = 'delivered'
GROUP BY o.order_id, o.order_purchase_timestamp 
), 

-- 1.2 revenue MoM
total_revenue AS (
SELECT
    DATETRUNC(month, order_purchase_timestamp) AS month_year,
    SUM(order_value) AS month_revenue
FROM order_value
GROUP BY DATETRUNC(month, order_purchase_timestamp)
),

-- 1.3 average order value MoM
avg_order_value AS (

SELECT
    DATETRUNC(month, order_purchase_timestamp) AS month_year,
    AVG(order_value) AS month_average_order_value
FROM order_value v
GROUP BY DATETRUNC(month, order_purchase_timestamp)
)

SELECT
    r.month_year,
    c.total_orders,
    month_revenue,
    month_average_order_value
INTO #MoM_performance 
FROM total_revenue r  
INNER JOIN avg_order_value a
ON r.month_year = a.month_year
INNER JOIN order_count c  
ON r.month_year = c.month_year
ORDER BY r.month_year;

SELECT * FROM #MoM_performance
ORDER BY month_year;

-- analysis:
--== Total orders ==--
-- Total monthly orders has a clear uptrend over time.
-- From the beginning of late 2016 to late 2017, the pattern is on a stable uptrend with only a few small corrections. However, the number of orders became more variable with ups and downs within a noticeable range from early 2018 onwards
-- There were a few strong sudden rise, most notably was the one from Oct 2017 -> Nov 2017 with around ~70% MoM increase in total orders. But following month from Nov 2017 -> Dec 2017 has a noticeable dip, cutting the from Oct was cut by half.
-- This suggest strong growth of order numbers from Olist in the first year, however it started to slowed down and consolidating in the later half

--== Montly Revenue ==--
-- Monthly Revenue followed an almost mirrored image of the total orders pattern above.

--== Average Order Value ==--
-- Average order value stays relatively flat over time
-- The pattern is mostly stable over time, with occasional slight decrease MoM but quickly returns to the baseline
-- There is one very sharp dip in Dec 2016, which has exactly 1 order, so it's not repsentative of the broader pattern. For the other parts, the average value stays very stable within a narrow band around 150 - 180 mark

-- Overall observation: with average order value stays relatively the same, and revenue and order numbers increase almost at a 1:1 ratio, we can conclude that Olist revenue increase mostly comes from more orders, not bigger transaction size per orders.

-- Q2. Strongest and weakest performing months by revenue
-- SELECT TOP 5 *
-- FROM #MoM_performance
-- ORDER BY month_revenue DESC

-- SELECT TOP 5 *
-- FROM #MoM_performance
-- ORDER BY month_revenue ASC;

-- top 5 strongest performing months consist of the peak in Nov 2017 discussed previously, and the 4 months within early 2018, which are all in the later period of the dataset

-- top 5 worst performing months are on the early stage of the dataset, which is in late 2016 and early 2017

-- December 2016 is the lowest extreme point, which as discussed contained only 1 order, so it should be interpreted cautiously

-- 3. How much of total business for every month comes from new customers versus repeat customers?



WITH order_value AS (
    SELECT 
        o.order_id, 
        o.customer_id,
        o.order_purchase_timestamp,
        SUM(p.payment_value) AS total_value
    FROM orders o 
    INNER JOIN order_payments p  
    ON o.order_id = p.order_id
    GROUP BY o.order_id,
             o.customer_id, 
             order_purchase_timestamp
), 
customer_month_purchase AS (
SELECT DISTINCT
    customer_unique_id,
    DATETRUNC(month, order_purchase_timestamp) AS month_day,
    COUNT(*) OVER (PARTITION BY DATETRUNC(month, order_purchase_timestamp), customer_unique_id) AS total_orders,
    SUM(total_value) OVER (PARTITION BY DATETRUNC(month, order_purchase_timestamp), customer_unique_id) AS total_spent
FROM order_value ov 
INNER JOIN customers c  
ON ov.customer_id = c.customer_id
),
repeating_customers AS (
    SELECT
        *
    FROM customer_month_purchase cm
    WHERE EXISTS (SELECT 1 FROM customer_month_purchase WHERE customer_unique_id = cm.customer_unique_id
    AND month_day < cm.month_day)
)
SELECT 
    m.month_year,
    COALESCE(proportion_repeating_customers, 0) AS proportion_repeating_customers,
    COALESCE(repeating_customers_total_orders_contribution, 0) AS repeating_customers_total_orders_contribution,
    COALESCE(repeating_customers_total_revenue_contribution, 0) AS repeating_customers_total_revenue_contribution
 FROM #MoM_performance m 
LEFT JOIN
(
SELECT
    month_day,
    ROUND(CAST(
        COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM customer_month_purchase WHERE month_day = r.month_day) ,  5) 
        AS proportion_repeating_customers,
    
    ROUND(CAST(SUM(total_orders) AS FLOAT)/ (SELECT SUM(total_orders) FROM customer_month_purchase WHERE month_day = r.month_day), 5) AS repeating_customers_total_orders_contribution,

    ROUND(CAST(SUM(total_spent) AS FLOAT) / (SELECT SUM(total_spent) FROM customer_month_purchase WHERE month_day = r.month_day), 5) AS repeating_customers_total_revenue_contribution
FROM repeating_customers r
GROUP BY month_day) t
ON m.month_year = t.month_day

-- Proportion of purchases from new customers makes up the majority of shares across most periods
-- Repeating customers proportion does gain slight increase over time from Feb 2017 -> Aug 2018 but stayed < 3% during those period, while new customers still take the overwhemingly majority
-- However, an interesting shift happened in Sep 2018 where repeating customer proportion suddenly skyrockected to above 64%, then the following month (Oct 2018), repeating customers' purchases went to 75%\

-- How concentrated is total revenue across customers, sellers, and products?
DROP TABLE IF EXISTS #revenue_concentration_summary;

WITH customer_revenue AS (
    SELECT 
        SUM(payment_value) AS total,
        SUM(SUM(payment_value)) OVER () AS total_rev,
        CUME_DIST() OVER (ORDER BY SUM(payment_value) DESC) AS percentile 
    FROM customers c  
    INNER JOIN orders o  
        ON c.customer_id = o.customer_id
    INNER JOIN order_payments p  
        ON o.order_id = p.order_id
    WHERE LOWER(o.order_status) = 'delivered'
    GROUP BY c.customer_unique_id
),
top_5 AS (
    SELECT
        SUM(total) AS top_5_total,
        SUM(total) / MAX(total_rev) AS top_5_prop
    FROM customer_revenue
    WHERE percentile <= 0.05
),
top_10 AS (
    SELECT
        SUM(total) AS top_10_total,
        SUM(total) / MAX(total_rev) AS top_10_prop
    FROM customer_revenue
    WHERE percentile <= 0.10
),
top_20 AS (
    SELECT
        SUM(total) AS top_20_total,
        SUM(total) / MAX(total_rev) AS top_20_prop
    FROM customer_revenue
    WHERE percentile <= 0.20
)
SELECT
    'Customers' AS entity_type,
    top_5_total,
    top_5_prop,
    top_10_total,
    top_10_prop,
    top_20_total,
    top_20_prop
INTO #revenue_concentration_summary
FROM top_5
CROSS JOIN top_10
CROSS JOIN top_20;

-- top 5% of customers contribute to 26.8% of GMV
-- top 10% of customers contribute to 38.25% of GMV
-- top 20% of customers contribute to 53.5% of GMV
-- Overall, GMV is moderaly concentrated, with 20% of customers generating over half the revenue, suggesting customer revenue is not evenly distributed, with higher value customers contributing a higher share.

WITH sellers_revenue AS (
    SELECT
        SUM(price + freight_value) AS total,
        SUM(SUM(price + freight_value)) OVER () AS total_rev,
        CUME_DIST() OVER (ORDER BY SUM(price + freight_value) DESC) AS percentile
    FROM sellers s  
    INNER JOIN order_items i  
    ON s.seller_id = i.seller_id
    WHERE i.order_id IN (SELECT order_id FROM orders WHERE LOWER(order_status) = 'delivered')
    GROUP BY s.seller_id
), top_5 AS (
    SELECT
        SUM(total) AS top_5_total,
        SUM(total) / MAX(total_rev) AS top_5_prop
    FROM sellers_revenue
    WHERE percentile <= 0.05      
),
top_10 AS (
    SELECT
        SUM(total) AS top_10_total,
        SUM(total) / MAX(total_rev) AS top_10_prop
    FROM sellers_revenue
    WHERE percentile <= 0.10
),
top_20 AS (
    SELECT
        SUM(total) AS top_20_total,
        SUM(total) / MAX(total_rev) AS top_20_prop
    FROM sellers_revenue
    WHERE percentile <= 0.20
)
INSERT INTO #revenue_concentration_summary (
    entity_type,
    top_5_total,
    top_5_prop,
    top_10_total,
    top_10_prop,
    top_20_total,
    top_20_prop
)
SELECT
    'Sellers' AS entity_type,
    top_5_total,
    top_5_prop,
    top_10_total,
    top_10_prop,
    top_20_total,
    top_20_prop
FROM top_5
CROSS JOIN top_10
CROSS JOIN top_20;

-- top 5% of sellers is accounted for 52% of GMV
-- top 10% of sellers is accoutned for 66% of GMV
-- top 20% of sellers is account for 82% of GMV
-- Overall, the GMV is extremely concentrated, with top 20% of sellers accounts for over 80% of GMV, suggesting an extremely disproportionate distribution, with higher value sellers accounts for majority of the GMV

WITH product_revenue AS (
    SELECT 
        SUM(price + freight_value) AS total,
        SUM(SUM(price + freight_value)) OVER () AS total_rev,
        CUME_DIST() OVER (ORDER BY SUM(price + freight_value) DESC) AS percentile
    FROM order_items i   
    INNER JOIN products p  
        ON i.product_id = p.product_id
    WHERE i.order_id IN (SELECT order_id FROM orders WHERE LOWER(order_status) = 'delivered')
    GROUP BY p.product_id
),
top_5 AS (
    SELECT
        SUM(total) AS top_5_total,
        SUM(total) / MAX(total_rev) AS top_5_prop
    FROM product_revenue
    WHERE percentile <= 0.05
),
top_10 AS (
    SELECT
        SUM(total) AS top_10_total,
        SUM(total) / MAX(total_rev) AS top_10_prop
    FROM product_revenue
    WHERE percentile <= 0.10
),
top_20 AS (
    SELECT
        SUM(total) AS top_20_total,
        SUM(total) / MAX(total_rev) AS top_20_prop
    FROM product_revenue
    WHERE percentile <= 0.20
)
INSERT INTO #revenue_concentration_summary (
    entity_type,
    top_5_total,
    top_5_prop,
    top_10_total,
    top_10_prop,
    top_20_total,
    top_20_prop
)
SELECT
    'Products' AS entity_type,
    top_5_total,
    top_5_prop,
    top_10_total,
    top_10_prop,
    top_20_total,
    top_20_prop
FROM top_5
CROSS JOIN top_10
CROSS JOIN top_20;

SELECT *
FROM #revenue_concentration_summary;

-- top 5% best selling products accounts for 46% of GMV
-- top 10% of best selling products accoutns for 59% of GMV
-- top 20% of best-selling products accounts for 73% of GMV
-- Overall, very concentrated GMV among products, with top 20% of products accounts for nearly 75% of GMV, suggesting a small portion of best-selling products contribute a higher share of GMV.









