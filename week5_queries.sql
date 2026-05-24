-- ============================================================
-- IDX Exchange — Data Analyst Internship
-- Week 5: Subqueries and CTEs
-- Tables: rets_property, california_sold
-- Author: Sarah Nguyen
-- ============================================================

-- Concept: Subqueries
-- Find listings priced above the overall average
SELECT L_Address, L_City, L_SystemPrice
FROM rets_property
WHERE L_SystemPrice > (
SELECT AVG(L_SystemPrice) FROM rets_property
)
ORDER BY L_SystemPrice DESC LIMIT 20;

-- Exercise 5.1 — Explore california_sold
SELECT City,
COUNT(*) AS total_sold,
ROUND(AVG(ClosePrice), 0) AS avg_sold_price,
ROUND(AVG(ListPrice), 0) AS avg_list_price,
ROUND(AVG(ClosePrice / ListPrice) * 100, 1) AS avg_sale_to_list_pct
FROM california_sold
WHERE ClosePrice IS NOT NULL AND ListPrice > 0
GROUP BY City
HAVING COUNT(*) >= 10
ORDER BY avg_sale_to_list_pct DESC
LIMIT 20;

-- Concept: CTEs
-- CTEs use WITH to name a subquery, making complex queries easier to read. Most professional analysts prefer CTEs over deeply nested subqueries.
WITH historical_avg AS (
SELECT City,
ROUND(AVG(ClosePrice), 0) AS avg_sold_price,
COUNT(*) AS num_sold
FROM california_sold
WHERE ClosePrice IS NOT NULL
GROUP BY City HAVING COUNT(*) >= 10
)
SELECT p.L_City,
COUNT(DISTINCT p.L_DisplayId) AS active_listings,
ROUND(AVG(p.L_SystemPrice), 0) AS avg_active_price,
h.avg_sold_price,
ROUND((AVG(p.L_SystemPrice) - h.avg_sold_price)
/ h.avg_sold_price * 100, 1) AS pct_diff_from_historical
FROM rets_property p
JOIN historical_avg h ON p.L_City = h.City
GROUP BY p.L_City, h.avg_sold_price
ORDER BY pct_diff_from_historical DESC;

-- Exercise 5.2 — Seasonal Trends
SELECT YEAR(CloseDate) AS sale_year,
MONTH(CloseDate) AS sale_month,
COUNT(*) AS homes_sold,
ROUND(AVG(ClosePrice), 0) AS avg_sold_price
FROM california_sold
WHERE CloseDate IS NOT NULL
GROUP BY YEAR(CloseDate), MONTH(CloseDate)
ORDER BY sale_year, sale_month;

-- Q1: Top 10 cities by sale-to-list ratio
-- Sold above asking most often

SELECT
    City,
    COUNT(*) AS total_sold,
    ROUND(AVG(ListPrice), 0) AS avg_list_price,
    ROUND(AVG(ClosePrice), 0) AS avg_close_price,
    ROUND(AVG(ClosePrice / ListPrice) * 100, 1) AS avg_sale_to_list_pct
FROM california_sold
WHERE ClosePrice IS NOT NULL
    AND ListPrice > 0
    AND City IS NOT NULL
GROUP BY City
HAVING COUNT(*) >= 10
ORDER BY avg_sale_to_list_pct DESC
LIMIT 10;


-- Q2: Cities where active listings are priced significantly above historical norms

WITH historical_avg AS (
    SELECT
        City,
        ROUND(AVG(ClosePrice), 0) AS avg_sold_price,
        COUNT(*) AS num_sold
    FROM california_sold
    WHERE ClosePrice IS NOT NULL
        AND City IS NOT NULL
    GROUP BY City
    HAVING COUNT(*) >= 10
)

SELECT
    p.L_City,
    COUNT(DISTINCT p.L_DisplayId) AS active_listings,
    ROUND(AVG(p.L_SystemPrice), 0) AS avg_active_price,
    h.avg_sold_price,
    ROUND(
        (AVG(p.L_SystemPrice) - h.avg_sold_price)
        / h.avg_sold_price * 100,
        1
    ) AS pct_above_historical
