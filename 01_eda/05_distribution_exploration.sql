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

-- shape: highly left-skewed with fat left tail (bounded by 1-5 range). Most reviews cluster at higher values. Unimodal with 1 peak at 5 stars
-- center: since it's left-skewed distribution, the median value of 5 is a better representation of a typical review, as mean (4.0864) is pulled towards the lower side by extreme outliers (small numbers of negative reviews)
-- spread: reviews range from 1 - 5 stars, however, 50% of reviews are either 4 or 5 stars (IQR: 1)
-- visual summary: overall, histogram shows highly rated reviews dominate, box plot also confirms dense cluster at higher rated reviews, with occasional lower negative reviews, most clearly seen by a sharp drop from 5 -> 4 stars then maintain a smaller but meaninful level at lower ratings.

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

-- shape: roughly symmetric with a very slight right skewed (0.0243). Orders are fairly evenly distributed throughout the month. Unimodal with one peak on day 24 of the month.
-- center: since this is symmetric distribution, either mean of 15.5059 or median of 15 reasonbly represents the typical purchase day of a month.
-- spread: there has been orders on every day of the month (day 1 -> 31). 50% of orders falls between day 8 - day 23 of the month. This shows orders are fairly evenly distributed across the month, and is not tightly clustered to any narrow band.
-- visual summary: histogram appears fairly flat, with small bumps above the rest happen in later days of the month. Boxplot also looks balance around the center, confirming day of month has little skewness and no meaninful outlier behaviour


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
-- shape: slightly right-skewed distribution, but not strongly skewed overall. Not clearly unimodal, though month 8 is the highest point and orders stay relatively high from month 3 -> 8 before dropping off later.
-- center: since this is only slightly right-skewed, either mean of 6.0322 or median of 6 reasonably represents a typical order month.
-- spread: month ranges from 1 -> 12, and 50% of all orders fall between month 3 -> 8 (IQR: 5). This shows orders are fairly spread across the year, though more concentrated in the earlier-to-middle months.
-- visual summary: histogram stays fairly dense from month 1 -> 8 and peaks at month 8, then drops sharply at month 9 -> 10 before recovering somewhat at month 11. boxplot shows no meaningful outlier behaviour since month is bounded between 1 and 12.


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
-- shape: moderately left-skewed distribution, with most orders clustering from late morning to evening and a longer thinner tail toward the early-morning hours. Broadly unimodal, with the highest point at hour 16.
-- center: since this is left-skewed, the median of 15 better represents a typical purchase hour than the mean of 14.7708, which is pulled slightly lower by the low-frequency overnight hours.
-- spread: hour ranges from 0 -> 23, and 50% of all orders fall between hour 11 -> 19 (IQR: 8). This shows most orders are placed within a fairly broad daytime-to-evening window.
-- visual summary: histogram rises sharply from the morning, stays very dense from around hour 9 -> 22, peaks in the afternoon, then falls off heavily during overnight and very early morning hours. boxplot also confirms the center is around the mid-to-late day rather than the extremes.


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

-- shape: orders cluster around weekdays, then drop clearly on the weekend. This is the real pattern. Framing it mainly as symmetric / slightly right-skewed is weaker because that depends on how weekdays were numerically encoded.
-- center: mean and median are not very meaningful here because weekday is a cyclical categorical time unit, not a true linear numeric measure like order value or delivery days.
-- spread: orders occur across all 7 days, but the distribution is not even. Monday -> Friday account for 76,594 orders (77.0%), while Saturday + Sunday account for 22,847 orders (23.0%). Among individual days, Monday is highest (16,196) and Saturday is lowest (10,887).
-- visual summary: the bar chart is highest across the weekday block, then drops on Saturday, with a small recovery on Sunday. Overall, purchases are clearly weekday-heavy rather than weekend-heavy.


WITH base AS (
    SELECT COUNT(DISTINCT order_id) AS val
    FROM sellers s
    INNER JOIN order_items i
        ON s.seller_id = i.seller_id
    GROUP BY s.seller_id
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

--shape: extreme right-skewed distribution, with a fat long tail made up by very popular sellers. Most sellers's total items sold cluster at the low -> very low amount
-- center: since it's right-skewed distribution, the median value of 8 is a better representation of a typical total items sold for a seller compared to the mean of 36.3974, which is pulled towards the higher amount by a few of the very popular sellers
-- spread: total items sold for a seller ranges from 1 -> 2033, however, 50% of sellers only have sold anywhere from 2 -> 24 items (IQR: 22)
-- visual summary: most sellers' total items sold clustered and peaked at lower amount then drop offs as it gets to higher amount, confirmed by both histogram and box plots. However, there still remains a fair amount of sellers remain at higher total of items sold, confirming the fat tail.


USE Olist;

WITH base AS (
    SELECT
        MAX(CAST(payment_installments AS FLOAT)) AS val
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
-- shape: moderately right-skewed distribution with a long sparse right tail. There is a very strong peak at 1 installment, then frequency generally drops as installment length increases. It is not perfectly smooth though, because there are visible bumps at common plan lengths like 8 and 10.
-- center: since it is right-skewed, the median of 2 better represents a typical order-level max installment count than the mean of 2.9305, which is pulled upward by the smaller group of long-installment orders.
-- spread: max installments range from 0 -> 24, however, 50% of all orders fall between 1 -> 4 installments (IQR: 3). Also, 71.46% of orders are at 3 installments or less, which reinforces that shorter payment horizons clearly dominate overall.
-- visual summary: histogram peaks extremely sharply at 1, then stays meaningful across 2 -> 6 before becoming much sparser at higher installment lengths, with a few visible bumps at standard financing plans. Box plot confirms a dense lower cluster, median at 2, upper whisker around 8, and a smaller group of high-installment outliers above that. Overall, most customers either pay immediately or over short plans, while a smaller but still meaningful group are willing to stay on longer installment plans.