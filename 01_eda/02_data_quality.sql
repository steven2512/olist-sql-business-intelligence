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









