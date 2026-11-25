select * from bronze.crm_sales_details;
select prd_key from silver.crm_prd_info;

select sls_prd_key from bronze.crm_sales_details
where sls_prd_key not in (select prd_key from silver.crm_prd_info)

SELECT 
	sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0;

-- Check for invalid dates
SELECT
	count(sls_order_dt)
FROM bronze.crm_sales_details
WHERE sls_order_dt <=0 or sls_order_dt IS NULL;

-- Replace 0 with Null
SELECT
	NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0  
	  OR LEN(sls_order_dt) != 8 
	  OR sls_order_dt > 20500101 
	  OR sls_order_dt <19000101;

-- Check for Invalid Dates Order
select *
FROM bronze.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt;

-- Checl Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.

-- Rules
-- If Sales is negative, zero, or null, derive it using Quantity and Price.
-- If Price is zero or null, calculate it using Sales and Quantity.
-- If Price is negative, convert it to a positive value.

SELECT DISTINCT
	sls_sales AS old_sls_sales,	
	sls_quantity,	
	sls_price AS old_sls_price,
	CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
		 THEN sls_quantity * ABS(sls_price) 
		 ELSE sls_sales
	END AS sls_sales,

	CASE WHEN sls_price IS NULL OR sls_price <= 0 
		 THEN sls_sales / NULLIF(sls_quantity, 0)
		 ELSE sls_price
	END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL
OR sls_quantity IS NULL
OR sls_price IS NULL
OR sls_sales <= 0
OR sls_quantity <= 0
OR sls_price <= 0
ORDER BY sls_sales,	
		 sls_quantity,	
		 sls_price
;




