-- ============================================================ 
-- IDX Exchange — Data Analyst Internship
-- Week 3: Aggregations & Grouping
-- Tables: rets_property
-- Author: Sarah Nguyen
-- ============================================================


-- Concept: Aggregate Functions

SELECT
    COUNT(*) AS total_listings,
    AVG(L_SystemPrice) AS avg_price,
    MIN(L_SystemPrice) AS cheapest,
    MAX(L_SystemPrice) AS most_expensive
FROM rets_property;


-- Exercise 3.1 — GROUP BY L_City

SELECT
    L_City,
    COUNT(*) AS total_listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_list_price,
    MIN(L_SystemPrice) AS min_price,
    MAX(L_SystemPrice) AS max_price
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
GROUP BY L_City
ORDER BY avg_list_price DESC;



-- Exercise 3.2 — Price Per Square Foot

SELECT
    L_City,
    COUNT(*) AS listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_price,
    ROUND(AVG(LM_Int2_3), 0) AS avg_sqft,
    ROUND(AVG(L_SystemPrice / LM_Int2_3), 2) AS avg_price_per_sqft
FROM rets_property
WHERE LM_Int2_3 > 0
    AND L_SystemPrice IS NOT NULL
GROUP BY L_City
ORDER BY avg_price_per_sqft DESC
LIMIT 20;



-- Exercise 3.3 — HAVING

SELECT
    L_City,
    COUNT(*) AS total_listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_price
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
GROUP BY L_City
HAVING COUNT(*) >= 10
ORDER BY avg_price DESC;



-- Exercise 3.4 — Inventory by Bedroom Count

SELECT
    L_Keyword2 AS bedrooms,
    COUNT(*) AS total_listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_price
FROM rets_property
WHERE L_Keyword2 IS NOT NULL
    AND L_Keyword2 BETWEEN 1 AND 8
GROUP BY L_Keyword2
ORDER BY L_Keyword2;

-- Week 3 Debugging Exercise
-- BROKEN: Cities with average price above $600k (min 5 listings)
SELECT L_City,
COUNT(*) AS total_listings,
ROUND(AVG(L_SystemPrice), 0) AS avg_price
FROM rets_property
WHERE AVG(L_SystemPrice) > 600000 -- Bug: wrong clause for aggregate filter
AND L_SystemPrice IS NOT NULL
GROUP BY L_City
HAVING COUNT(*) >= 5
ORDER BY avg_price DESC;

-- Fixed: moved AVG filter from WHERE to HAVING
-- WHERE filters individual rows before grouping
-- HAVING filters grouped results like AVG and COUNT

SELECT
    L_City,
    COUNT(*) AS total_listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_price
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
GROUP BY L_City
HAVING COUNT(*) >= 5
    AND AVG(L_SystemPrice) > 600000
ORDER BY avg_price DESC;

-- Q1: Top 10 cities by highest average list price

SELECT
    L_City,
    COUNT(*) AS total_listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_price
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
GROUP BY L_City
HAVING COUNT(*) >= 10
ORDER BY avg_price DESC
LIMIT 10;


-- Q2: Top 10 cities by most active inventory

SELECT
    L_City,
    COUNT(*) AS total_listings
FROM rets_property
GROUP BY L_City
ORDER BY total_listings DESC
LIMIT 10;

-- Q3: Average price per sqft by city — top 15 cities
SELECT
    L_City,
    COUNT(*) AS listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_price,
    ROUND(AVG(LM_Int2_3), 0) AS avg_sqft,
    ROUND(AVG(L_SystemPrice / LM_Int2_3), 2) AS avg_price_per_sqft
FROM rets_property
WHERE LM_Int2_3 > 0
    AND L_SystemPrice IS NOT NULL
GROUP BY L_City
ORDER BY avg_price_per_sqft DESC
LIMIT 15;

-- Q4: Listing count at each bedroom count 1 through 6
SELECT
    L_Keyword2 AS bedrooms,
    COUNT(*) AS total_listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_price
FROM rets_property
WHERE L_Keyword2 BETWEEN 1 AND 6
GROUP BY L_Keyword2
ORDER BY L_Keyword2;

-- Q5: ZIP codes with average price above $800,000
SELECT
    L_Zip,
    COUNT(*) AS total_listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_price
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
GROUP BY L_Zip
HAVING AVG(L_SystemPrice) > 800000
ORDER BY avg_price DESC;
