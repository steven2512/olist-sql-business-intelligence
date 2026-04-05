USE Olist;
DROP TABLE IF EXISTS #cohort_retention;
DROP TABLE IF EXISTS #cohort_revenue;

WITH first_customer_buy AS (
    SELECT
        customer_unique_id,
        DATETRUNC(month, MIN(order_purchase_timestamp)) AS cohort_month
    FROM customers c
    INNER JOIN orders o  
    ON c.customer_id = o.customer_id
    GROUP BY customer_unique_id
), 
all_customer_buys AS (
    SELECT DISTINCT
        customer_unique_id,
        DATETRUNC(month, order_purchase_timestamp) AS purchase_month
    FROM customers c
    INNER JOIN orders o  
    ON c.customer_id = o.customer_id
),
cohort_repeat AS (
    SELECT 
        cohort_month,
        DATEDIFF(month, cohort_month, purchase_month) AS month_offset,
        COUNT(DISTINCT f.customer_unique_id) AS total_customers
    FROM first_customer_buy f
    INNER JOIN all_customer_buys a
    ON f.customer_unique_id = a.customer_unique_id
    GROUP BY cohort_month, DATEDIFF(month, cohort_month, purchase_month)
),
date_bounds AS (
    SELECT
        MIN(cohort_month) AS min_cohort_month,
        MAX(purchase_month) AS max_purchase_month
    FROM first_customer_buy f
    CROSS JOIN (
        SELECT MAX(purchase_month) AS purchase_month
        FROM all_customer_buys
    ) p
),
month_numbers AS (
    SELECT TOP (
        SELECT DATEDIFF(month, min_cohort_month, max_purchase_month) + 1
        FROM date_bounds
    )
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS month_offset
    FROM sys.all_objects
),
cohort_template AS (
    SELECT
        c.cohort_month,
        n.month_offset
    FROM (
        SELECT DISTINCT
            cohort_month
        FROM first_customer_buy
    ) c
    CROSS JOIN month_numbers n
    CROSS JOIN date_bounds d
    WHERE DATEADD(month, n.month_offset, c.cohort_month) <= d.max_purchase_month
),
cohort_filled AS (
    SELECT
        t.cohort_month,
        t.month_offset,
        COALESCE(r.total_customers, 0) AS total_customers
    FROM cohort_template t
    LEFT JOIN cohort_repeat r
    ON t.cohort_month = r.cohort_month
    AND t.month_offset = r.month_offset
)
SELECT 
    cohort_month,
    month_offset,
    total_customers,
    CAST(total_customers AS FLOAT) / FIRST_VALUE(total_customers) OVER (PARTITION BY cohort_month ORDER BY month_offset) AS retention_rate
INTO #cohort_retention
FROM cohort_filled;

SELECT *
FROM #cohort_retention
ORDER BY cohort_month, month_offset;

WITH first_customer_buy AS (
    SELECT
        customer_unique_id,
        DATETRUNC(month, MIN(order_purchase_timestamp)) AS cohort_month
    FROM customers c
    INNER JOIN orders o  
    ON c.customer_id = o.customer_id
    GROUP BY customer_unique_id
),
order_value AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        DATETRUNC(month, o.order_purchase_timestamp) AS purchase_month,
        SUM(p.payment_value) AS order_value
    FROM customers c
    INNER JOIN orders o  
    ON c.customer_id = o.customer_id
    INNER JOIN order_payments p
    ON o.order_id = p.order_id
    GROUP BY
        o.order_id,
        c.customer_unique_id,
        DATETRUNC(month, o.order_purchase_timestamp)
)
SELECT
    f.cohort_month,
    DATEDIFF(month, f.cohort_month, o.purchase_month) AS month_offset,
    SUM(o.order_value) AS cohort_revenue
INTO #cohort_revenue
FROM first_customer_buy f
INNER JOIN order_value o
ON f.customer_unique_id = o.customer_unique_id
GROUP BY
    f.cohort_month,
    DATEDIFF(month, f.cohort_month, o.purchase_month);

-- Which cohorts have the strongest retention?
WITH cohort_sizes AS (
    SELECT
        cohort_month,
        total_customers AS cohort_size
    FROM #cohort_retention
    WHERE month_offset = 0
),
retention_summary AS (
    SELECT
        r.cohort_month,
        s.cohort_size,
        AVG(CASE WHEN r.month_offset BETWEEN 1 AND 3 THEN r.retention_rate END) AS avg_retention_1_to_3,
        MAX(CASE WHEN r.month_offset = 1 THEN r.retention_rate END) AS month_1_retention
    FROM #cohort_retention r
    INNER JOIN cohort_sizes s
    ON r.cohort_month = s.cohort_month
    GROUP BY
        r.cohort_month,
        s.cohort_size
)
SELECT TOP 5
    cohort_month,
    cohort_size,
    avg_retention_1_to_3,
    month_1_retention
FROM retention_summary
WHERE cohort_size >= 500
ORDER BY avg_retention_1_to_3 DESC, month_1_retention DESC;

-- Which cohorts generate the most revenue over time?
SELECT TOP 5
    cohort_month,
    SUM(cohort_revenue) AS total_revenue_over_time
FROM #cohort_revenue
GROUP BY cohort_month
ORDER BY total_revenue_over_time DESC;

-- Cohort retention is very weak overall, with most cohorts dropping sharply after the first purchase month.
-- For the larger 2017 cohorts, month 1 retention is only around 0.2% - 0.7%, meaning only a very small fraction of customers returned in the following month.
-- Retention falls even further by month 2 and month 3, where most cohorts are already near 0%.
-- This suggests the overwhelming majority of customers make a first purchase, then do not return again in the following months.
-- Overall, the cohort view strongly confirms that repeat purchase behaviour is extremely limited, at least in pure mathematical retention terms.
-- Among the larger cohorts, Sep 2017, May 2017, and Aug 2017 show the strongest early retention, averaging roughly 0.50%, 0.46%, and 0.43% across months 1 - 3, with month 1 retention around 0.68%, 0.50%, and 0.69% respectively. The highest-revenue cohorts over time are mainly from Nov 2017 and Mar - May 2018.
