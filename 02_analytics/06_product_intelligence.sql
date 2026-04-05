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

-- How concentrated are sales among the top products and categories?
;WITH product_revenue AS (
    SELECT
        SUM(i.price + i.freight_value) AS total,
        SUM(SUM(i.price + i.freight_value)) OVER () AS total_revenue,
        CUME_DIST() OVER (ORDER BY SUM(i.price + i.freight_value) DESC) AS percentile
    FROM order_items i
    INNER JOIN orders o
    ON i.order_id = o.order_id
    WHERE LOWER(o.order_status) = 'delivered'
    GROUP BY i.product_id
),
top_5 AS (
    SELECT
        SUM(total) AS top_5_total,
        SUM(total) / MAX(total_revenue) AS top_5_prop
    FROM product_revenue
    WHERE percentile <= 0.05
),
top_10 AS (
    SELECT
        SUM(total) AS top_10_total,
        SUM(total) / MAX(total_revenue) AS top_10_prop
    FROM product_revenue
    WHERE percentile <= 0.10
),
top_20 AS (
    SELECT
        SUM(total) AS top_20_total,
        SUM(total) / MAX(total_revenue) AS top_20_prop
    FROM product_revenue
    WHERE percentile <= 0.20
)
SELECT
    'Products' AS entity_type,
    top_5_total,
    top_5_prop,
    top_10_total,
    top_10_prop,
    top_20_total,
    top_20_prop
FROM top_5
CROSS JOIN top_10
CROSS JOIN top_20;
-- top 5% of products account for 46.3% of revenue
-- top 10% of products account for 59.1% of revenue
-- top 20% of products account for 73.1% of revenue, showing a very concentrated product mix

;WITH category_revenue AS (
    SELECT
        SUM(i.price + i.freight_value) AS total,
        SUM(SUM(i.price + i.freight_value)) OVER () AS total_revenue,
        CUME_DIST() OVER (ORDER BY SUM(i.price + i.freight_value) DESC) AS percentile
    FROM order_items i
    INNER JOIN orders o
    ON i.order_id = o.order_id
    LEFT JOIN products p
    ON i.product_id = p.product_id
    WHERE LOWER(o.order_status) = 'delivered'
    GROUP BY COALESCE(p.product_category_name, 'unknown')
),
top_5 AS (
    SELECT
        SUM(total) AS top_5_total,
        SUM(total) / MAX(total_revenue) AS top_5_prop
    FROM category_revenue
    WHERE percentile <= 0.05
),
top_10 AS (
    SELECT
        SUM(total) AS top_10_total,
        SUM(total) / MAX(total_revenue) AS top_10_prop
    FROM category_revenue
    WHERE percentile <= 0.10
),
top_20 AS (
    SELECT
        SUM(total) AS top_20_total,
        SUM(total) / MAX(total_revenue) AS top_20_prop
    FROM category_revenue
    WHERE percentile <= 0.20
)
SELECT
    'Categories' AS entity_type,
    top_5_total,
    top_5_prop,
    top_10_total,
    top_10_prop,
    top_20_total,
    top_20_prop
FROM top_5
CROSS JOIN top_10
CROSS JOIN top_20;
-- top 5% of categories account for 25.3% of revenue
-- top 10% of categories account for 49.9% of revenue
-- top 20% of categories account for 74.3% of revenue, suggesting revenue is also concentrated at category level, though less dominated by the very top few groups

-- Which products are high volume but low value, and which are high value but low volume?
;WITH product_profile AS (
    SELECT
        i.product_id,
        MAX(COALESCE(p.product_category_name, 'unknown')) AS product_category_name,
        SUM(i.price + i.freight_value) AS total_revenue,
        COUNT(*) AS total_units_sold,
        CAST(SUM(i.price + i.freight_value) AS FLOAT) / NULLIF(COUNT(*), 0) AS avg_unit_revenue,
        CUME_DIST() OVER (ORDER BY COUNT(*) DESC) AS volume_percentile,
        CUME_DIST() OVER (ORDER BY SUM(i.price + i.freight_value) DESC) AS revenue_percentile
    FROM order_items i
    INNER JOIN orders o
    ON i.order_id = o.order_id
    LEFT JOIN products p
    ON i.product_id = p.product_id
    WHERE LOWER(o.order_status) = 'delivered'
    GROUP BY i.product_id
)
SELECT TOP 10
    product_id,
    product_category_name,
    total_units_sold,
    total_revenue,
    avg_unit_revenue
FROM product_profile
WHERE volume_percentile <= 0.20
AND revenue_percentile > 0.20
ORDER BY total_units_sold DESC, total_revenue DESC;
-- High volume but low value products are mostly low-ticket items, with avg unit revenue generally staying around 18 - 30.
-- High value but low volume products are the opposite: they sell only 1 - 3 units, but each unit is very expensive, often above 2k.
-- This suggests some products drive sales through scale, while others contribute through very high ticket size despite weak volume.

;WITH product_profile AS (
    SELECT
        i.product_id,
        MAX(COALESCE(p.product_category_name, 'unknown')) AS product_category_name,
        SUM(i.price + i.freight_value) AS total_revenue,
        COUNT(*) AS total_units_sold,
        CAST(SUM(i.price + i.freight_value) AS FLOAT) / NULLIF(COUNT(*), 0) AS avg_unit_revenue,
        CUME_DIST() OVER (ORDER BY COUNT(*) DESC) AS volume_percentile,
        CUME_DIST() OVER (ORDER BY SUM(i.price + i.freight_value) DESC) AS revenue_percentile
    FROM order_items i
    INNER JOIN orders o
    ON i.order_id = o.order_id
    LEFT JOIN products p
    ON i.product_id = p.product_id
    WHERE LOWER(o.order_status) = 'delivered'
    GROUP BY i.product_id
)
SELECT TOP 10
    product_id,
    product_category_name,
    total_units_sold,
    total_revenue,
    avg_unit_revenue
FROM product_profile
WHERE revenue_percentile <= 0.20
AND volume_percentile > 0.20
ORDER BY total_revenue DESC, total_units_sold DESC;