FROM rets_property p
JOIN historical_avg h
    ON LOWER(TRIM(p.L_City)) = LOWER(TRIM(h.City))
WHERE p.L_SystemPrice IS NOT NULL
    AND p.L_City IS NOT NULL
GROUP BY
    p.L_City,
    h.avg_sold_price
HAVING COUNT(DISTINCT p.L_DisplayId) >= 10
ORDER BY pct_above_historical DESC
LIMIT 20;


-- Q3: Which month has the highest average historical sale price?

SELECT
    YEAR(CloseDate) AS sale_year,
    MONTH(CloseDate) AS sale_month,
    COUNT(*) AS homes_sold,
    ROUND(AVG(ClosePrice), 0) AS avg_sold_price
FROM california_sold
WHERE CloseDate IS NOT NULL
    AND ClosePrice IS NOT NULL
GROUP BY
    YEAR(CloseDate),
    MONTH(CloseDate)
HAVING COUNT(*) >= 10
ORDER BY avg_sold_price DESC
LIMIT 1;


-- Q4: How does the average discount from list price vary by bedroom count?

SELECT
    BedroomsTotal AS bedrooms,
    COUNT(*) AS total_sold,
    ROUND(AVG(ListPrice), 0) AS avg_list_price,
    ROUND(AVG(ClosePrice), 0) AS avg_close_price,
    ROUND(AVG(ListPrice - ClosePrice), 0) AS avg_discount_amount,
    ROUND(AVG((ListPrice - ClosePrice) / ListPrice) * 100, 1) AS avg_discount_pct
FROM california_sold
WHERE ListPrice > 0
    AND ClosePrice IS NOT NULL
    AND BedroomsTotal IS NOT NULL
    AND BedroomsTotal BETWEEN 1 AND 8
GROUP BY BedroomsTotal
ORDER BY BedroomsTotal;


-- Q5: Cities where homes typically sell within 2% of asking price

SELECT
    City,
    COUNT(*) AS total_sold,
    ROUND(AVG(ListPrice), 0) AS avg_list_price,
    ROUND(AVG(ClosePrice), 0) AS avg_close_price,
    ROUND(AVG(ClosePrice / ListPrice) * 100, 1) AS avg_sale_to_list_pct,
    ROUND(ABS(AVG(ClosePrice / ListPrice) * 100 - 100), 1) AS pct_from_asking
FROM california_sold
WHERE ClosePrice IS NOT NULL
    AND ListPrice > 0
    AND City IS NOT NULL
GROUP BY City
HAVING COUNT(*) >= 10
    AND ABS(AVG(ClosePrice / ListPrice) * 100 - 100) <= 2
ORDER BY pct_from_asking ASC, total_sold DESC;

-- Week 5 Debugging Exercise — CTE Returns All NULLs
-- This CTE runs without error but pct_diff_from_historical is NULL for every row. Find why the JOIN is failing.
-- BROKEN: Compare active prices to historical sold prices
WITH historical AS (
SELECT City, ROUND(AVG(ClosePrice), 0) AS avg_sold
FROM california_sold
WHERE ClosePrice IS NOT NULL
GROUP BY City
)
SELECT p.L_City,
ROUND(AVG(p.L_SystemPrice), 0) AS avg_active_price,
h.avg_sold,
ROUND((AVG(p.L_SystemPrice) - h.avg_sold)
/ h.avg_sold * 100, 1) AS pct_diff_from_historical
FROM rets_property p
LEFT JOIN historical h ON p.L_City = h.City
GROUP BY p.L_City, h.avg_sold
ORDER BY avg_active_price DESC;

-- Compare L_City to california_sold with LOWER(TRIM()) normalization
-- L_City normalized with LOWER(TRIM())
SELECT DISTINCT LOWER(TRIM(L_City)) AS normalized_city
FROM rets_property
WHERE L_City IS NOT NULL
ORDER BY normalized_city;

-- california_sold normalized with LOWER(TRIM())
SELECT DISTINCT LOWER(TRIM(City)) AS normalized_city
FROM california_sold
WHERE City IS NOT NULL
ORDER BY normalized_city;

