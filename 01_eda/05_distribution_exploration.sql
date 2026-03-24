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

-- Findings: order value ranges from 0 to 13664.08, with a median of 105.29 and mean of 160.9903
-- Skewness is at 9.1502 suggests extreme right skew, with most orders clustered on the lower side, and mean is being pulled far above the median by large order values
-- Typical orders sit between 62.01 and 176.97

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

-- Findings: freight-to-order ratio ranges from 0% to 95.5451%, with a median of 18.33% and mean of 20.88%
-- Skewness is at 1.066, suggesting high right skew, with many freight-to-order ratios are on the lower side, and mean is being pulled above the median with disproportionately high freight costs
-- Typical orders have freight-to-order ratio between 11.65% to 27.55%