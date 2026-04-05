SELECT TOP 10
    s.seller_id,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(*) AS total_units_sold,
    SUM(price + freight_value) AS revenue
FROM sellers s  
INNER JOIN order_items i  
ON s.seller_id = i.seller_id
GROUP BY s.seller_id
ORDER BY revenue DESC

SELECT TOP 10
    s.seller_id,
    COUNT(DISTINCT order_id) AS total_orders
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

