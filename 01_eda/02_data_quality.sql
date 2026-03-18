-- 1. How many null values are in all columns of all tables?
-- Build a procedure that displays null counts for each column of each table
DROP PROCEDURE IF EXISTS sp_null_counter;
GO

CREATE PROCEDURE sp_null_counter AS
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
			' IS NULL') AS NVARCHAR(MAX)), ' UNION ALL ')
	FROM INFORMATION_SCHEMA.columns
    
    CREATE TABLE null_count_result (
        table_name NVARCHAR(100),
        column_name NVARCHAR(100),
        null_counts INT
    )
    
    INSERT INTO null_count_result
	EXEC sp_executesql @querry
	
	SELECT * FROM null_count_result
END
GO

EXEC sp_null_counter


DROP TABLE IF EXISTS null_count_result;

--Approach: build a count NA query string for each table + column combination then use stored procedure sp_executesql to execute that querry in 1 pass
-- Result: 1 table with table_name, column_name, and null_counts

