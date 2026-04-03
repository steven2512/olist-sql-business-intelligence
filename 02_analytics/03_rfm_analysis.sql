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
), 

rfm_raw AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS total_orders,
        SUM(order_value) AS total_spent,
        DATEDIFF(day, MAX(order_purchase_timestamp), (SELECT MAX(order_purchase_timestamp) FROM base)) AS recent_purchase_in_days
    FROM base
    GROUP BY customer_unique_id
),

rfm_percentile AS
(
SELECT
    customer_unique_id,
    CUME_DIST() OVER (ORDER BY recent_purchase_in_days) AS r_percentile,
    CUME_DIST() OVER (ORDER BY total_orders DESC) AS f_percentile,
    CUME_DIST() OVER (ORDER BY total_spent DESC) AS m_percentile
FROM rfm_raw
), rfm_score AS (
    SELECT
        customer_unique_id,
        CASE 
        WHEN r_percentile <= 0.2 THEN 5
        WHEN r_percentile > 0.2 AND 
             r_percentile <= 0.4 THEN 4
        WHEN r_percentile > 0.4 AND 
             r_percentile <= 0.6 THEN 3
        WHEN r_percentile > 0.6 AND 
             r_percentile <= 0.8 THEN 2
        ELSE 1 END AS r,

        CASE 
        WHEN f_percentile <= 0.2 THEN 5
        WHEN f_percentile > 0.2 AND 
             f_percentile <= 0.4 THEN 4
        WHEN f_percentile > 0.4 AND 
             f_percentile <= 0.6 THEN 3
        WHEN f_percentile > 0.6 AND 
             f_percentile <= 0.8 THEN 2
        ELSE 1 END AS f,

        CASE 
        WHEN m_percentile <= 0.2 THEN 5
        WHEN m_percentile > 0.2 AND 
             m_percentile <= 0.4 THEN 4
        WHEN m_percentile > 0.4 AND 
             m_percentile <= 0.6 THEN 3
        WHEN m_percentile > 0.6 AND 
             m_percentile <= 0.8 THEN 2
        ELSE 1 END AS m
    
    FROM rfm_percentile
),

rfm_segment AS (
    SELECT
        customer_unique_id,
        r,
        f,
        m,
        CASE
            WHEN r BETWEEN 4 AND 5
             AND f BETWEEN 4 AND 5
             AND m BETWEEN 4 AND 5 THEN 'Champions'

            WHEN r BETWEEN 2 AND 5
             AND f BETWEEN 3 AND 5
             AND m BETWEEN 3 AND 5 THEN 'Loyalists'

            WHEN r BETWEEN 4 AND 5
             AND f BETWEEN 1 AND 3
             AND m BETWEEN 1 AND 3 THEN 'Potential / New'

            WHEN r BETWEEN 1 AND 2
             AND f BETWEEN 1 AND 2
             AND m BETWEEN 1 AND 2 THEN 'Hibernating'

            WHEN r BETWEEN 1 AND 2
             AND f BETWEEN 2 AND 5
             AND m BETWEEN 2 AND 5 THEN 'At Risk'

            ELSE 'Needs Attention'
        END AS segment
    FROM rfm_score
)

SELECT
    customer_unique_id,
    r,
    f,
    m,
    segment
FROM rfm_segment;


        
