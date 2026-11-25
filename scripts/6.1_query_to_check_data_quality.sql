-- Quality Checks
-- Check For Nuls or Duplicates in Primary Key
-- Expectation: No Result
SELECT
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info 
GROUP BY prd_id
HAVING count(*) > 1 OR prd_id IS NULL;
---
-- Check for Unwanted Spaces
-- Expectations: No Results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);
----

-- Check for Nulls or Negative Numbers
-- Expectation: No results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;
---

-- Data Standarization & Consistency
SELECT DISTINCT prd_line 
FROM silver.crm_prd_info;
---

-- Check for Invalid Date Orders
SELECT *
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;
---

-- Final Look at the silver.crm_prd_info table
SELECT 
	*
FROM silver.crm_prd_info;

