USE Olist;

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
 FROM total_revenue r  
INNER JOIN avg_order_value a
ON r.month_year = a.month_year
INNER JOIN order_count c  
ON r.month_year = c.month_year
ORDER BY r.month_year

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

