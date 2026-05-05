-- =====================================================
-- IDX Exchange – Data Analyst Internship
-- Week 1: Data Exploration & Profiling
-- Tables: rets_property, rets_openhouse, california_sold
-- Author: Sarah Nguyen
-- =====================================================

-- =====================================================
-- Week 1 Data Quality Summary
-- =====================================================
-- Summary of Key Findings:
--
-- Data Quality:
-- • No NULL values found in key column L_SystemPrice
-- • Some numeric fields contain unrealistic values (e.g., price = 795, very large max values)
-- • Bedrooms and square footage show extreme ranges (possible outliers)
--
-- Data Types:
-- • california_sold.CloseDate stored as VARCHAR instead of DATE (data type issue)
-- • Some fields may require type conversion before analysis
--
-- Duplicates:
-- • L_DisplayId is unique in rets_property (no duplicates detected)
--
-- Table Relationships:
-- • rets_property (41,199 rows)
-- • rets_openhouse (11,876 rows)
-- • Only 10,423 listings match between tables
-- • 1,453 openhouse records have no matching property
-- • 30,776 properties have no openhouse record
--
-- Consistency Issues:
-- • Same identifier (L_DisplayId) used across tables but not perfectly aligned
-- • City field mismatch:
--     - rets_property uses L_City
--     - california_sold uses City
-- • Some city/address inconsistencies due to unstructured address fields
--
-- Recommendations:
-- • Use LEFT JOIN when combining property and openhouse data
-- • Standardize column names before joins (e.g., City vs L_City)
-- • Filter out extreme numeric outliers before analysis
-- • Convert CloseDate to proper DATE format
-- • Clean/parse address fields if city-level analysis is needed
-- =====================================================

-- Exercise 1.1: List all tables in the database
SHOW TABLES;

-- More detail: table sizes and row counts via INFORMATION_SCHEMA
SELECT TABLE_NAME,
TABLE_ROWS,
ROUND(DATA_LENGTH / 1024 / 1024, 2) AS size_mb
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'rets'
ORDER BY TABLE_ROWS DESC;

-- Exercise 1.2: View structure of property table
DESCRIBE rets_property;
DESCRIBE rets_openhouse;
DESCRIBE california_sold;

-- Data type issue:
-- CloseDate is stored as VARCHAR instead of DATE
-- This prevents proper time-based analysis (sorting, filtering, trends)
-- Recommendation: Convert to DATE using STR_TO_DATE before analysis

--

-- Full detail via INFORMATION_SCHEMA
SELECT COLUMN_NAME,
DATA_TYPE,
IS_NULLABLE,
CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'rets'
AND TABLE_NAME = 'rets_property'
ORDER BY ORDINAL_POSITION;

--

-- Exercise 1.3: Profile Column Quality
-- NULL rate check across key columns
SELECT
COUNT(*) AS total_rows,
SUM(CASE WHEN L_SystemPrice IS NULL THEN 1 ELSE 0 END) AS price_nulls,
SUM(CASE WHEN L_Keyword2 IS NULL THEN 1 ELSE 0 END) AS beds_nulls,
SUM(CASE WHEN LM_Int2_3 IS NULL THEN 1 ELSE 0 END) AS sqft_nulls,
SUM(CASE WHEN L_City IS NULL THEN 1 ELSE 0 END) AS city_nulls
FROM rets_property;

-- Check for bad prices
SELECT *
FROM rets_property
WHERE L_SystemPrice <= 1000
LIMIT 10;

-- How many bad prices rows
SELECT COUNT(*) AS bad_price_count
FROM rets_property
WHERE L_SystemPrice <= 1000;

-- Checked for unrealistic low prices (<= $1000)
-- Result: Found 1 listing with price below realistic threshold
-- Conclusion: This value is likely invalid and will be excluded from analysis
SELECT *
FROM rets_property
WHERE L_SystemPrice > 10000;

-- Check for bad bedrooms
SELECT *
FROM rets_property
WHERE L_Keyword2 <= 0
LIMIT 10;