-- Fix: wrap both sides of the ON condition with LOWER(TRIM()) to normalize spacing and case
WITH historical AS (
SELECT City, ROUND(AVG(ClosePrice), 0) AS avg_sold
FROM california_sold
WHERE ClosePrice IS NOT NULL
GROUP BY City
)
SELECT p.L_City,
ROUND(AVG(p.L_SystemPrice), 0) AS avg_active_price,
h.avg_sold,
ROUND((AVG(p.L_SystemPrice) - h.avg_sold)
/ h.avg_sold * 100, 1) AS pct_diff_from_historical
FROM rets_property p
LEFT JOIN historical h
    ON LOWER(TRIM(p.L_City)) = LOWER(TRIM(h.City))
GROUP BY p.L_City, h.avg_sold
ORDER BY avg_active_price DESC;

-- Found city name mismatches between rets_property and california_sold
-- Some cities had differences in capitalization or spacing
-- Fixed by using LOWER(TRIM()) in the JOIN condition

-- ============================================================
-- Week 5 Open-Ended Challenge
-- Question:
-- A seller asked whether right now is a good time to list
-- their home in Sacramento.
--
-- Executive Summary:
-- Based on the analysis, Sacramento appears to be a relatively
-- favorable market for sellers if active listing prices are above
-- historical sold prices and homes are selling near or above
-- asking price. Seasonal sales trends and sale-to-list ratios
-- can also help determine whether market demand is currently strong.

-- Sacramento appears to be a reasonable market to list in because this query compares current active inventory,
-- active listing prices, historical sold prices, seasonal sales trends, and sale-to-list ratio.
-- If Sacramento's sale-to-list ratio is near or above 100% and active prices are above historical sold prices,
-- that suggests sellers may have favorable pricing conditions.
-- ============================================================


WITH sacramento_sold AS (
    SELECT
        City,
        COUNT(*) AS total_sold,
        ROUND(AVG(ListPrice), 0) AS avg_historical_list_price,
        ROUND(AVG(ClosePrice), 0) AS avg_historical_sold_price,
        ROUND(AVG(ClosePrice / ListPrice) * 100, 1) AS avg_sale_to_list_pct
    FROM california_sold
    WHERE LOWER(TRIM(City)) = 'sacramento'
        AND ClosePrice IS NOT NULL
        AND ListPrice > 0
    GROUP BY City
),

sacramento_active AS (
    SELECT
        L_City,
        COUNT(DISTINCT L_DisplayId) AS active_listings,
        ROUND(AVG(L_SystemPrice), 0) AS avg_active_price
    FROM rets_property
    WHERE LOWER(TRIM(L_City)) = 'sacramento'
        AND L_SystemPrice IS NOT NULL
    GROUP BY L_City
),

sacramento_seasonal AS (
    SELECT
        MONTH(CloseDate) AS sale_month,
        COUNT(*) AS homes_sold,
        ROUND(AVG(ClosePrice), 0) AS avg_monthly_sold_price
    FROM california_sold
    WHERE LOWER(TRIM(City)) = 'sacramento'
        AND CloseDate IS NOT NULL
        AND ClosePrice IS NOT NULL
    GROUP BY MONTH(CloseDate)
)

SELECT
    a.L_City,
    a.active_listings,
    a.avg_active_price,
    s.total_sold,
    s.avg_historical_list_price,
    s.avg_historical_sold_price,
    s.avg_sale_to_list_pct,
    ROUND(
        (a.avg_active_price - s.avg_historical_sold_price)
        / s.avg_historical_sold_price * 100,
        1
    ) AS pct_active_above_historical
FROM sacramento_active a
JOIN sacramento_sold s
    ON LOWER(TRIM(a.L_City)) = LOWER(TRIM(s.City));


-- Sacramento seasonal trend by month

SELECT
    MONTH(CloseDate) AS sale_month,
    COUNT(*) AS homes_sold,
    ROUND(AVG(ClosePrice), 0) AS avg_monthly_sold_price
FROM california_sold
WHERE LOWER(TRIM(City)) = 'sacramento'
    AND CloseDate IS NOT NULL
    AND ClosePrice IS NOT NULL
GROUP BY MONTH(CloseDate)
ORDER BY sale_month;
