-- ============================================================
-- IDX Exchange — Data Analyst Internship
-- Week 4: Multi-Table JOINs
-- Tables: rets_property, rets_openhouse
-- Author: Sarah Nguyen
-- ============================================================

-- INNER JOIN: only listings that HAVE at least one open house
SELECT p.L_DisplayId, p.L_Address, o.OpenHouseDate
FROM rets_property p
INNER JOIN rets_openhouse o ON p.L_DisplayId = o.L_DisplayId
LIMIT 10;

-- LEFT JOIN: ALL listings, NULL for open house fields if none exist
SELECT p.L_DisplayId, p.L_Address, o.OpenHouseDate
FROM rets_property p
LEFT JOIN rets_openhouse o ON p.L_DisplayId = o.L_DisplayId
LIMIT 10;

-- Exercise 4.1 — Listings with Open Houses
SELECT p.L_DisplayId, p.L_Address, p.L_City, p.L_SystemPrice,
o.OpenHouseDate, o.OH_StartTime, o.OH_EndTime
FROM rets_property p
INNER JOIN rets_openhouse o ON p.L_DisplayId = o.L_DisplayId
ORDER BY o.OpenHouseDate
LIMIT 20;

-- Exercise 4.2 — Count Open Houses per Listing
SELECT p.L_DisplayId, p.L_Address, p.L_City, p.L_SystemPrice,
COUNT(o.OpenHouseDate) AS num_open_houses
FROM rets_property p
INNER JOIN rets_openhouse o ON p.L_DisplayId = o.L_DisplayId
GROUP BY p.L_DisplayId, p.L_Address, p.L_City, p.L_SystemPrice
ORDER BY num_open_houses DESC
LIMIT 20;

-- Exercise 4.3 — What Percentage Have Open Houses?
SELECT
COUNT(DISTINCT p.L_DisplayId) AS total_listings,
COUNT(DISTINCT o.L_DisplayId) AS listings_with_openhouse,
ROUND(100.0 * COUNT(DISTINCT o.L_DisplayId)
/ COUNT(DISTINCT p.L_DisplayId), 1) AS pct_with_openhouse
FROM rets_property p
LEFT JOIN rets_openhouse o ON p.L_DisplayId = o.L_DisplayId;

-- Exercise 4.4 — Open House Activity by City
SELECT p.L_City,
COUNT(DISTINCT p.L_DisplayId) AS total_listings,
COUNT(o.OpenHouseDate) AS total_open_houses,
ROUND(100.0 * COUNT(DISTINCT o.L_DisplayId)
/ COUNT(DISTINCT p.L_DisplayId), 1) AS pct_with_openhouse
FROM rets_property p
LEFT JOIN rets_openhouse o ON p.L_DisplayId = o.L_DisplayId
GROUP BY p.L_City
HAVING COUNT(DISTINCT p.L_DisplayId) >= 10
ORDER BY total_open_houses DESC
LIMIT 20;

-- Exercise 4.5 — Most Popular Open House Days
SELECT DAYNAME(OpenHouseDate) AS day_of_week,
COUNT(*) AS num_open_houses
FROM rets_openhouse
WHERE OpenHouseDate IS NOT NULL
GROUP BY DAYNAME(OpenHouseDate), DAYOFWEEK(OpenHouseDate)
ORDER BY DAYOFWEEK(OpenHouseDate);

-- Q1: Top 10 cities by most open houses scheduled
SELECT
    p.L_City,
    COUNT(o.OpenHouseDate) AS total_open_houses,
    COUNT(DISTINCT p.L_DisplayId) AS listings_with_openhouses
FROM rets_property p
INNER JOIN rets_openhouse o
    ON p.L_DisplayId = o.L_DisplayId
WHERE p.L_City IS NOT NULL
GROUP BY p.L_City
ORDER BY total_open_houses DESC
LIMIT 10;


-- Q2: Most popular day of the week for open houses
SELECT
    DAYNAME(o.OpenHouseDate) AS day_of_week,
    COUNT(*) AS total_open_houses
