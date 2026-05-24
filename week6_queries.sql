-- ============================================================
-- IDX Exchange — Data Analyst Internship
-- Week 6: Window Functions & Advanced Analytics
-- Tables: rets_property, california_sold
-- Author: Sarah Nguyen
-- ============================================================

-- Concept: Window Functions
-- Window functions calculate values across related rows without collapsing the result like GROUP BY does. Each row keeps its identity while also getting aggregated context.
SELECT
    L_City,
    ROUND(AVG(L_SystemPrice), 0) AS avg_price,
    RANK() OVER (
        ORDER BY AVG(L_SystemPrice) DESC
    ) AS price_rank
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
GROUP BY L_City
LIMIT 20;

-- Exercise 6.1 — PARTITION BY
-- PARTITION BY restarts the calculation for each city while keeping every individual listing row:
SELECT
    L_DisplayId,
    L_Address,
    L_City,
    L_SystemPrice,
    ROUND(AVG(L_SystemPrice) OVER (PARTITION BY L_City), 0) AS city_avg_price,
    ROUND(L_SystemPrice - AVG(L_SystemPrice) OVER (PARTITION BY L_City), 0) AS diff_from_city_avg,
    RANK() OVER (
        PARTITION BY L_City
        ORDER BY L_SystemPrice DESC
    ) AS rank_in_city
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
ORDER BY L_City, rank_in_city
LIMIT 30;

-- Exercise 6.2 — Find Price Outliers
WITH city_stats AS (
    SELECT L_City, AVG(L_SystemPrice) AS city_avg, STDDEV(L_SystemPrice) AS city_stddev
    FROM rets_property
    WHERE L_SystemPrice IS NOT NULL
    GROUP BY L_City
    HAVING COUNT(*) >= 5
)
SELECT
    p.L_DisplayId, p.L_Address, p.L_City, p.L_SystemPrice,
    ROUND(cs.city_avg, 0) AS city_avg_price,
    ROUND(p.L_SystemPrice / cs.city_avg * 100, 1) AS pct_of_city_avg
FROM rets_property p
JOIN city_stats cs ON p.L_City = cs.L_City
WHERE p.L_SystemPrice > cs.city_avg * 1.5
ORDER BY pct_of_city_avg DESC
LIMIT 20;

-- Exercise 6.3 — Sold Price Quartiles
WITH quartiles AS (
SELECT ClosePrice, City,
NTILE(4) OVER (ORDER BY ClosePrice) AS price_quartile
FROM california_sold WHERE ClosePrice IS NOT NULL
)
SELECT price_quartile,
COUNT(*) AS num_sold,
ROUND(MIN(ClosePrice), 0) AS min_price,
ROUND(MAX(ClosePrice), 0) AS max_price,
ROUND(AVG(ClosePrice), 0) AS avg_price
FROM quartiles
GROUP BY price_quartile ORDER BY price_quartile;

-- Exercise 6.4 — Running Totals
WITH monthly AS (
SELECT DATE_FORMAT(ListingContractDate, '%Y-%m') AS list_month,
COUNT(*) AS new_listings
FROM rets_property WHERE ListingContractDate IS NOT NULL
GROUP BY DATE_FORMAT(ListingContractDate, '%Y-%m')
)
SELECT list_month, new_listings,
SUM(new_listings) OVER (
ORDER BY list_month ROWS UNBOUNDED PRECEDING
) AS running_total
FROM monthly ORDER BY list_month;

-- Week 6 Debugging Exercise — Window Function Filter Error
-- This query is supposed to show the single most expensive listing per city but returns multiple rows per city. Fix it.
-- BROKEN: Most expensive listing in each city
SELECT L_DisplayId, L_Address, City, ListPrice,
RANK() OVER (
PARTITION BY City ORDER BY ListPrice DESC
) AS rank_in_city
FROM rets_property
WHERE ListPrice IS NOT NULL
AND rank_in_city = 1 -- Bug: cannot filter on window function here
ORDER BY City;

-- Debugging Exercise Fixed:
-- The original query tried to filter rank_in_city in the WHERE clause.
-- Window functions run after WHERE, so we need a CTE first.

WITH ranked AS (
    SELECT
        L_DisplayId,
        L_Address,
        L_City,
        L_SystemPrice,
        RANK() OVER (
            PARTITION BY L_City
            ORDER BY L_SystemPrice DESC
        ) AS rank_in_city
    FROM rets_property
    WHERE L_SystemPrice IS NOT NULL
        AND L_City IS NOT NULL
)
SELECT
    L_DisplayId,
    L_Address,
    L_City,
    L_SystemPrice,
    rank_in_city
FROM ranked
WHERE rank_in_city = 1
ORDER BY L_City;

-- Q1: Rank cities with 10+ listings by average active listing price

SELECT
    L_City,
    COUNT(*) AS active_listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_active_price,
    RANK() OVER (
        ORDER BY AVG(L_SystemPrice) DESC
    ) AS price_rank
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
    AND L_City IS NOT NULL
GROUP BY L_City
HAVING COUNT(*) >= 10
ORDER BY price_rank;


-- Q2: Show the single most expensive listing in each city

WITH ranked_listings AS (
    SELECT
        L_DisplayId,
        L_Address,
        L_City,
        L_SystemPrice,
        RANK() OVER (
            PARTITION BY L_City
            ORDER BY L_SystemPrice DESC
        ) AS rank_in_city
    FROM rets_property
    WHERE L_SystemPrice IS NOT NULL
        AND L_City IS NOT NULL
)
SELECT
    L_DisplayId,
    L_Address,
    L_City,
    L_SystemPrice,
    rank_in_city
FROM ranked_listings
WHERE rank_in_city = 1
ORDER BY L_City;


