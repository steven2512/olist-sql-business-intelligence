-- What tables exist in the database?

SELECT *
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_TYPE = 'BASE TABLE';

-- How many tables are there in the database?
SELECT COUNT(*) AS TOTAL_TABLES
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_TYPE = 'BASE TABLE';

-- How many rows does each table have?
SELECT
    t.name,
    SUM(p.rows) AS total_rows
FROM sys.tables t
INNER JOIN sys.partitions p
WHERE p.index_id IN (0,1)