FROM rets_openhouse o
WHERE o.OpenHouseDate IS NOT NULL
GROUP BY
    DAYNAME(o.OpenHouseDate),
    DAYOFWEEK(o.OpenHouseDate)
ORDER BY total_open_houses DESC;


-- Q3: Top 10 listings with the most open houses
SELECT
    p.L_DisplayId,
    p.L_Address,
    p.L_City,
    p.L_SystemPrice,
    COUNT(o.OpenHouseDate) AS num_open_houses
FROM rets_property p
INNER JOIN rets_openhouse o
    ON p.L_DisplayId = o.L_DisplayId
GROUP BY
    p.L_DisplayId,
    p.L_Address,
    p.L_City,
    p.L_SystemPrice
ORDER BY num_open_houses DESC
LIMIT 10;

-- Q4: How many listings have zero open houses?
SELECT
    COUNT(DISTINCT p.L_DisplayId) AS listings_with_zero_open_houses
FROM rets_property p
LEFT JOIN rets_openhouse o
    ON p.L_DisplayId = o.L_DisplayId
WHERE o.L_DisplayId IS NULL;


-- Q5: Do higher-priced listings have more open houses on average?
SELECT
    CASE
        WHEN p.L_SystemPrice < 500000 THEN 'Under $500K'
        WHEN p.L_SystemPrice BETWEEN 500000 AND 999999 THEN '$500K-$999K'
        WHEN p.L_SystemPrice BETWEEN 1000000 AND 1999999 THEN '$1M-$1.99M'
        ELSE '$2M+'
    END AS price_range,
    COUNT(DISTINCT p.L_DisplayId) AS total_listings,
    COUNT(o.OpenHouseDate) AS total_open_houses,
    ROUND(COUNT(o.OpenHouseDate) / COUNT(DISTINCT p.L_DisplayId), 2) AS avg_open_houses_per_listing
FROM rets_property p
LEFT JOIN rets_openhouse o
    ON p.L_DisplayId = o.L_DisplayId
WHERE p.L_SystemPrice IS NOT NULL
GROUP BY price_range
ORDER BY avg_open_houses_per_listing DESC;


-- Debugging Exercise Fixed:
-- The original query inflated average prices because listings with multiple open houses appeared multiple times after the JOIN.
-- This version calculates city-level averages before joining to open house counts.

-- BROKEN: Average list price by city for listings with open houses
-- Results are higher than expected — why?
-- Answer: -- Results are higher than expected because the INNER JOIN creates duplicate rows when one listing has multiple open houses.
-- 		   -- A listing with 3 open houses appears 3 times, so its price is counted multiple times.
-- 		   -- This inflates listing_count and can skew avg_price.

SELECT
    p.L_City,
    COUNT(*) AS listing_count,
    ROUND(AVG(p.L_SystemPrice), 0) AS avg_price
FROM rets_property p
INNER JOIN rets_openhouse o
    ON p.L_DisplayId = o.L_DisplayId
GROUP BY p.L_City
ORDER BY avg_price DESC
LIMIT 15;

-- FIXED: Calculate average price before joining to open house counts

WITH city_prices AS (
    SELECT
        L_City,
        COUNT(DISTINCT L_DisplayId) AS listing_count,
        ROUND(AVG(L_SystemPrice), 0) AS avg_price
    FROM rets_property
    WHERE L_SystemPrice IS NOT NULL
        AND L_City IS NOT NULL
    GROUP BY L_City
)

SELECT
    L_City,
    listing_count,
    avg_price
FROM city_prices
ORDER BY avg_price DESC
LIMIT 15;

-- ============================================================
-- Week 4 Open-Ended Challenge
-- Question:
-- The sales team wants to host weekend open house events only in cities
-- where open house activity is already high.
--
-- Recommendation:
-- Based on the analysis, I would target cities with the highest number
-- of open houses and focus the events on weekends, especially Saturday
-- and Sunday.
-- ============================================================