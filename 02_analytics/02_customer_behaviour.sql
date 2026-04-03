USE Olist;
-- How many orders does a typical customer place
WITH base AS 
(SELECT
    customer_unique_id,
    COUNT(*) AS val
FROM orders o  
INNER JOIN customers c  
ON o.customer_id = c.customer_id
WHERE LOWER(o.order_status) = 'delivered'
GROUP BY c.customer_unique_id),

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

-- shape: extreme right-skewed, with majority of customers place exactly 1 order. thin long tail with 1 peak (unimodal)
-- center: right-skewed suggests median is more of a typical total orders a customer place at exactly 1 order.
-- spread: customers range from 1 -> 15 orders, but 50% of customers place exactly 1 order (IQR: 1), in reality, majority of customers place exactly 1 order.
-- Taking into the context of the next question (97% of customers are one-time), it makes sense how most customers place exactly 1 order.


-- What share of customers purchase only once versus more than once?
WITH customer_orders AS
(SELECT
    customer_unique_id,
    COUNT(*) AS val
FROM orders o  
INNER JOIN customers c  
ON o.customer_id = c.customer_id
WHERE LOWER(o.order_status) = 'delivered'
GROUP BY c.customer_unique_id),
total_orders AS (
    SELECT 
        COUNT(*) AS total_one_order,
        CAST(COUNT(*) AS FLOAT) / 
        (SELECT COUNT(*) FROM customer_orders) AS one_order_proportion,
         1 - CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*)
         FROM customer_orders) AS more_order_proportion
    FROM customer_orders
    WHERE val = 1
) SELECT * FROM total_orders;

-- ~97% of customers purchased only once, and 3% of customers purchase more than once

-- How long does it typically take for a customer to place a second order?
WITH base AS
(SELECT
    date_diff AS val
FROM (
SELECT
    customer_unique_id,
    DATEDIFF(day, LAG(order_purchase_timestamp) OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp), order_purchase_timestamp) AS date_diff
FROM (
SELECT
    customer_unique_id,
    order_purchase_timestamp,
    COUNT(*) OVER (PARTITION BY customer_unique_id) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp) AS order_no
FROM customers c  
INNER JOIN orders o  
ON c.customer_id = o.customer_id
WHERE LOWER(o.order_status) = 'delivered') t
WHERE total_orders > 1 AND order_no <= 2 ) t2
WHERE date_diff IS NOT NULL )
,
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

-- shape: highly right-skewed distribution, with a long fat tail. Most customers take a shorter amount of time to place a 2nd order. Unimodal with 1 peak.
-- center: since it's a right-skewed distribution, the median of 29 days is a better representation than the mean of 81 days. So typically, a repeating customer would place a second order about a month after their first one.
-- spread: customers took anywhere from 0 -> 609 days to place a second order. However, 50% of customers lie within a wide band of 0 -> 126 days before placing a second order (IQR: 126)

-- Do repeat customers spend more per order than one-time customers?

WITH customers_spent AS (
SELECT
    customer_unique_id,
    COUNT(*) AS total_orders,
    AVG(order_value) AS avg_spent
FROM customers c  
INNER JOIN orders o  
ON c.customer_id = o.customer_id
INNER JOIN (
    SELECT
        order_id,
        SUM(payment_value) AS order_value
    FROM 
    order_payments
    GROUP BY order_id) p
ON o.order_id = p.order_id
WHERE LOWER(o.order_status) = 'delivered'
GROUP BY customer_unique_id
)
SELECT AVG(avg_spent) AS avg_spent_repeating, 
    (SELECT AVG(avg_spent) 
    FROM customers_spent 
    WHERE total_orders = 1) AS avg_spent_one_time
FROM customers_spent
WHERE total_orders > 1

-- typically, one-time-customer spends more than average compared to repeating customer (161.81 > 148.5)

--Do repeat customers buy more items per order than one-time customers?
WITH customers_items AS (
SELECT
    customer_unique_id,
    COUNT(*) AS total_orders,
    AVG(CAST(total_item AS FLOAT)) AS avg_items
FROM customers c  
INNER JOIN orders o  
ON c.customer_id = o.customer_id

INNER JOIN (
    SELECT
        order_id,
        COUNT(*) AS total_item
    FROM 
    order_items
    GROUP BY order_id) i
ON o.order_id = i.order_id
WHERE LOWER(o.order_status) = 'delivered'
GROUP BY customer_unique_id
)
SELECT AVG(CAST(avg_items AS FLOAT)) AS avg_items_repeating, 
    (SELECT AVG(CAST(avg_items AS FLOAT))
    FROM customers_items 
    WHERE total_orders = 1) AS avg_items_one_time
FROM customers_items
WHERE total_orders > 1

-- Repeating customers typically buy slightly more items per order compared to one-time customer (1.21 > 1.13)


