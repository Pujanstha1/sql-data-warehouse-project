SELECT * FROM bronze.erp_loc_a101;   -- CID, CNTRY  -- Values like AW-00011000
SELECT cst_key FROM silver.crm_cust_info;			-- Values like AW00011011

-- TOTAL ENTRIES
SELECT COUNT(*) FROM bronze.erp_loc_a101;  -- 18484 

-- CHECKING IF ANY REPETITION WITH CID
SELECT DISTINCT CID, COUNT(*) FROM bronze.erp_loc_a101 GROUP BY CID HAVING COUNT(*) > 1 ;  -- NOTHING

-- UNIQUE VALUES IN CNTRY COLUMN
SELECT DISTINCT CNTRY, COUNT(*) FROM bronze.erp_loc_a101 GROUP BY CNTRY;
-- DE				566
-- USA				2591
-- Germany			1214
-- United States	3391
-- NULL				332
-- Australia		3591
-- United Kingdom	1913
--   				5
-- Canada			1571
-- France			1810
-- US				1500

