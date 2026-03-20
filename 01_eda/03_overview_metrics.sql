USE Olist;

-- 1. Volume counts
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

-- 2. Revenue Snapshot
-- Calculate GMV (Gross Merchandise Value - all money that actually flows through Olist)
SELECT SUM(payment_value) AS total_revenue
FROM orders o
INNER JOIN order_payments i
ON o.order_id = i.order_id
WHERE LOWER(o.order_status) = 'delivered';
-- GMV: 15422461.769998817

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


