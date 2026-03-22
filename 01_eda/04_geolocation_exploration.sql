USE Olist;
-- 1. Data structure and quality
SELECT GEOLOCATION_ZIP_CODE_PREFIX,
       GEOLOCATION_LAT,
       GEOLOCATION_LNG,
       GEOLOCATION_CITY,
       GEOLOCATION_STATE
  FROM GEOLOCATION
 GROUP BY GEOLOCATION_ZIP_CODE_PREFIX,
          GEOLOCATION_LAT,
          GEOLOCATION_LNG,
          GEOLOCATION_CITY,
          GEOLOCATION_STATE
HAVING COUNT(*) > 1;

SELECT 
COUNT(DISTINCT geolocation_zip_code_prefix)
FROM geolocation
-- There are 19015 distinct geographic units exist
--No candidate keys found -> table contain many rows duplicates
-- 261831 exact duplicates out of 1000163 rows
-- Some rows also have different accent of the city name, while every other column is identical
-- This suggests that this dataset might possibly be imported from multiple sources (or an uncleaned source) and the author did not perform deduplications
-- Also inconsistencies happened with 8 zip code prefixes (same prefix, but different states -> which is impossible in real world)
-- Grain (originally intended): one district per zip code prefix
-- Grain (actually is): one geographical sample point in a district per row - non unique

-- For the conflicting zip codes -> states situation. Majority voting has been applied
DROP TABLE IF EXISTS #zip_code_and_state;
SELECT 
    geolocation_zip_code_prefix,
    geolocation_state
INTO #zip_code_and_state
FROM
(SELECT
    geolocation_zip_code_prefix,
    geolocation_state,
    ROW_NUMBER() OVER (PARTITION BY geolocation_zip_code_prefix ORDER BY total DESC) AS numbering
FROM (SELECT
    geolocation_zip_code_prefix,
    geolocation_state,
    COUNT(*) AS total,
    MAX(COUNT(*)) OVER (PARTITION BY  geolocation_zip_code_prefix) AS majority_count
FROM geolocation
GROUP BY geolocation_zip_code_prefix, geolocation_state ) t
WHERE total = majority_count ) t2
WHERE numbering = 1;

SELECT COUNT(*) AS total_nulls
FROM geolocation
WHERE geolocation_lat IS NULL
OR geolocation_lng IS NULL
-- Findings: no missing lat or long on any sample point

SELECT COUNT(*) AS out_of_bounds_total FROM geolocation 
WHERE geolocation_lat NOT BETWEEN -33.74 AND 5.27
OR geolocation_lng NOT BETWEEN -73.98 AND -34.73
-- Findings: total of 42 sample points are potentially outside of Brazil's coordinate bounds

-- 2. Coverage and flow
SELECT DISTINCT   
    geolocation_state,
    COUNT(*) AS total,
    ROUND(CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER () * 100 , 2) AS proportion
FROM customers c  
INNER JOIN #zip_code_and_state z
ON c.customer_zip_code_prefix = z.geolocation_zip_code_prefix
GROUP BY geolocation_state
ORDER BY total DESC;
-- Findings: Roughly 42% of all customers are located in SP (Sao Paulo) (41731 customers). 
-- The top 5 states SP, RJ, MG, RS, PR alone accounts for over 75% of all customers

SELECT DISTINCT  
    geolocation_state,
    COUNT(*) AS total,
    ROUND(CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER () * 100 , 2) AS proportion
FROM sellers s  
INNER JOIN #zip_code_and_state z  
ON s.seller_zip_code_prefix = z.geolocation_zip_code_prefix
GROUP BY z.geolocation_state
ORDER BY total DESC;
-- Findings: Roughly 59% of all sellers are located in SP (Sao Paulo) (1814 sellers). 
-- SP and PR alone acounts for over 70% of all sellers

SELECT DISTINCT   
    z.geolocation_state
FROM customers c  
INNER JOIN #zip_code_and_state z
ON c.customer_zip_code_prefix = z.geolocation_zip_code_prefix

LEFT JOIN
(SELECT DISTINCT  
    geolocation_state
FROM sellers s  
INNER JOIN #zip_code_and_state z  
ON s.seller_zip_code_prefix = z.geolocation_zip_code_prefix) t
ON z.geolocation_state = t.geolocation_state
WHERE t.geolocation_state IS NULL
;
-- Findings: There are 5 states that has orders yet there are 0 sellers located in those states

SELECT DISTINCT  
    z.geolocation_state
FROM sellers s  
INNER JOIN #zip_code_and_state z  
ON s.seller_zip_code_prefix = z.geolocation_zip_code_prefix

LEFT JOIN
(SELECT DISTINCT   
    z.geolocation_state
FROM customers c  
INNER JOIN #zip_code_and_state z
ON c.customer_zip_code_prefix = z.geolocation_zip_code_prefix) t
ON z.geolocation_state = t.geolocation_state
WHERE t.geolocation_state IS NULL;
-- Findings: On the other hand, there exists customers in every state that has sellers.

SELECT
    cross_region_flag,
    COUNT(*) AS total,
    ROUND(CAST (COUNT(*) AS FLOAT)/ SUM(COUNT(*)) OVER () * 100 , 2) AS proportion
FROM (
    SELECT
        CASE WHEN zc.geolocation_state = zs.geolocation_state THEN 0 ELSE 1 END AS cross_region_flag
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN customers c ON o.customer_id = c.customer_id
    INNER JOIN sellers s ON oi.seller_id = s.seller_id
    INNER JOIN #zip_code_and_state zc ON c.customer_zip_code_prefix = zc.geolocation_zip_code_prefix
    INNER JOIN #zip_code_and_state zs ON s.seller_zip_code_prefix = zs.geolocation_zip_code_prefix
) t
GROUP BY cross_region_flag
-- Findings: 63% of all units of all items are delivered crossed regions. 36% are delivered within the same regions

