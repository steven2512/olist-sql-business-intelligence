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

-- 4. How many columns do each table have?
SELECT TABLE_NAME,
       COUNT(*) AS TOTAL_COLUMNS
  FROM INFORMATION_SCHEMA.COLUMNS
 GROUP BY TABLE_NAME;

-- Findings:
-- customers	5
-- geolocation	5
-- order_items	7
-- order_payments	5
-- order_reviews	7
-- orders	8
-- product_category_name_translation	2
-- products	9
-- sellers	4

--5. What are the columns of each table and their data type?
SELECT TABLE_NAME,
       COLUMN_NAME,
       DATA_TYPE
  FROM INFORMATION_SCHEMA.COLUMNS
 ORDER BY TABLE_NAME,
          ORDINAL_POSITION;

-- Findings:
-- customers	customer_id	nvarchar
-- customers	customer_unique_id	nvarchar
-- customers	customer_zip_code_prefix	int
-- customers	customer_city	nvarchar
-- customers	customer_state	nvarchar
-- geolocation	geolocation_zip_code_prefix	int
-- geolocation	geolocation_lat	float
-- geolocation	geolocation_lng	float
-- geolocation	geolocation_city	nvarchar
-- geolocation	geolocation_state	nvarchar
-- order_items	order_id	nvarchar
-- order_items	order_item_id	nvarchar
-- order_items	product_id	nvarchar
-- order_items	seller_id	nvarchar
-- order_items	shipping_limit_date	datetime2
-- order_items	price	float
-- order_items	freight_value	float
-- order_payments	order_id	nvarchar
-- order_payments	payment_sequential	nvarchar
-- order_payments	payment_type	nvarchar
-- order_payments	payment_installments	nvarchar
-- order_payments	payment_value	float
-- order_reviews	review_id	nvarchar
-- order_reviews	order_id	nvarchar
-- order_reviews	review_score	nvarchar
-- order_reviews	review_comment_title	nvarchar
-- order_reviews	review_comment_message	nvarchar
-- order_reviews	review_creation_date	datetime2
-- order_reviews	review_answer_timestamp	datetime2
-- orders	order_id	nvarchar
-- orders	customer_id	nvarchar
-- orders	order_status	nvarchar
-- orders	order_purchase_timestamp	datetime2
-- orders	order_approved_at	datetime2
-- orders	order_delivered_carrier_date	datetime2
-- orders	order_delivered_customer_date	datetime2
-- orders	order_estimated_delivery_date	datetime2
-- product_category_name_translation	column1	nvarchar
-- product_category_name_translation	column2	nvarchar
-- products	product_id	nvarchar
-- products	product_category_name	nvarchar
-- products	product_name_lenght	int
-- products	product_description_lenght	int
-- products	product_photos_qty	nvarchar
-- products	product_weight_g	int
-- products	product_length_cm	int
-- products	product_height_cm	int
-- products	product_width_cm	int
-- sellers	seller_id	nvarchar
-- sellers	seller_zip_code_prefix	int
-- sellers	seller_city	nvarchar
-- sellers	seller_state	nvarchar

-- 4. What are the grains of the tables?
SELECT ORDER_ID
  FROM ORDERS
 GROUP BY ORDER_ID
HAVING COUNT(*) > 1;
-- order_id is the primary key -> grain = one unique order

SELECT CUSTOMER_ID
  FROM CUSTOMERS
 GROUP BY CUSTOMER_ID
HAVING COUNT(*) > 1;
-- customer_id is the primary key -> grain = one unique customer

SELECT PRODUCT_ID
  FROM PRODUCTS
 GROUP BY PRODUCT_ID
HAVING COUNT(*) > 1;
-- product_id is the primary_key -> grain = one unique product

SELECT REVIEW_ID,
       ORDER_ID
  FROM ORDER_REVIEWS
 GROUP BY REVIEW_ID,
          ORDER_ID
HAVING COUNT(*) > 1;
-- review_id, order_id is composite primary key -> grain = a unique order within a review

SELECT SELLER_ID
  FROM SELLERS
 GROUP BY SELLER_ID
HAVING COUNT(*) > 1;
-- seller_id is the primary key -> grain = a unique seller