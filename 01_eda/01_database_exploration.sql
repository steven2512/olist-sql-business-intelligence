-- What tables exist in the database?

SELECT *
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_TYPE = 'BASE TABLE';

-- How many tables are there in the database?
SELECT COUNT(*) AS TOTAL_TABLES
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_TYPE = 'BASE TABLE';

-- How many rows does each table have?
SELECT T.NAME,
       SUM(P.ROWS) AS TOTAL_ROWS
  FROM SYS.TABLES T
INNER JOIN SYS.PARTITIONS P
 WHERE P.INDEX_ID IN ( 0,
                       1 )
 GROUP BY T.NAME;