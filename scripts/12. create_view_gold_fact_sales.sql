CREATE VIEW gold.facts_sales AS

SELECT top 5
	sd.sls_ord_num AS order_number,
	--sd.sls_prd_key,  -- replacing this with the below product_key (surrogate key) from the dimension table.
	pr.product_key,	   
	--sd.sls_cust_id,  -- replacing this with the below customer_key (surrogate key) from the dimension table.
	cu.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS sales_quantity,
	sd.sls_price AS sales_price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id
