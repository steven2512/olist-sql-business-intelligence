USE Olist;
-- 1. Assign a score in R F and M to each customer

WITH base AS (
SELECT
    customer_unique_id,
    order_purchase_timestamp,
    p.order_value
FROM customers c  
INNER JOIN orders o  
ON c.customer_id = o.customer_id
INNER JOIN (
    SELECT
        order_id, 
        SUM(payment_value) AS order_value
    FROM order_payments
    GROUP BY order_id
) p  
ON o.order_id = p.order_id
), rfm AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS total_orders,
        SUM(order_value) AS total_spent,
        MAX(order_purchase_timestamp) AS most_recent_purchase_date
    FROM base
    GROUP BY customer_unique_id
) SELECT * FROM rfm