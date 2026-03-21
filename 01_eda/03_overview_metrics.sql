USE Olist;

-- 1. Platform Scale
SELECT COUNT(*) AS total_orders 
FROM orders;
-- findings: total 99441 orders

SELECT COUNT(DISTINCT customer_unique_id)
FROM customers;
-- findings: 96096 unique customers

SELECT COUNT(*) AS total_sellers
FROM sellers;
-- findings: 3095 sellers;

SELECT COUNT(*) AS total_products
FROM products;
-- findings: 32951 products

SELECT COUNT(DISTINCT(product_id)) AS total_products_sold
FROM orders o
INNER JOIN order_items i
ON o.order_id = i.order_id
WHERE LOWER(o.order_status) = 'delivered';
-- findings: 32216 products have been sold (based only on orders that has been delivered)

SELECT COUNT(DISTINCT product_category_name) AS total_product_categories
FROM products;
--findings: total of 73 different categories of products

-- Calculate GMV (Gross Merchandise Value)
SELECT SUM(payment_value) AS total_revenue,
        SUM(payment_value) * 0.2 AS estimated_platform_revenue
FROM orders o
INNER JOIN order_payments i
ON o.order_id = i.order_id
WHERE LOWER(o.order_status) = 'delivered';
-- GMV: 15422461.769998817
-- Platform Revenue: 3084492.3539997637 (based on assumption of this project of 20% as the midpoint, refer to README.md for more info)

SELECT AVG(order_value) FROM
(SELECT
    o.order_id,
    SUM(payment_value) AS order_value
FROM orders o  
INNER JOIN order_payments i  
ON o.order_id = i.order_id
WHERE LOWER(order_status) = 'delivered'
GROUP BY o.order_id) v
-- Average order value ~ 159.86

-- 2. Operational Health
SELECT
    order_status,
    ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM orders) * 100, 4) AS delivered_fraction 
FROM orders
GROUP BY order_status
ORDER BY delivered_fraction DESC;
-- ~97% of orders were succesfully delivered

SELECT 
    ROUND(AVG(CAST(review_score AS FLOAT)), 2) AS avg_review_score 
FROM order_reviews;
-- average review rating of 4.09 / 5

SELECT AVG(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) AS avg_delivery_days
FROM orders
WHERE LOWER(order_status) = 'delivered' AND order_purchase_timestamp < order_delivered_customer_date;
-- average delivery time is 12 days

SELECT DISTINCT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) OVER () AS avg_delivery_days
FROM orders
WHERE LOWER(order_status) = 'delivered' AND order_purchase_timestamp < order_delivered_customer_date;
-- median delivery time is 10 days

SELECT 
    ROUND(SUM(freight_value) / 
    (
        SELECT SUM(payment_value) AS total_revenue
        FROM orders o
        INNER JOIN order_payments i
        ON o.order_id = i.order_id
        WHERE LOWER(o.order_status) = 'delivered'
    ) * 100 , 2) AS freight_to_gmv
FROM orders o  
INNER JOIN order_items i
ON o.order_id = i.order_id
WHERE LOWER(o.order_status) = 'delivered'
-- 14.25% of GMV is freight_value



