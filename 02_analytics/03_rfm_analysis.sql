USE Olist;
-- 1. Store customer-level RFM metrics and scores
DROP TABLE IF EXISTS #rfm_score;
DROP TABLE IF EXISTS #rfm_segment;

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
        DATEDIFF(
            day,
            MAX(order_purchase_timestamp),
            (SELECT MAX(order_purchase_timestamp) FROM base)
        ) AS recent_purchase_in_days
    FROM base
    GROUP BY customer_unique_id
),

rfm_percentile AS (
    SELECT
        customer_unique_id,
        total_orders,
        total_spent,
        recent_purchase_in_days,
        CUME_DIST() OVER (ORDER BY recent_purchase_in_days) AS r_percentile,
        CUME_DIST() OVER (ORDER BY total_orders DESC) AS f_percentile,
        CUME_DIST() OVER (ORDER BY total_spent DESC) AS m_percentile
    FROM rfm_raw
),

rfm_score AS (
    SELECT
        customer_unique_id,
        total_orders,
        total_spent,
        recent_purchase_in_days,
        CASE
            WHEN r_percentile <= 0.2 THEN 5
            WHEN r_percentile <= 0.4 THEN 4
            WHEN r_percentile <= 0.6 THEN 3
            WHEN r_percentile <= 0.8 THEN 2
            ELSE 1
        END AS r,
        CASE
            WHEN f_percentile <= 0.2 THEN 5
            WHEN f_percentile <= 0.4 THEN 4
            WHEN f_percentile <= 0.6 THEN 3
            WHEN f_percentile <= 0.8 THEN 2
            ELSE 1
        END AS f,
        CASE
            WHEN m_percentile <= 0.2 THEN 5
            WHEN m_percentile <= 0.4 THEN 4
            WHEN m_percentile <= 0.6 THEN 3
            WHEN m_percentile <= 0.8 THEN 2
            ELSE 1
        END AS m
    FROM rfm_percentile
)

SELECT
    customer_unique_id,
    total_orders,
    total_spent,
    recent_purchase_in_days,
    r,
    f,
    m
INTO #rfm_score
FROM rfm_score;

SELECT *
FROM #rfm_score;

-- 2. Assign RFM segments from the scored temp table
SELECT
    customer_unique_id,
    total_orders,
    total_spent,
    recent_purchase_in_days,
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
INTO #rfm_segment
FROM #rfm_score;


SELECT
    segment,
    COUNT(*) AS total_customers,
    ROUND(CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER () , 4)  AS cust_prop,
    SUM(total_orders) AS total_orders,
    ROUND(CAST(SUM(total_orders) AS FLOAT) / SUM(SUM(total_orders))  OVER (), 4)AS orders_prop,
    SUM(total_spent) AS total_revenue,
    ROUND(CAST(SUM(total_spent) AS FLOAT) / SUM(SUM(total_spent)) OVER () , 4) AS rev_prop,
    AVG(total_spent) AS avg_revenue
FROM #rfm_segment
GROUP BY segment
ORDER BY total_customers DESC

-- Summary of segments:
-- 57% pf customers are in 'Needs Attention' and they alone account for 78% of revenue
-- The next big chunks are Potential (23%) and Hibernating customers (16%).
-- Those top 3 segments account for 96% of customers and 85% of the revenue
-- Loyalists and Champion, which are the high-valued customers only takes up a bit over 2.4% of customers, and accounts for 5% of revenue
-- At risk customers are the lowest at 0.05% of customers and 0.08% of revenue

-- Interesting findings:
-- While Loyalists and Champions only accounts for 2% of customers, they actually spend the most on average
-- Potential / new customers accounts for over 1/5 of the customers, yet spend the least on average
-- Hibernating customers is at a rather alarming amount at 16%, meaning nearly 1/5 of customers hasn't bought anything for a while and might be at risk of churn.
-- Although at risk proportion is small, it's worth noticing they might transfer into Hibernating, and is also at risk of churn



        
