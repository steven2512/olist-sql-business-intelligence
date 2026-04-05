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

SELECT * FROM #top_10_rev tr
INNER JOIN #top_10_volume tv  
ON tr.seller_id = tv.seller_id
-- 5 out of 10 sellers with highest revenue also appears in the top 10 of highest amount of orders

-- How concentrated is performance among the top sellers?

WITH sellers_revenue AS (
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