-- How many bad bedrooms rows?
SELECT COUNT(*) AS bad_bedroom_count
FROM rets_property
WHERE L_Keyword2 <= 0;

-- Checked for invalid bedroom values (<= 0)
-- Result: Multiple listings found with 0 bedrooms
-- Interpretation: Likely missing or incorrectly recorded values
-- Action: These records will be excluded from analysis
SELECT *
FROM rets_property
WHERE L_Keyword2 > 0


-- Check for unrealistic sqft
SELECT *
FROM rets_property
WHERE LM_Int2_3 > 10000
LIMIT 10;

-- Checked for large sqft values (>10,000)
-- Found mostly in luxury areas (likely valid, not errors)
-- Keep but treat as outliers in analysis
--
-- Distribution check: what values does L_Status actually contain?
SELECT L_Status,
COUNT(*) AS total
FROM rets_property
GROUP BY L_Status
ORDER BY total DESC;

-- Checked distribution of L_Status values
-- Result: All 41,199 listings are marked as 'Active'
-- Conclusion: Dataset appears to contain only active listings
-- Limitation: Cannot analyze listing lifecycle (e.g., sold vs pending)
--
-- Sanity check: are numeric columns within realistic ranges?
SELECT
MIN(L_SystemPrice) AS min_price, MAX(L_SystemPrice) AS max_price,
MIN(L_Keyword2) AS min_beds, MAX(L_Keyword2) AS max_beds,
MIN(LM_Int2_3) AS min_sqft, MAX(LM_Int2_3) AS max_sqft
FROM rets_property
WHERE L_SystemPrice IS NOT NULL;

-- Performed sanity check on numeric columns (price, bedrooms, sqft)
-- Findings:
-- - Minimum price is $795 (likely invalid or placeholder)
-- - Bedrooms range from 0 to 71 (0 and extreme values are unrealistic)
-- - Square footage ranges from 0 to 50,000 (0 invalid, high values are outliers)
-- Conclusion: Dataset contains invalid and extreme values that should be filtered before analysis
--
-- Exercise 1.4: Check for duplicate listing IDs
-- Quick summary: total rows vs distinct L_DisplayIds
SELECT COUNT(*) AS total_rows,
COUNT(DISTINCT L_DisplayId) AS distinct_ids,
COUNT(*) - COUNT(DISTINCT L_DisplayId) AS duplicates
FROM rets_property;

-- Detail: which L_DisplayIds appear more than once?
SELECT L_DisplayId, COUNT(*) AS occurrences
FROM rets_property
GROUP BY L_DisplayId
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- Checked for duplicate L_DisplayId values
-- Result: No duplicates found (total rows = distinct IDs)
-- Conclusion: L_DisplayId is a unique identifier and safe to use for analysis
--
-- rets_openhouse duplicates
SELECT L_DisplayId, COUNT(*)
FROM rets_openhouse
GROUP BY L_DisplayId
HAVING COUNT(*) > 1;

-- Result: No duplicate L_DisplayId values found in rets_openhouse.
-- Insight: Each openhouse record appears once by L_DisplayId in this dataset.
--
-- california_sold duplicate check
SELECT 
    ListingKey, 
    COUNT(*) AS occurrences
FROM california_sold
GROUP BY ListingKey
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;
-- Result: No duplicate ListingKey values found in california_sold.
--
-- Exercise 1.5 — Cardinality Check Between Tables
SELECT
COUNT(DISTINCT L_DisplayId) AS distinct_listings,
COUNT(*) AS total_rows,
ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT L_DisplayId), 1) AS avg_rows_per_listing
FROM rets_openhouse;

-- How many rets_property listings have NO match in rets_openhouse?
SELECT COUNT(*) AS listings_without_openhouse
FROM rets_property p
WHERE NOT EXISTS (
SELECT 1 FROM rets_openhouse o WHERE o.L_DisplayId = p.L_DisplayId
);

