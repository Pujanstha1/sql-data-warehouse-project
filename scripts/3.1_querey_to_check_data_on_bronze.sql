-- Check for Null or Duplicates in Primary Key
-- Expectations: No Results
SELECT
	cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

--Check for Unwanted Spaces
-- Expectations: No Results
SELECT cst_key FROM bronze.crm_cust_info
WHERE cst_key != TRIM(cst_key)

-- Data Standarization & Consistency
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;