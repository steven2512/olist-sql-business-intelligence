-- 1. What tables exist in the database?
SELECT *
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_TYPE = 'BASE TABLE';

-- Findings:
-- tables: 
  -- sellers
  -- products
  -- product_category_name_translation
  -- orders
  -- order_reviews
  -- order_payments
  -- order_items
  -- geolocation
  -- customers


-- 2. How many tables are there in the database?
SELECT COUNT(*) AS TOTAL_TABLES
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_TYPE = 'BASE TABLE';

-- Findings:
-- total tables: 9


-- 3. How many rows does each table have?
SELECT T.NAME,
       SUM(P.ROWS) AS TOTAL_ROWS
  FROM SYS.TABLES T
 INNER JOIN SYS.PARTITIONS P
ON T.OBJECT_ID = P.OBJECT_ID
 WHERE P.INDEX_ID IN ( 0,
                       1 )
 GROUP BY T.NAME;

-- Findings:
-- customers	99441
-- geolocation	1000163
-- order_items	112650
-- order_payments	103886
-- order_reviews	99224
-- orders	99441
-- product_category_name_translation	72
-- products	32951
-- sellers	3095