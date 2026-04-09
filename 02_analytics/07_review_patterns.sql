-- Q1. How are review scores distributed across orders?
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

-- Q2. Which sellers, products, or categories receive the lowest review scores?
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

-- weakest sellers can be very poorly rated, with the bottom averages at roughly 1.26, 1.72, and 2.10
-- however, most of those extreme lows come from relatively small bases around 11 - 20 orders, so some volatility is expected
-- seller 1ca707... is more meaningful, with 114 orders and only 2.33 average rating, suggesting some seller-level quality problems are real rather than just noise

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

-- weak products are even more extreme than weak sellers, with the bottom products averaging as low as roughly 1.18 and 1.61
-- while some of the worst cases still have small sample sizes, a few products with 28, 43, and 61 reviewed orders remain near or below the low-2 range
-- this suggests poor reviews are not only random order-level noise; some products likely have recurring quality or expectation issues

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

-- category-level ratings are much less extreme, which makes sense since category averages smooth out volatile individual SKU behaviour
-- the weakest category is portateis_cozinha_e_preparadores_de_alimentos at about 3.43, though with only 14 orders it should be interpreted cautiously
-- more meaningful is moveis_escritorio, which averages only about 3.60 across 1263 orders, making it the clearest large-scale weak category
-- other weaker categories such as audio and casa_conforto also stay below the broader 4.09 marketplace average, suggesting dissatisfaction clusters by product group rather than being fully random

-- Q3. Are lower review scores associated with delivery delays?
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
-- avg delivery days for the 1000 worst reviewed orders is about 20.55, versus only 12 days across all delivered orders overall
-- in the context of earlier delivery analysis, where the median is 10 days and half of all orders arrive within 7 - 16 days, 20.55 is meaningfully slower
-- this suggests lower rated orders are associated with delivery delays, though delays are unlikely to be the only cause of weak reviews

-- Q4. Do repeat customers review differently from one-time customers?
SELECT
    CASE WHEN total_orders = 1 THEN 1 ELSE 0 END AS one_time_flag,
    AVG(avg_rating) AS avg_rating
FROM (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        AVG(CAST(review_score AS FLOAT)) AS avg_rating
    FROM customers c  
    INNER JOIN orders o
    ON c.customer_id = o.customer_id
    INNER JOIN order_reviews r  
    ON o.order_id = r.order_id
    GROUP BY customer_unique_id
) t
GROUP BY CASE WHEN total_orders = 1 THEN 1 ELSE 0 END

-- repeating customers have a slightly higher average review score than one-time customers (4.1177 vs 4.0839)
-- however, the gap is very small in practical terms, with both groups still rated clearly above 4.0
-- this suggests review satisfaction does differ slightly by repeat behaviour, but not by enough to say poor reviews alone explain why most customers never return

-- Q5. Which segments have the highest share of poor reviews?
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

-- Needs Attention has the lowest average review score at about 4.02, while Potential / New is the highest at about 4.21
-- however, every segment still remains above 4.0, so no segment appears to have particularly weak reviews in an absolute sense
-- this suggests dissatisfaction is more likely tied to specific orders, products, sellers, or delayed deliveries than to broad customer segment type
