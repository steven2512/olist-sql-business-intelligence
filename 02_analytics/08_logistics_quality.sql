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

