CREATE VIEW gold.dim_products AS

SELECT 
	ROW_NUMBER() OVER (ORDER BY pin.prd_start_dt, pin.prd_key) AS product_key,
	pin.prd_id AS product_id,
	pin.prd_key AS product_number,
	pin.prd_nm AS product_name,
	pin.cat_id AS category_id,
	px.cat AS category,
	px.subcat AS subcategory,
	px.maintenance,
	pin.prd_cost AS product_cost,
	pin.prd_line AS product_line,
	pin.prd_start_dt
	--pin.prd_end_dt,			-- no need for this as all end_dt are NULL
FROM silver.crm_prd_info pin
LEFT JOIN silver.erp_px_cat_g1v2 px
ON		  pin.cat_id = px.ID
where prd_end_dt IS NULL  -- Filters out all historical data and only provides current.
