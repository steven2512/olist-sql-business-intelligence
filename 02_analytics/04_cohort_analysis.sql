USE Olist;
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
all_purchase_months AS (
    SELECT DISTINCT
        purchase_month
    FROM all_customer_buys
),
cohort_template AS (
    SELECT DISTINCT
        c.cohort_month,
        DATEDIFF(month, c.cohort_month, m.purchase_month) AS month_offset
    FROM (
        SELECT DISTINCT
            cohort_month
        FROM first_customer_buy
    ) c
    INNER JOIN all_purchase_months m
    ON m.purchase_month >= c.cohort_month
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
FROM cohort_filled
ORDER BY cohort_month, month_offset

