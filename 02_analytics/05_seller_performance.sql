USE Olist;
DROP TABLE IF EXISTS #top_10_rev;
DROP TABLE IF EXISTS #top_10_volume;

-- Which sellers generate the most orders, revenue, and units sold?
SELECT TOP 10
    s.seller_id,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(*) AS total_units_sold,
    SUM(price + freight_value) AS revenue
INTO #top_10_rev
FROM sellers s  
INNER JOIN order_items i  
ON s.seller_id = i.seller_id
GROUP BY s.seller_id
ORDER BY revenue DESC

SELECT TOP 10
    s.seller_id,
    COUNT(DISTINCT order_id) AS total_orders
INTO #top_10_volume
FROM sellers s  
INNER JOIN order_items i  
ON s.seller_id = i.seller_id
GROUP BY s.seller_id
ORDER BY total_orders DESC


SELECT TOP 10
    s.seller_id,
    COUNT(*) AS total_units_sold
FROM sellers s  
INNER JOIN order_items i  
ON s.seller_id = i.seller_id
GROUP BY s.seller_id
ORDER BY total_units_sold DESC

SELECT
    tr.seller_id,
    tr.total_orders AS revenue_top_10_total_orders,
    tr.total_units_sold,
    tr.revenue,
    tv.total_orders AS volume_top_10_total_orders
FROM #top_10_rev tr
INNER JOIN #top_10_volume tv  
ON tr.seller_id = tv.seller_id
-- 5 out of 10 sellers with highest revenue also appears in the top 10 of highest amount of orders

-- How concentrated is performance among the top sellers?

;WITH sellers_revenue AS (
    SELECT
        SUM(price + freight_value) AS total,
        SUM(SUM(price + freight_value)) OVER () AS total_rev,
        CUME_DIST() OVER (ORDER BY SUM(price + freight_value) DESC) AS percentile
    FROM sellers s  
    INNER JOIN order_items i  
    ON s.seller_id = i.seller_id
    WHERE i.order_id IN (SELECT order_id FROM orders WHERE LOWER(order_status) = 'delivered')
    GROUP BY s.seller_id
), top_5 AS (
    SELECT
        SUM(total) AS top_5_total,
        SUM(total) / MAX(total_rev) AS top_5_prop
    FROM sellers_revenue
    WHERE percentile <= 0.05      
),
top_10 AS (
    SELECT
        SUM(total) AS top_10_total,
        SUM(total) / MAX(total_rev) AS top_10_prop
    FROM sellers_revenue
    WHERE percentile <= 0.10
),
top_20 AS (
    SELECT
        SUM(total) AS top_20_total,
        SUM(total) / MAX(total_rev) AS top_20_prop
    FROM sellers_revenue
    WHERE percentile <= 0.20
)
SELECT
    'Sellers' AS entity_type,
    top_5_total,
    top_5_prop,
    top_10_total,
    top_10_prop,
    top_20_total,
    top_20_prop
FROM top_5
CROSS JOIN top_10
CROSS JOIN top_20;

-- top 5% of sellers is accounted for 52% of GMV
-- top 10% of sellers is accoutned for 66% of GMV
-- top 20% of sellers is account for 82% of GMV
-- Overall, the GMV is extremely concentrated, with top 20% of sellers accounts for over 80% of GMV, suggesting an extremely disproportionate distribution, with higher value sellers accounts for majority of the GMV

-- Are top sellers also stronger in reviews or delivery performance?
SELECT AVG(avg_rating) FROM (
SELECT
    seller_id,
    AVG(CAST(review_score AS FLOAT)) AS avg_rating
 FROM
(SELECT DISTINCT 
    s.seller_id,
    o.order_id   
FROM sellers s  
INNER JOIN order_items i  
ON s.seller_id = i.seller_id
INNER JOIN orders o  
ON i.order_id = o.order_id
) t
INNER JOIN order_reviews r  
ON t.order_id = r.order_id
GROUP BY seller_id ) t2

-- avg rating of ~4.0, surprisingly lower than 4.09 average rating across all sellers

-- Delivery Performance
SELECT AVG(CAST(avg_delivery_days AS FLOAT)) AS avg_delivery_days_top_sellers
FROM (
SELECT
    seller_id,
    AVG(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) AS avg_delivery_days
FROM
(SELECT DISTINCT 
    s.seller_id,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_id   
FROM #top_10_rev s
INNER JOIN order_items i  
ON s.seller_id = i.seller_id
INNER JOIN orders o  
ON i.order_id = o.order_id
) t
GROUP BY seller_id ) t2
-- avg: 13.1 days even slightly higher than overall average of 12 days (so pretty much the same as every other seller)


-- Which sellers are growing or declining over time?
;WITH seller_monthly_revenue AS (
    SELECT
        t.seller_id,
        CAST(DATETRUNC(month, o.order_purchase_timestamp) AS date) AS month_year,
        SUM(i.price + i.freight_value) AS month_revenue
    FROM #top_10_rev t
    INNER JOIN order_items i
    ON t.seller_id = i.seller_id
    INNER JOIN orders o
    ON i.order_id = o.order_id
    GROUP BY
        t.seller_id,
        DATETRUNC(month, o.order_purchase_timestamp)
),
seller_trend AS (
    SELECT
        seller_id,
        month_year,
        month_revenue,
        ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY month_year) AS first_month_order,
        ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY month_year DESC) AS last_month_order
    FROM seller_monthly_revenue
)
SELECT
    seller_id,
    month_year,
    month_revenue
FROM seller_monthly_revenue
ORDER BY seller_id, month_year;

;WITH seller_monthly_revenue AS (
    SELECT
        t.seller_id,
        CAST(DATETRUNC(month, o.order_purchase_timestamp) AS date) AS month_year,
        SUM(i.price + i.freight_value) AS month_revenue
    FROM #top_10_rev t
    INNER JOIN order_items i
    ON t.seller_id = i.seller_id
    INNER JOIN orders o
    ON i.order_id = o.order_id
    GROUP BY
        t.seller_id,
        DATETRUNC(month, o.order_purchase_timestamp)
),
seller_trend AS (
    SELECT
        seller_id,
        month_year,
        month_revenue,
        ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY month_year) AS first_month_order,
        ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY month_year DESC) AS last_month_order
    FROM seller_monthly_revenue
)
SELECT
    f.seller_id,
    f.month_year AS first_active_month,
    f.month_revenue AS first_month_revenue,
    l.month_year AS last_active_month,
    l.month_revenue AS last_month_revenue,
    l.month_revenue - f.month_revenue AS revenue_change,
    CAST((l.month_revenue - f.month_revenue) * 100.0 / NULLIF(f.month_revenue, 0) AS FLOAT) AS revenue_change_pct
FROM seller_trend f
INNER JOIN seller_trend l
ON f.seller_id = l.seller_id
WHERE f.first_month_order = 1
AND l.last_month_order = 1
ORDER BY revenue_change DESC;

-- Most of the top revenue sellers end the dataset at a higher monthly revenue than where they started, suggesting growth is concentrated in a few strong gainers rather than evenly shared across all top sellers.
-- In raw volume, the strongest gainers are sellers 1025f0..., 4869f7..., and 955fee..., with first-to-last active month revenue increases of roughly 19.5k, 14.4k, and 8.1k respectively.
-- In percentage terms, seller 1025f0... and 955fee... grow the fastest at roughly 1263% and 1248%, while seller 4869f7... also grows strongly at about 841%.
-- On the other hand, seller 532435... shows the sharpest raw decline at about -17.3k, while seller 7e93a4... has the steepest percentage drop at roughly -84% from its first active month to its last.


