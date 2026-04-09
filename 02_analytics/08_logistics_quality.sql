WITH base AS (
    SELECT
        DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date) AS val
    FROM orders
    WHERE LOWER(order_status) = 'delivered'
    AND order_purchase_timestamp < order_delivered_customer_date
),

stats AS (
    SELECT
        COUNT(*)                    AS n,
        MIN(val)                    AS min_val,
        MAX(val)                    AS max_val,
        AVG(CAST(val AS FLOAT))     AS mean_val,
        STDEV(val)                  AS stddev_val
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
            * SUM(POWER((CAST(b.val AS FLOAT) - s.mean_val) / NULLIF(s.stddev_val, 0), 3)) AS skewness
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

-- shape: highly right-skewed distribution with a fat long tail, with most orders delivered within a lower amount of days, however a fair amount of orders are delivered at a much higher time frame.
-- center: since it's right-skewed distribution, the median of 10 days better represents a typical delivery time than the mean of 12.4968 days, which was pulled above the median by the extreme outliers.
-- spread: delivery time ranges from 0 days -> 210 days, however 50% of orders are delivered from 7 -> 16 days (IQR: 9)
-- Visual summary: delivery time cluster most around 8-10 days mark, then drops but remains fairly dense as it approaches 50 - 100 days mark, and gradually remains a fair amount of density even at higher > 160 days, confirmed by the boxplot

USE Olist;
SELECT
    CASE WHEN DATEDIFF(day, order_estimated_delivery_date, order_delivered_customer_date) > 0 THEN 'late'
    WHEN DATEDIFF(day, order_estimated_delivery_date, order_delivered_customer_date) = 0 THEN 'on time'
            ELSE 'early' END AS status_delivery,
    COUNT(*) AS total_orders,
    CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER () AS proportion
FROM orders o
WHERE LOWER(order_status) = 'delivered' AND order_delivered_customer_date IS NOT NULL
GROUP BY CASE WHEN DATEDIFF(day, order_estimated_delivery_date, order_delivered_customer_date) > 0 THEN 'late'
            WHEN DATEDIFF(day, order_estimated_delivery_date, order_delivered_customer_date) = 0 THEN 'on time'
            ELSE 'early' END

-- ~92% of orders are early, 1% is on time, and ~7% is late
-- Olist is generally beating its promised delivery window, with 91.89% of orders arriving early and only 6.77% arriving late.
-- Exact on-time delivery is rare at only 1.34%, suggesting the logistics system tends to deliver either comfortably before the estimate or noticeably after it, rather than clustering exactly on the promised date.
-- Overall, the estimated delivery dates appear to be conservative more often than not.

-- Which sellers, product groups, or regions have the longest delivery times?
-- sellers
SELECT TOP 10
    t.seller_id,
    AVG(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) AS delivery_time
FROM orders o  
INNER JOIN (
    SELECT DISTINCT  
        i.order_id,
        s.seller_id
    FROM order_items i  
    INNER JOIN sellers s  
    ON i.seller_id = s.seller_id
) t
ON o.order_id = t.order_id
GROUP BY t.seller_id
HAVING COUNT(*) > 10
ORDER BY delivery_time DESC

-- seller-level delivery time varies a lot, with the slowest sellers averaging roughly 26 - 37 days per order, far above the overall average of 12.5 days.
-- This suggests some seller-specific logistics or fulfillment issues are severe enough to materially slow delivery beyond the marketplace baseline.

SELECT TOP 10
    t.product_category_name,
    AVG(CAST(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date) AS FLOAT)) AS avg_delivery_time
FROM orders o
INNER JOIN (
    SELECT DISTINCT
        i.order_id,
        COALESCE(p.product_category_name, 'unknown') AS product_category_name
    FROM products p
    INNER JOIN order_items i
        ON p.product_id = i.product_id
) t
    ON o.order_id = t.order_id
WHERE LOWER(o.order_status) = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY t.product_category_name
ORDER BY avg_delivery_time DESC;

-- moveis_escritorio stands out clearly as the slowest product group at about 20.59 days, which is substantially above the overall delivery average.
-- furniture-related categories appear repeatedly near the top, such as moveis_colchao_e_estofado and moveis_sala, suggesting bulky or harder-to-handle product groups face systematically slower delivery.
-- Outside furniture, some fashion-related and niche categories also run slower, but not nearly as extremely as the weakest furniture groups.


USE Olist;
DROP TABLE IF EXISTS #zip_code_and_state;

WITH zip_state_counts AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_state,
        COUNT(*) AS total
    FROM geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_state
),
zip_state_ranked AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_state,
        ROW_NUMBER() OVER (
            PARTITION BY geolocation_zip_code_prefix
            ORDER BY total DESC, geolocation_state
        ) AS rn
    FROM zip_state_counts
)
SELECT
    geolocation_zip_code_prefix,
    geolocation_state
INTO #zip_code_and_state
FROM zip_state_ranked
WHERE rn = 1;


SELECT
    z.geolocation_state,
    AVG(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) AS avg_delivery_time
FROM customers c  
INNER JOIN orders o  
ON c.customer_id = o.customer_id
INNER JOIN #zip_code_and_state z
ON c.customer_zip_code_prefix = z.geolocation_zip_code_prefix
GROUP BY z.geolocation_state
ORDER BY avg_delivery_time DESC

-- the slowest customer regions are heavily concentrated in the North and Northeast, with RR, AP, and AM averaging roughly 29, 27, and 26 days respectively.
-- These states take around double the overall average delivery time, suggesting geography is a major constraint in logistics performance.
-- This fits the earlier geolocation findings where demand and seller supply are concentrated elsewhere, making longer-distance fulfillment more likely for these regions.

-- Where in the fulfillment timeline do the biggest delays occur?
SELECT
    order_id,
    CAST(DATEDIFF(hour, order_approved_at, order_delivered_carrier_date) AS FLOAT) / DATEDIFF(hour, order_purchase_timestamp, order_delivered_customer_date)  AS diff_approved_carier_prop,
    CAST(DATEDIFF(hour, order_delivered_carrier_date, order_delivered_customer_date) AS FLOAT) / DATEDIFF(hour, order_purchase_timestamp, order_delivered_customer_date)   AS diff_carier_customer_prop,
    CAST(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date) AS FLOAT) AS delivery_days
FROM
orders
ORDER BY DATEDIFF(hour, order_purchase_timestamp, order_delivered_customer_date) DESC
--biggest delay is in carrier shipping to customer with some takes up to 99%+ of the total delivery time

-- Are longer delivery times associated with weaker reviews or repeat purchase?
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

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_customer_date) AS delivery_days
    FROM customers c
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE LOWER(o.order_status) = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
),
customer_order_counts AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM customer_orders
    GROUP BY customer_unique_id
)
SELECT
    CASE WHEN c.total_orders = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
    AVG(CAST(o.delivery_days AS FLOAT)) AS avg_delivery_days
FROM customer_orders o
INNER JOIN customer_order_counts c
    ON o.customer_unique_id = c.customer_unique_id
GROUP BY CASE WHEN c.total_orders = 1 THEN 'One-time' ELSE 'Repeat' END;

