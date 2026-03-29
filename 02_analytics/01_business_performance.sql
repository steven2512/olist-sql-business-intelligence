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


