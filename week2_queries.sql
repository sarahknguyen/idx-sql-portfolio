-- ============================================================
-- IDX Exchange — Data Analyst Internship
-- Week 2: SELECT, WHERE & ORDER BY
-- Tables: rets_property
-- Author: Sarah Barah
-- ============================================================


-- Exercise 2.1 — Select Specific Columns

SELECT
    L_DisplayId,
    L_Address,
    L_City,
    L_SystemPrice,
    L_Keyword2,
    LM_Dec_3
FROM rets_property
LIMIT 20;

-- Exercise 2.2 — Filtering with WHERE
-- Properties in a specific city

SELECT
    L_DisplayId,
    L_Address,
    L_SystemPrice,
    L_Keyword2
FROM rets_property
WHERE L_City = 'Los Angeles'
LIMIT 20;

-- 3+ bedroom homes under $700k
SELECT
    L_Address,
    L_City,
    L_SystemPrice,
    L_Keyword2
FROM rets_property
WHERE L_Keyword2 >= 3
    AND L_SystemPrice < 700000
ORDER BY L_SystemPrice ASC;


-- Exercise 2.3 — BETWEEN and LIKE
-- Properties between $400k and $600k

SELECT
    L_Address,
    L_City,
    L_SystemPrice
FROM rets_property
WHERE L_SystemPrice BETWEEN 400000 AND 600000
ORDER BY L_SystemPrice;

-- Cities starting with 'San'
SELECT DISTINCT
    L_City
FROM rets_property
WHERE L_City LIKE 'San%';



-- Exercise 2.4 — NULL Handling
-- Listings missing square footage

SELECT
    L_DisplayId,
    L_Address,
    L_City
FROM rets_property
WHERE LM_Int2_3 IS NULL;

-- Listings with square footage, largest first
SELECT
    L_DisplayId,
    L_Address,
    L_City,
    LM_Int2_3
FROM rets_property
WHERE LM_Int2_3 IS NOT NULL
ORDER BY LM_Int2_3 DESC
LIMIT 10;


-- Q1: How many total listings are in rets_property?
SELECT COUNT(*) AS total_listings
FROM rets_property;


-- Q2: Top 10 most expensive listings
SELECT
    L_Address,
    L_City,
    L_SystemPrice
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
ORDER BY L_SystemPrice DESC
LIMIT 10;

-- Q3: All listings with 4+ bedrooms
SELECT
    L_DisplayId,
    L_Address,
    L_City,
    L_SystemPrice,
    L_Keyword2
FROM rets_property
WHERE L_Keyword2 >= 4
ORDER BY L_Keyword2 DESC;

-- Q4: All listings in a ZIP code of your choosing
SELECT
    L_DisplayId,
    L_Address,
    L_City,
    L_Zip,
    L_SystemPrice
FROM rets_property
WHERE L_Zip = '90001'
ORDER BY L_SystemPrice DESC;



-- Q5: Properties over 3,000 sqft under $1M
SELECT
    L_DisplayId,
    L_Address,
    L_City,
    LM_Int2_3,
    L_SystemPrice
FROM rets_property
WHERE LM_Int2_3 > 3000
    AND L_SystemPrice < 1000000
    AND LM_Int2_3 IS NOT NULL
    AND L_SystemPrice IS NOT NULL
ORDER BY LM_Int2_3 DESC;



-- Q6: Every distinct city — no duplicates
SELECT DISTINCT L_City
FROM rets_property
WHERE L_City IS NOT NULL
ORDER BY L_City;



-- Debugging Exercise
-- Fixed Bug 1: Los Angeles must be wrapped in single quotes because it is a string
-- Fixed Bug 2: LIMIT should be an integer, not a quoted string


-- BROKEN: 10 cheapest listings in Los Angeles with a valid price
SELECT L_Address, L_City, L_SystemPrice
FROM rets_property
WHERE L_City = 'Los Angeles' -- Bug 1: 
AND L_SystemPrice IS NOT NULL
ORDER BY L_SystemPrice ASC
LIMIT 10; -- Bug 2: expects a number not a text, take quotes out

-- ============================================================
-- Week 2 Open-Ended Challenge
-- Affordable housing can be interpreted in multiple ways.
-- I explored affordability through:
-- 1. Cities with the most homes under $500k
-- 2. Homes with the best value per bedroom
-- I believe the first approach is most useful for a buyer’s guide
-- because it shows where buyers have the most affordable inventory.
-- ============================================================


-- Query 1: Cities with the most listings under $500k

SELECT
    L_City,
    COUNT(*) AS affordable_listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_affordable_price
FROM rets_property
WHERE L_SystemPrice < 500000
    AND L_SystemPrice IS NOT NULL
GROUP BY L_City
ORDER BY affordable_listings DESC
LIMIT 15;



-- Query 2: Best value per bedroom

SELECT
    L_Address,
    L_City,
    L_SystemPrice,
    L_Keyword2 AS bedrooms,
    ROUND(L_SystemPrice / L_Keyword2, 0) AS price_per_bedroom
FROM rets_property
WHERE L_Keyword2 > 0
    AND L_SystemPrice IS NOT NULL
ORDER BY price_per_bedroom ASC
LIMIT 20;