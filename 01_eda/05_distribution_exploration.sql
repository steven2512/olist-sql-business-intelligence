USE Olist;
SELECT * FROM information_schema.columns
WHERE NUMERIC_PRECISION IS NOT NULL;


-- 1. Order and cost distribution
WITH base AS (
    SELECT
        SUM(payment_value) AS val
    FROM order_payments
    GROUP BY order_id
),

stats AS (
    SELECT
        COUNT(*)    AS n,
        MIN(val)    AS min_val,
        MAX(val)    AS max_val,
        AVG(val)    AS mean_val,
        STDEV(val)  AS stddev_val
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
    ROUND(s.min_val,    4) AS min_val,
    ROUND(s.max_val,    4) AS max_val,
    ROUND(s.mean_val,   4) AS mean,
    ROUND(p.p50,        4) AS median,
    ROUND(s.stddev_val, 4) AS stddev,
    ROUND(p.p25,        4) AS p25,
    ROUND(p.p75,        4) AS p75,
    ROUND(p.p75 - p.p25, 4) AS iqr,
    ROUND(sk.skewness,  4) AS skewness
FROM stats s
CROSS JOIN percentiles p
CROSS JOIN skewness sk;
-- Highly right-skewed distribution (skewness 9.15): vast majority of 99,440 orders cluster at lower values, with a long tail of rare high-value outliers.
-- Center: median $105.29 better represents typical order than mean $160.99, as extreme values pull the average upward.
-- Spread & range: IQR $114.96 (Q1 $62.01–Q3 $176.97) shows half of orders fall in a moderate band; overall range $0–$13,664 with std. dev. $221.95.
-- Visual summary: Histogram peaks sharply at low values then drops off; boxplot confirms dense lower cluster plus many high outliers. Overall, small-to-medium orders dominate, with occasional large purchases.

WITH base AS (
    SELECT
        SUM(freight_value) / SUM(freight_value + price) * 100 AS val
    FROM order_items
    GROUP BY order_id
),

stats AS (
    SELECT
        COUNT(*)    AS n,
        MIN(val)    AS min_val,
        MAX(val)    AS max_val,
        AVG(val)    AS mean_val,
        STDEV(val)  AS stddev_val
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

-- Shape: Right-skewed distribution with most freight ratio cluster on the lower side, and a long thick tail of outliers. Unimodal with one peak at 12.5% then drops off gradually
-- Center: since distribution is right-skewed, the median of 18.3256 is better representation of a typical freight ratio as the mean (20.8804) is being pulled towards the higher side by the extreme ouliers (rare large freight ratio)
-- Spread: freight ratio ranges from 0% -> 95.5451%, however, 50% of all orders have freight-value in a quite narrow band of 11.6502% - 27.5463% (IQR: 15.8961)
-- Visual summary: freight ratio peaks early at lower ratios then drops off gradually towards the end; box clot confirms dense lower freight ratios, with many high outliers. In summary, smaller freight ratios dominate, with high freight ratios that drops off gradually in frequency as we go higher.

WITH base AS (
    SELECT
        COUNT(*) AS val
    FROM order_items
    GROUP BY order_id
),

stats AS (
    SELECT
        COUNT(*)    AS n,
        MIN(val)    AS min_val,
        MAX(val)    AS max_val,
        AVG(CAST(val AS FLOAT)) AS mean_val,
        STDEV(val)  AS stddev_val
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

-- Shape: extreme right-skewed distribution, with a long thin tail caused by small amount of extreme outliers. Uniomdal with 1 peak at 1 item.
-- Center: since it's right-skewed distribution, the median of 1 item better represents an order's typical total items compared to the mean of 1.1417 that is pulled towards the higher side by the outliers
-- Spread: total items ranges from 1 -> 21, however, 50% of the orders have a mathetmatically tightest possible band at exactly 1 item (IQR: 0).
-- Visual summary: The majority of orders (more than 90%+ of orders) consists of exactly 1 item, then drops sharply in frequency and remains sparse as there are more items.

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

-- ============================================================
-- DISTRIBUTION: Day of Month
-- ============================================================
WITH base AS (
    SELECT DAY(order_purchase_timestamp) AS val
    FROM orders
),
stats AS (
    SELECT
        COUNT(*)                AS n,
        MIN(val)                AS min_val,
        MAX(val)                AS max_val,
        AVG(CAST(val AS FLOAT)) AS mean_val,
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


-- ============================================================
-- DISTRIBUTION: Month of Order
-- ============================================================
WITH base AS (
    SELECT MONTH(order_purchase_timestamp) AS val
    FROM orders
),
stats AS (
    SELECT
        COUNT(*)                AS n,
        MIN(val)                AS min_val,
        MAX(val)                AS max_val,
        AVG(CAST(val AS FLOAT)) AS mean_val,
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


-- ============================================================
-- DISTRIBUTION: Hour of Day
-- ============================================================
WITH base AS (
    SELECT DATEPART(hour, order_purchase_timestamp) AS val
    FROM orders
),
stats AS (
    SELECT
        COUNT(*)                AS n,
        MIN(val)                AS min_val,
        MAX(val)                AS max_val,
        AVG(CAST(val AS FLOAT)) AS mean_val,
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


-- ============================================================
-- DISTRIBUTION: Day of Week
-- ============================================================
WITH base AS (
    SELECT DATEPART(weekday, order_purchase_timestamp) AS val
    FROM orders
),
stats AS (
    SELECT
        COUNT(*)                AS n,
        MIN(val)                AS min_val,
        MAX(val)                AS max_val,
        AVG(CAST(val AS FLOAT)) AS mean_val,
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
