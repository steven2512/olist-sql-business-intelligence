USE Olist;
GO

-- 1. How many null values are in all columns of all tables?
-- Build a procedure that displays null counts for each column of each table
CREATE OR ALTER PROCEDURE sp_null_counter AS
BEGIN
	DROP TABLE IF EXISTS null_count_result;
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




