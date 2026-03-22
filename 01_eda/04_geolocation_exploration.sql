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

--No candidate keys found -> table contain many rows duplicates
-- 261831 exact duplicates out of 1000163 rows
-- Some rows also have different accent of the city name, while every other column is identical
-- This suggests that this dataset might possibly be imported from multiple sources (or an uncleaned source) and the author did not perform deduplications
-- Also inconsistencies happened with 8 zip code prefixes (same prefix, but different states -> which is impossible in real world)
-- Grain (originally intended): one district per zip code prefix
-- Grain (actually is): one geographical sample point in a district per row - non unique

SELECT COUNT(*) AS total_nulls
FROM geolocation
WHERE geolocation_lat IS NULL
OR geolocation_lng IS NULL
-- Findings: no missing lat or long on any sample point

SELECT COUNT(*) AS out_of_bounds_total FROM geolocation 
WHERE geolocation_lat NOT BETWEEN -33.74 AND 5.27
OR geolocation_lng NOT BETWEEN -73.98 AND -34.73
-- Findings: total of 42 sample points are potentially outside of Brazil's coordinate bounds

