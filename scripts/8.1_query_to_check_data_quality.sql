select * from silver.erp_cust_az12; -- CID, BDATE, GEN    -- CID like    NASAW00011000
SELECT * FROM silver.crm_cust_info;						  -- cst_id like         11011
														  -- cst_key like   AW00011011
-- Checking if there are any values matching the cst_key from 'crm_cust_info' AW00011011
SELECT						-- YES, there is value matching but with       NASAW00011011
	*
FROM silver.erp_cust_az12 
WHERE CID LIKE '%AW00011011%';

-- Total Entries
select count(*) from silver.erp_cust_az12; -- 18483

-- Checking if there are any repetitons
SELECT CID, COUNT(*) FROM silver.erp_cust_az12
GROUP BY CID
HAVING COUNT(*) > 1; ---- 0

-- Checking total entries in CID  columns
select COUNT(CID) FROM silver.erp_cust_az12;

-- Checking Null Values in CID column
SELECT *FROM silver.erp_cust_az12 -- 0
WHERE CID IS NULL
;

-- Checking Null Values in BDATE column
SELECT * FROM silver.erp_cust_az12
WHERE BDATE IS NULL
;

-- Checking total entries in BDATE
select COUNT(BDATE) FROM silver.erp_cust_az12;


-- Check the range of BDATE
SELECT DISTINCT BDATE 
FROM silver.erp_cust_az12
WHERE BDATE > '1920-01-01' OR BDATE > GETDATE()
ORDER BY BDATE DESC;

-- Checking total entries in GEN Column --- 17012
select COUNT(GEN) FROM silver.erp_cust_az12;

-- Checking Unique Values in GEN column
SELECT DISTINCT GEN, COUNT(*) FROM silver.erp_cust_az12 GROUP BY GEN;
-- NULL	  1471
-- F 	  5
--   	  4
-- Male	  8608
-- Female 8391
-- M 	  4