-- Q3: Flag listings priced more than 2 standard deviations above city average

WITH city_stats AS (
    SELECT
        L_City,
        AVG(L_SystemPrice) AS city_avg_price,
        STDDEV(L_SystemPrice) AS city_stddev
    FROM rets_property
    WHERE L_SystemPrice IS NOT NULL
        AND L_City IS NOT NULL
    GROUP BY L_City
    HAVING COUNT(*) >= 10
)
SELECT
    p.L_DisplayId,
    p.L_Address,
    p.L_City,
    p.L_SystemPrice,
    ROUND(cs.city_avg_price, 0) AS city_avg_price,
    ROUND(cs.city_stddev, 0) AS city_stddev,
    ROUND(
        (p.L_SystemPrice - cs.city_avg_price) / cs.city_stddev,
        2
    ) AS z_score
FROM rets_property p
JOIN city_stats cs
    ON p.L_City = cs.L_City
WHERE p.L_SystemPrice > cs.city_avg_price + 2 * cs.city_stddev
ORDER BY z_score DESC;


-- Q4: Cities with the most consistent pricing
-- Lower coefficient of variation means prices are more consistent.

SELECT
    L_City,
    COUNT(*) AS active_listings,
    ROUND(AVG(L_SystemPrice), 0) AS avg_price,
    ROUND(STDDEV(L_SystemPrice), 0) AS price_stddev,
    ROUND(STDDEV(L_SystemPrice) / AVG(L_SystemPrice), 3) AS coefficient_of_variation
FROM rets_property
WHERE L_SystemPrice IS NOT NULL
    AND L_City IS NOT NULL
GROUP BY L_City
HAVING COUNT(*) >= 10
ORDER BY coefficient_of_variation ASC
LIMIT 20;


-- Q5: Final city summary table
-- Export this as exports/week6_final_summary.csv

WITH active_city AS (
    SELECT
        L_City,
        COUNT(*) AS active_listings,
        ROUND(AVG(L_SystemPrice), 0) AS avg_active_price
    FROM rets_property
    WHERE L_SystemPrice IS NOT NULL
        AND L_City IS NOT NULL
    GROUP BY L_City
),
sold_city AS (
    SELECT
        City,
        COUNT(*) AS sold_count,
        ROUND(AVG(ClosePrice), 0) AS avg_historical_sold,
        ROUND(AVG(ClosePrice / ListPrice) * 100, 1) AS sale_to_list_ratio
    FROM california_sold
    WHERE ClosePrice IS NOT NULL
        AND ListPrice > 0
        AND City IS NOT NULL
    GROUP BY City
)
SELECT
    a.L_City,
    a.active_listings,
    a.avg_active_price,
    s.sold_count,
    s.avg_historical_sold,
    s.sale_to_list_ratio,
    ROUND(a.avg_active_price / s.avg_historical_sold, 2) AS active_to_sold_ratio
FROM active_city a
JOIN sold_city s
    ON LOWER(TRIM(a.L_City)) = LOWER(TRIM(s.City))
WHERE a.active_listings >= 10
ORDER BY active_to_sold_ratio DESC;

-- ============================================================
-- Week 6 Open-Ended Challenge
-- Question:
-- The CEO wants to know which cities are most competitive right now
-- and which cities represent the best opportunity for buyers.
--
-- Recommendation:
-- I define competitive cities as markets where active listing prices
-- are higher than historical sold prices and sale-to-list ratios are
-- close to or above 100%.
--
-- I define buyer opportunities as cities where active prices are below
-- historical sold prices or where sale-to-list ratios are below 98%,
-- suggesting buyers may have more room to negotiate.
-- ============================================================

WITH active_city AS (
    SELECT
        L_City,
        COUNT(*) AS active_listings,
        ROUND(AVG(L_SystemPrice), 0) AS avg_active_price
    FROM rets_property
    WHERE L_SystemPrice IS NOT NULL
        AND L_City IS NOT NULL
    GROUP BY L_City
),
sold_city AS (
    SELECT
        City,
        COUNT(*) AS sold_count,
        ROUND(AVG(ClosePrice), 0) AS avg_sold_price,
        ROUND(AVG(ClosePrice / ListPrice) * 100, 1) AS sale_to_list_ratio
    FROM california_sold
    WHERE ClosePrice IS NOT NULL
        AND ListPrice > 0
        AND City IS NOT NULL
    GROUP BY City
),
final_summary AS (
    SELECT
        a.L_City AS city,
        a.active_listings,
        a.avg_active_price,
        s.sold_count,
        s.avg_sold_price,
        s.sale_to_list_ratio,
        ROUND(a.avg_active_price / s.avg_sold_price, 2) AS active_to_sold_ratio,
        RANK() OVER (
            ORDER BY s.sale_to_list_ratio DESC
        ) AS competitiveness_rank,
        CASE
            WHEN s.sale_to_list_ratio >= 100
                AND a.avg_active_price >= s.avg_sold_price
                THEN 'Competitive Market'
            WHEN s.sale_to_list_ratio < 98
                OR a.avg_active_price < s.avg_sold_price
                THEN 'Buyer Opportunity'
            ELSE 'Balanced Market'
        END AS market_label
    FROM active_city a
    JOIN sold_city s
        ON LOWER(TRIM(a.L_City)) = LOWER(TRIM(s.City))
    WHERE a.active_listings >= 10
        AND s.sold_count >= 10
)
SELECT
    city,
    active_listings,
    avg_active_price,
    sold_count,
    avg_sold_price,
    sale_to_list_ratio,
    active_to_sold_ratio,
    competitiveness_rank,
    market_label
FROM final_summary
ORDER BY competitiveness_rank, active_to_sold_ratio DESC;
