USE Olist;
GO

-- 1. How many null values are in all columns of all tables?
-- Build a procedure that displays null counts for each column of each table
CREATE OR ALTER PROCEDURE sp_null_counter AS
BEGIN
	DECLARE @querry NVARCHAR(MAX)
	SELECT
		@querry = STRING_AGG(CAST(
			CONCAT('SELECT ',
			'''',
			table_name,
			'''',
			' AS table_name', 
			', ',
			'''',
			column_name,
			'''',
			' AS column_name',
			', ',
			'COUNT(*) AS null_counts FROM ',
			table_name,
			' WHERE ',
			column_name,
			' IS NULL') AS NVARCHAR(MAX)), ' UNION ALL ') +
			' ORDER BY ' + 'null_counts DESC'
	FROM INFORMATION_SCHEMA.columns
    
	EXEC sp_executesql @querry

END
GO

EXEC sp_null_counter
GO
--Output:
-- order_reviews	review_comment_title	87658
-- order_reviews	review_comment_message	58256
-- orders	order_delivered_customer_date	2965
-- orders	order_delivered_carrier_date	1783
-- products	product_category_name	610
-- products	product_description_lenght	610
-- products	product_name_lenght	610
-- products	product_photos_qty	610
-- orders	order_approved_at	160
-- products	product_height_cm	2
-- products	product_length_cm	2
-- products	product_weight_g	2
-- products	product_width_cm	2
-- customers	customer_city	0
-- customers	customer_id	0
-- customers	customer_state	0
-- customers	customer_unique_id	0
-- customers	customer_zip_code_prefix	0
-- geolocation	geolocation_city	0
-- geolocation	geolocation_lat	0
-- geolocation	geolocation_lng	0
-- geolocation	geolocation_state	0
-- geolocation	geolocation_zip_code_prefix	0
-- order_items	freight_value	0
-- order_items	order_id	0
-- order_items	order_item_id	0
-- order_items	price	0
-- order_items	product_id	0
-- order_items	seller_id	0
-- order_items	shipping_limit_date	0
-- order_payments	order_id	0
-- order_payments	payment_installments	0
-- order_payments	payment_sequential	0
-- order_payments	payment_type	0
-- order_payments	payment_value	0
-- order_reviews	order_id	0
-- order_reviews	review_answer_timestamp	0
-- order_reviews	review_creation_date	0
-- order_reviews	review_id	0
-- order_reviews	review_score	0
-- orders	customer_id	0
-- orders	order_estimated_delivery_date	0
-- orders	order_id	0
-- orders	order_purchase_timestamp	0
-- orders	order_status	0
-- product_category_name_translation	product_category_name	0
-- product_category_name_translation	product_category_name_english	0
-- products	product_id	0
-- sellers	seller_city	0
-- sellers	seller_id	0
-- sellers	seller_state	0
-- sellers	seller_zip_code_prefix	0

--Findings:
-- Order reviews misses a lot of title and comments which is expected
-- 2965 orders at the point of recording this dataset might have yet to been delivered to customers or was never updated
-- 1783 orders at the point of recording this dataset might have yet to been delivered to the carrier or was never updated
-- 160 orders were never approved or have yet to be approved
-- 610 products seems to be missing critical info: category_name, photo, and name, description length
-- 2 products are missing dimentions like height, length, weight, width


-- 2. How many duplicate rows are there in each table?

CREATE OR ALTER PROCEDURE duplicate_counts
AS
BEGIN
	DECLARE @querry NVARCHAR(MAX)
	SELECT
		@querry = STRING_AGG(
			'SELECT '
			+ '''' 
			+ table_name
			+ ''''
			+ ' AS table_name' 
			+ ', '
			+ 'COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM '
			+ table_name
			+ ') t ) AS duplicate_counts FROM '
			+ table_name
			, ' UNION ALL ') 
			+ ' ORDER BY duplicate_counts DESC'
	FROM information_schema.tables
	WHERE TABLE_TYPE = 'BASE TABLE'
	
	EXEC sp_executesql @querry

END
GO
EXEC duplicate_counts
GO
--Findings: geolocation is the only table with duplicate rows (already reported in file 01_database_exploration)
--output
-- geolocation	261831
-- customers	0
-- order_items	0
-- order_payments	0
-- order_reviews	0
-- orders	0
-- product_category_name_translation	0
-- products	0
-- sellers	0

