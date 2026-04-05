USE Olist;
DROP TABLE IF EXISTS #top_10_product_revenue;
DROP TABLE IF EXISTS #top_10_category_revenue;

-- Which products and categories generate the most revenue, order frequency, and units sold?
SELECT TOP 10
    i.product_id,
    MAX(COALESCE(p.product_category_name, 'unknown')) AS product_category_name,
    SUM(i.price + i.freight_value) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_units_sold,
    DATEDIFF(month, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp)) + 1 AS active_months,
    CAST(COUNT(DISTINCT o.order_id) AS FLOAT)
        / NULLIF(DATEDIFF(month, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp)) + 1, 0)
        AS avg_orders_per_active_month
INTO #top_10_product_revenue
FROM order_items i
INNER JOIN orders o
ON i.order_id = o.order_id
LEFT JOIN products p
ON i.product_id = p.product_id
WHERE LOWER(o.order_status) = 'delivered'
GROUP BY i.product_id
ORDER BY total_revenue DESC;

SELECT *
FROM #top_10_product_revenue
ORDER BY total_revenue DESC;

SELECT TOP 10
    i.product_id,
    MAX(COALESCE(p.product_category_name, 'unknown')) AS product_category_name,
    SUM(i.price + i.freight_value) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_units_sold,
    DATEDIFF(month, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp)) + 1 AS active_months,
    CAST(COUNT(DISTINCT o.order_id) AS FLOAT)
        / NULLIF(DATEDIFF(month, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp)) + 1, 0)
        AS avg_orders_per_active_month
FROM order_items i
INNER JOIN orders o
ON i.order_id = o.order_id
LEFT JOIN products p
ON i.product_id = p.product_id
WHERE LOWER(o.order_status) = 'delivered'
GROUP BY i.product_id
ORDER BY total_orders DESC;

SELECT TOP 10
    i.product_id,
    MAX(COALESCE(p.product_category_name, 'unknown')) AS product_category_name,
    SUM(i.price + i.freight_value) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_units_sold
FROM order_items i
INNER JOIN orders o
ON i.order_id = o.order_id
LEFT JOIN products p
ON i.product_id = p.product_id
WHERE LOWER(o.order_status) = 'delivered'
GROUP BY i.product_id
ORDER BY total_units_sold DESC;

SELECT TOP 10
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    SUM(i.price + i.freight_value) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_units_sold,
    DATEDIFF(month, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp)) + 1 AS active_months,
    CAST(COUNT(DISTINCT o.order_id) AS FLOAT)
        / NULLIF(DATEDIFF(month, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp)) + 1, 0)
        AS avg_orders_per_active_month
INTO #top_10_category_revenue
FROM order_items i
INNER JOIN orders o
ON i.order_id = o.order_id
LEFT JOIN products p
ON i.product_id = p.product_id
WHERE LOWER(o.order_status) = 'delivered'
GROUP BY COALESCE(p.product_category_name, 'unknown')
ORDER BY total_revenue DESC;

SELECT *
FROM #top_10_category_revenue
ORDER BY total_revenue DESC;

SELECT TOP 10
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    SUM(i.price + i.freight_value) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_units_sold,
    DATEDIFF(month, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp)) + 1 AS active_months,
    CAST(COUNT(DISTINCT o.order_id) AS FLOAT)
        / NULLIF(DATEDIFF(month, MIN(o.order_purchase_timestamp), MAX(o.order_purchase_timestamp)) + 1, 0)
        AS avg_orders_per_active_month
FROM order_items i
INNER JOIN orders o
ON i.order_id = o.order_id
LEFT JOIN products p
ON i.product_id = p.product_id
WHERE LOWER(o.order_status) = 'delivered'
GROUP BY COALESCE(p.product_category_name, 'unknown')
ORDER BY total_orders DESC;

SELECT TOP 10
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    SUM(i.price + i.freight_value) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS total_units_sold
FROM order_items i
INNER JOIN orders o
ON i.order_id = o.order_id
LEFT JOIN products p
ON i.product_id = p.product_id
WHERE LOWER(o.order_status) = 'delivered'
GROUP BY COALESCE(p.product_category_name, 'unknown')
ORDER BY total_units_sold DESC;
