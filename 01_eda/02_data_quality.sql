-- 1. How many null values are in all columns of all tables?

DROP PROCEDURE IF EXISTS name_count;
GO

CREATE PROCEDURE name_count
AS
BEGIN
	-- all table names and their columns
	SELECT
		table_name,
		column_name
	INTO #table_column
	FROM information_schema.columns

	-- same table as above but extra column for null counts
	SELECT
		table_name,
		column_name,
		0 AS total_null_count
	INTO #null_count
	FROM information_schema.columns
	
	--extract table_name and column_name line by line
	--and find total null counts
	--then update it to #null_count
	WHILE EXISTS (SELECT * FROM #table_column)
	BEGIN
		DECLARE @tbl NVARCHAR(50)
		DECLARE @col NVARCHAR(50)
		DECLARE @total_count INT
		DECLARE @querry NVARCHAR(MAX)
		
		SELECT TOP 1
			@tbl = table_name,
			@col = column_name
		FROM #table_column

		SET @querry = 'SELECT @total_count = COUNT(*) FROM ' 
						+ @tbl + 
						' WHERE ' + @col + ' IS NULL'
		EXEC sp_executesql 
			@querry,
			N'@total_count INT OUTPUT',
			@total_count OUTPUT


		UPDATE #null_count 
		SET total_null_count = @total_count
		WHERE table_name = @tbl AND column_name = @col

		DELETE FROM #table_column
		WHERE table_name = @tbl AND column_name = @col
		
	END
	
	SELECT * FROM #null_count;
END
GO

EXEC name_count;