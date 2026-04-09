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
