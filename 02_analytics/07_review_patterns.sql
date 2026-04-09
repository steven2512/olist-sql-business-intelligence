WITH base AS (
    SELECT CAST(review_score AS FLOAT) AS val
    FROM order_reviews
),

stats AS (
    SELECT
        COUNT(*)                AS n,
        MIN(val)                AS min_val,
        MAX(val)                AS max_val,
        AVG(val)                AS mean_val,
        STDEV(val)              AS stddev_val
    FROM base
),

percentiles AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY val) OVER () AS p25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY val) OVER () AS p50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY val) OVER () AS p75
    FROM base
),

skewness AS (
    SELECT
        (CAST(s.n AS FLOAT) / ((s.n - 1.0) * (s.n - 2.0)))
            * SUM(POWER((b.val - s.mean_val) / NULLIF(s.stddev_val, 0), 3)) AS skewness
    FROM base b
    CROSS JOIN stats s
    GROUP BY s.n, s.mean_val, s.stddev_val
)

SELECT
    s.n,
    ROUND(s.min_val,     4) AS min_val,
    ROUND(s.max_val,     4) AS max_val,
    ROUND(s.mean_val,    4) AS mean,
    ROUND(p.p50,         4) AS median,
    ROUND(s.stddev_val,  4) AS stddev,
    ROUND(p.p25,         4) AS p25,
    ROUND(p.p75,         4) AS p75,
    ROUND(p.p75 - p.p25, 4) AS iqr,
    ROUND(sk.skewness,   4) AS skewness
FROM stats s
CROSS JOIN percentiles p
CROSS JOIN skewness sk;

-- shape: highly left-skewed with fat left tail (bounded by 1-5 range). Most reviews cluster at higher values. Unimodal with 1 peak at 5 stars
-- center: since it's left-skewed distribution, the median value of 5 is a better representation of a typical review, as mean (4.0864) is pulled towards the lower side by extreme outliers (small numbers of negative reviews)
-- spread: reviews range from 1 - 5 stars, however, 50% of reviews are either 4 or 5 stars (IQR: 1)
-- visual summary: overall, histogram shows highly rated reviews dominate, box plot also confirms dense cluster at higher rated reviews, with occasional lower negative reviews, most clearly seen by a sharp drop from 5 -> 4 stars then maintain a smaller but meaninful level at lower ratings.

USE Olist;
SELECT TOP 10
    t.seller_id,
    COUNT(DISTINCT t.order_id) AS total_orders,
    AVG(CAST(review_score AS FLOAT)) AS avg_rating
FROM
(SELECT DISTINCT
    i.order_id,
    s.seller_id
FROM sellers s  
INNER JOIN order_items i  
ON s.seller_id = i.seller_id) t
INNER JOIN order_reviews r
ON t.order_id = r.order_id
GROUP BY t.seller_id
HAVING COUNT(DISTINCT t.order_id) > 10
ORDER BY avg_rating

-- products
SELECT TOP 10
    t.product_id,
    COUNT(DISTINCT t.order_id) AS total_orders,
    AVG(CAST(review_score AS FLOAT)) AS avg_rating
FROM
(SELECT DISTINCT
    i.order_id,
    p.product_id
FROM products p  
INNER JOIN order_items i  
ON p.product_id = i.product_id) t
INNER JOIN order_reviews r
ON t.order_id = r.order_id
GROUP BY t.product_id
HAVING COUNT(DISTINCT t.order_id) > 10
ORDER BY avg_rating

--

SELECT TOP 10
    t.product_category_name,
    COUNT(DISTINCT t.order_id) AS total_orders,
    AVG(CAST(review_score AS FLOAT)) AS avg_rating
FROM
(SELECT DISTINCT
    i.order_id,
    p.product_id,
    p.product_category_name
FROM products p  
INNER JOIN order_items i  
ON p.product_id = i.product_id) t
INNER JOIN order_reviews r
ON t.order_id = r.order_id
GROUP BY t.product_category_name
HAVING COUNT(DISTINCT t.order_id) > 10
ORDER BY avg_rating

SELECT AVG(CAST(delivery_days AS FLOAT)) AS avg_delivery_days
FROM (
SELECT TOP 1000
    o.order_id,
    DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date) AS delivery_days,
    AVG(CAST(review_score AS FLOAT)) AS avg_rating
FROM orders o  
INNER JOIN order_reviews r  
ON o.order_id = r.order_id
GROUP BY o.order_id, DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)
ORDER BY avg_rating
) d
-- avg_delivery_days for top 1000 worst reviewed orders are 20, while the average delivery days of all orders is 12. So lower rated orders appears to be associated with delivery delays

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
    rfm.segment,
    AVG(CAST(review_score AS FLOAT)) AS avg_review_score
FROM #rfm_segment rfm
INNER JOIN customers c  
ON rfm.customer_unique_id = c.customer_unique_id
INNER JOIN orders o  
ON c.customer_id = o.customer_id
INNER JOIN order_reviews r
ON o.order_id = r.order_id
GROUP BY rfm.segment
ORDER BY avg_review_score

-- Needs Attention, loyalists and at risk has lowest average_review_score but it's generally still very high at >4. No segments particularly have low review scores (as noted by avg review of all customers at 4.09)