-- 3. Do the values make sense?
-- 3.1 stored procedure to find out all negative values of all numerical columns
CREATE OR ALTER PROCEDURE negative_checks
AS
BEGIN
	DECLARE	@querry NVARCHAR(MAX)

	SELECT 
		@querry = STRING_AGG('SELECT '
		+ ''''
		+ table_name
		+ ''' AS table_name, '
		+ ''''
		+ column_name
		+ ''' AS column_name, '
		+ 'COUNT(*) AS negative_counts FROM '
		+ table_name
		+ ' WHERE '
		+ column_name
		+ ' < 0'
		, ' UNION ALL ') + ' ORDER BY negative_counts DESC'
	FROM INFORMATION_SCHEMA.columns
	WHERE NUMERIC_PRECISION IS NOT NULL
	EXEC sp_executesql @querry
END
GO

EXEC negative_checks
GO

--Output:
-- geolocation	geolocation_lng	1000160
-- geolocation	geolocation_lat	998827
-- customers	customer_zip_code_prefix	0
-- geolocation	geolocation_zip_code_prefix	0
-- order_items	freight_value	0
-- order_items	price	0
-- order_payments	payment_value	0
-- products	product_description_lenght	0
-- products	product_height_cm	0
-- products	product_length_cm	0
-- products	product_name_lenght	0
-- products	product_weight_g	0
-- products	product_width_cm	0
-- sellers	seller_zip_code_prefix	0

--Findings: only geolocation lat and lng has negative values which is already expected, others have no impossible values.

-- 3.2 Zero checks for all columns
CREATE OR ALTER PROCEDURE zero_checks
AS
BEGIN
	DECLARE	@querry NVARCHAR(MAX)

	SELECT 
		@querry = STRING_AGG('SELECT '
		+ ''''
		+ table_name
		+ ''' AS table_name, '
		+ ''''
		+ column_name
		+ ''' AS column_name, '
		+ 'COUNT(*) AS zero_counts FROM '
		+ table_name
		+ ' WHERE '
		+ column_name
		+ ' = 0'
		, ' UNION ALL ') + ' ORDER BY zero_counts DESC'
	FROM INFORMATION_SCHEMA.columns
	WHERE NUMERIC_PRECISION IS NOT NULL
	EXEC sp_executesql @querry
END
GO

EXEC zero_checks

--Output:
-- order_items	freight_value	383
-- order_payments	payment_value	9
-- products	product_weight_g	4
-- customers	customer_zip_code_prefix	0
-- geolocation	geolocation_lat	0
-- geolocation	geolocation_lng	0
-- geolocation	geolocation_zip_code_prefix	0
-- order_items	price	0
-- products	product_description_lenght	0
-- products	product_height_cm	0
-- products	product_length_cm	0
-- products	product_name_lenght	0
-- products	product_width_cm	0
-- sellers	seller_zip_code_prefix	0

-- Findings: Interestingly, there are 9 order_payments that has a value of 0, and 4 products weigh 0g
-- Freight value of 0 could be explained by sellers offering free shippings.

-- 3.3 Consistency
--Chronological Orders Of timestamps in reviews
SELECT COUNT(*) FROM order_reviews
WHERE review_creation_date >= review_answer_timestamp;
-- output: 0
-- all review timestamps make sense (creation before answer)

--Chronological Orders of timestamps in orders
SELECT COUNT(*) AS incorrect_timestamp_orders
FROM orders
WHERE NOT (
	 order_purchase_timestamp
	  < order_approved_at 
	 AND order_approved_at 
	  < order_delivered_carrier_date
	 AND order_delivered_carrier_date 
	  < order_delivered_customer_date
	 );
-- output: 2686
-- Findings: 2686 orders have incorrect chronoglocial orders of timestamps (excluded NULL timestamps which might have a valid reason)

-- Identifying gaps in sequential columns
-- order_items have order_item_id which is supposed to be sequentaial for each order_id
SELECT COUNT(*) AS order_item_gap_counts
FROM 
(SELECT
	order_id
FROM order_items
GROUP BY order_id
HAVING SUM(CAST(order_item_id AS INT))
      != COUNT(*) * (COUNT(*) + 1) /2 ) t;
--approach: sum of the group of n integers = sum of the arithemetic series must hold to have no gaps