-- Total Listing in rets_property
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT L_DisplayId) AS distinct_ids
FROM rets_property;

-- There's a discrepancy
-- Most likely reason: rets_openhouse has L_DisplayId values that do not all exist in rets_property
-- - 11,876 = listings that DO have an open house record
-- - 30,776 = listings that do NOT have an open house record
-- - 41,199 = total listings in rets_property
--

-- Check how many openhouse records do not match rets_property
SELECT COUNT(*) AS openhouses_without_property
FROM rets_openhouse o
WHERE NOT EXISTS (
    SELECT 1
    FROM rets_property p
    WHERE p.L_DisplayId = o.L_DisplayId
);

-- Count actual matching listings between both tables
SELECT COUNT(DISTINCT p.L_DisplayId) AS listings_with_openhouse
FROM rets_property p
INNER JOIN rets_openhouse o
    ON p.L_DisplayId = o.L_DisplayId;

-- Result: rets_openhouse has 11,876 records.
-- However, 1,453 openhouse records do not match rets_property.
-- Therefore, only 10,423 property listings have matching openhouse records.
-- 30,776 property listings do not have openhouse records.
-- Insight: Use LEFT JOIN from rets_property when analyzing listings to avoid dropping non-openhouse listings.
--
-- Do city names match between the two tables?
-- Cities in california_sold but NOT in rets_property
SELECT DISTINCT L_City
FROM california_sold
WHERE L_City NOT IN (
SELECT DISTINCT L_City FROM rets_property
WHERE L_City IS NOT NULL
)
ORDER BY L_City
LIMIT 20;

-- Error: checking database to see if there is an L-City
DESCRIBE california_sold;

-- No L-City, most likely embedded in the UnparsedAddress
-- Extract the city from the address
-- Cities in california_sold but not in rets_property
SELECT DISTINCT City
FROM california_sold
WHERE City IS NOT NULL
  AND City NOT IN (
      SELECT DISTINCT L_City
      FROM rets_property
      WHERE L_City IS NOT NULL
  )
ORDER BY City
LIMIT 20;

-- Result: california_sold uses City, while rets_property uses L_City.
-- Insight: Same concept, different column names across tables.
-- Recommendation: Use aliases or standardized names before joining/analyzing.
--
-- BROKEN: Count listings with missing price
SELECT COUNT(*) AS missing_prices
FROM rets_property
WHERE L_SystemPrice = NULL; -- Bug: this will never match anything

-- Bug explanation:
-- Using "= NULL" does not work because NULL is not a value and cannot be compared with "=".
-- This condition always evaluates to FALSE, so it returns 0 rows.

-- Fix: Use IS NULL to correctly identify missing values.

-- Corrected Version
SELECT COUNT(*) AS missing_prices
FROM rets_property
WHERE L_SystemPrice IS NULL;

-- No Null Values, check data
SELECT 
    COUNT(*) AS total_rows,
    COUNT(L_SystemPrice) AS non_null_values,
    COUNT(*) - COUNT(L_SystemPrice) AS null_values
FROM rets_property;

SELECT COUNT(*) AS zero_prices
FROM rets_property
WHERE L_SystemPrice = 0;

-- Result: No NULL values found in L_SystemPrice.
-- However, missing prices are likely represented as 0 instead of NULL.
-- Insight: Data quality issue — NULL checks alone are insufficient.
-- Recommendation: Treat L_SystemPrice = 0 as missing in analysis.
--
SELECT MIN(L_SystemPrice), MAX(L_SystemPrice)
FROM rets_property;

-- Result: L_SystemPrice has 0 NULL values and 0 zero values.
-- MIN(L_SystemPrice) = 795 and MAX(L_SystemPrice) = 170,000,000.
-- Insight: Missing price is not an issue in this column, but the max value is extremely high and should be reviewed as a possible luxury listing or outlier.
--

-- From the data team lead: Explore all three tables. Look for NULLs, outliers, duplicates, and inconsistencies.