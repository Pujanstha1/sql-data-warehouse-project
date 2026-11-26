-- Checking the Table
SELECT * FROM silver.erp_px_cat_g1v2;  --ID, CAT, SUBCAT, MAINTAINANCE  -- ID like AC-BR
--Matching Table
SELECT * FROM silver.crm_prd_info;									    -- prd_key like BC-M005
																		-- cat_id AC_BC
-- Total Entries
SELECT COUNT(*) FROM silver.erp_px_cat_g1v2;  --37

-- Total Distict Values
SELECT DISTINCT ID, COUNT(*) FROM silver.erp_px_cat_g1v2 GROUP BY ID; -- 37 DISTINCT VALUES

-- Check if the ID matches
SELECT DISTINCT ID FROM silver.erp_px_cat_g1v2 WHERE ID IN (SELECT cat_id FROM silver.crm_prd_info	); 

-- Check Unwanted Spaces   --- NO EMPTY SPACES
SELECT * silver.erp_px_cat_g1v2
WHERE CAT != TRIM(CAT) OR SUBCAT != TRIM(SUBCAT) OR MAINTENANCE != TRIM(MAINTENANCE); 

-- Count of Unique Items from CAT column
SELECT CAT, COUNT(*) FROM silver.erp_px_cat_g1v2 GROUP BY CAT;
-- Accessories	12
-- Bikes	3
-- Clothing	8
-- Components	14

-- Distinct Values from SUBCAT Column
SELECT SUBCAT, COUNT(*) FROM silver.erp_px_cat_g1v2 GROUP BY SUBCAT;  -- 37 DISTINCT VALUES

-- Count of Unique Items from MAINTENANCE column
SELECT MAINTENANCE, COUNT(*) FROM silver.erp_px_cat_g1v2 GROUP BY MAINTENANCE;
-- No	17
-- Yes	20