--output: 0 - no gaps found in any of the order_id, order_item_id combination

--order_payments have payment_sequential which is supposed to be sequential for each order_id
SELECT COUNT(*) AS order_payment_gap_counts
FROM 
(SELECT
	order_id
FROM order_payments
GROUP BY order_id
HAVING SUM(CAST(payment_sequential AS INT))
	!= COUNT(*) * (COUNT(*) +1) / 2 ) p;

--Findings: suprisingly, 80 orders have gaps in the numbering of the payment parts. 

SELECT
	min_sequential_numbering,
	max_sequential_numbering,
	COUNT(*) AS total
FROM
(SELECT
	order_id,
	MIN(payment_sequential) AS min_sequential_numbering,
	MAX(payment_sequential) AS max_sequential_numbering
FROM
(SELECT
	t.order_id,
	o.payment_sequential
FROM order_payments o
INNER JOIN
(SELECT
	order_id
FROM order_payments
GROUP BY order_id
HAVING SUM(CAST(payment_sequential AS INT))
	!= COUNT(*) * (COUNT(*) +1) / 2
) t	
ON o.order_id = t.order_id) p
GROUP BY order_id) g
GROUP BY min_sequential_numbering, max_sequential_numbering;

-- Further analysis shows that 78/80 orders have a single payment part numbering at 2
-- 2/80 have 2 payment parts starting at 2 and ending at 3
-- however almost every other payment starts at 1, which suggests missing or inconsistent numbering

-- 4. Referrential Integrity

--customer_id in customers and orders
SELECT * FROM INFORMATION_SCHEMA.columns

SELECT
	*
FROM orders o
LEFT JOIN customers c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

SELECT * FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL

SELECT * FROM customers
WHERE customer_id IS NULL

-- interesting findings: every single customer in customers table have placed at least an order, and based on findings in file 01_database_exploration and documentation from Olist, every row is an order participant (could be same customer) so anyone who hasn't placed any order would not be included in the table at all.

--order_id in order_payments, order_reviews, and order_items
 SELECT p.order_id
 FROM order_payments p
 LEFT JOIN orders o
 ON p.order_id = o.order_id
 WHERE o.order_id IS NULL
 
 UNION ALL
 SELECT r.order_id
 FROM order_reviews r
 LEFT JOIN orders o
 ON r.order_id = o.order_id
 WHERE o.order_id IS NULL
 
 UNION ALL
 SELECT i.order_id
 FROM order_items i
 LEFT JOIN orders o
 ON i.order_id = o.order_id
 WHERE o.order_id IS NULL

--product_category_name inproducts and product_category_name_translation
SELECT
    *
FROM product_category_name_translation t
LEFT JOIN products p
ON t.product_category_name = p.product_category_name
WHERE p.product_category_name IS NULL

--prdouct_id in products and order_items
SELECT
    *
FROM order_items i
LEFT JOIN products p
ON i.product_id = p.product_id
WHERE p.product_id IS NULL

--seller_id in sellers and order_items

SELECT
    *
FROM order_items i
LEFT JOIN sellers s
ON i.seller_id = s.seller_id
WHERE s.seller_id IS NULL

-- zip_code_prefix, seller_zip_code_prefix, customer_zip_code_prefix in geolocation, customers, and sellers
SELECT COUNT(*) AS total
FROM sellers s
LEFT JOIN geolocation g
ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL

SELECT COUNT(*) AS total
FROM customers c
LEFT JOIN geolocation g
ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL
-- total of 7 sellers have zip code prefix that does not exist in geolocation
-- total 278 customers have zip code prefix that does not exist in geolocation

--Findings: all referecing columns in child table have a matching records in their parents table except for zip code prefix from customers and sellers to the parent table of geolocation

-- Notice: 'foreign keys' words are not used here since technically we imported flat files and no relationships were defined like in a formal database
-- All relationships here are inffered based on experienc and basic intuition

-- customer_state, payment_type
SELECT 
	payment_type,
	COUNT(*) AS total
FROM order_payments
GROUP BY payment_type;
-- 3 payments have type not_defined, which is unusual

SELECT
	review_score,
	COUNT(*) AS total
FROM order_reviews
GROUP BY review_score
-- review scores contains 1 -> 5 which is expected

SELECT
	order_status,
	COUNT(*) AS total
FROM orders
GROUP BY order_status
-- all 8 order status makes sense
 






