/*
===============================================================================
Create Bronze Stored Procedure
===============================================================================
Purpose:
    Loads raw data from the source CSV files (CRM and ERP) into the Bronze
    layer tables of the DataWarehouse database.

How it works, per table:
    1. TRUNCATE the table (empty it so reruns don't duplicate data)
    2. BULK INSERT the CSV file into the table
    3. Measure and print how long that step took

Where to find it after creating:
    Databases > DataWarehouse > Programmability > Stored Procedures > bronze.load_bronze

How to use:
    - First time (or after ANY edit to this file): run this whole script once.
      That creates / updates the stored procedure.
    - Every other time, just run:   EXEC bronze.load_bronze;
===============================================================================
*/

-- CREATE OR ALTER = create the procedure if it doesn't exist, otherwise overwrite it with this new version.
-- bronze.load_bronze = procedure name, stored in the "bronze" schema.
-- AS = marks the start of the procedure definition.
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
-- BEGIN / END wrap the entire body of the procedure.
BEGIN

	-- Declare 4 variables to hold timestamps:
	--   @start_time / @end_time           -> timing of ONE table load
	--   @batch_start_time / @batch_end_time -> timing of the WHOLE bronze load
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

	-- TRY/CATCH = error handling. SQL runs the code inside TRY; if anything fails,
	-- it jumps straight to the CATCH block at the bottom instead of crashing.
	BEGIN TRY

		-- Record the time the whole batch started (GETDATE() = current date and time).
		SET @batch_start_time = GETDATE();

		-- PRINT = show a message in the "Messages" tab. These lines make a header banner.
		PRINT '========================================================'
		PRINT 'Loading Bronze Layer'
		PRINT '========================================================'

		-- Sub-header for the CRM source system tables.
		PRINT '--------------------------------------------------------'
		PRINT 'Loading CRM Table'
		PRINT '--------------------------------------------------------'

		----------------------------------------------------------------------
		-- TABLE 1: bronze.crm_cust_info  (CRM customer information)
		----------------------------------------------------------------------

		-- Start the stopwatch for this table.
		SET @start_time = GETDATE();

		-- Log which step is running.
		PRINT '>> Truncating Table: bronze.crm_cust_info'

		-- TRUNCATE = delete ALL rows quickly but keep the table structure.
		-- Ensures the table is empty before the insert, preventing the same data being loaded twice.
		TRUNCATE TABLE bronze.crm_cust_info;

		-- Log the next step.
		PRINT '>> Inserting Data Into: bronze.crm_cust_info'

		-- BULK INSERT = fast way to load a whole file into a table.
		-- Target table:
		BULK INSERT bronze.crm_cust_info
		-- Source file path (on the machine where SQL Server runs):
		FROM 'C:\Users\pujan\Desktop\Data Engineering\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		-- WITH ( ... ) = options for how to read the file:
		WITH (
			FIRSTROW = 2,           -- skip row 1 because it is the header (column names), start at row 2
			FIELDTERMINATOR = ',',  -- columns in the CSV are separated by commas
			TABLOCK                 -- lock the whole table during the load, which makes it faster
		);

		-- Stop the stopwatch.
		SET @end_time = GETDATE();

		-- DATEDIFF(second, start, end) = number of seconds between the two times.
		-- CAST(... AS NVARCHAR) converts the number to text so it can be joined with the message using +.
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds.';

		-- Divider line between tables.
		PRINT '----------------------'

		-- Quality checks (commented out; uncomment and run on their own after loading):
		-- Check the data loaded as intended:
		-- SELECT * FROM bronze.crm_cust_info;

		-- Check the total rows match the source file:
		-- SELECT COUNT(*) FROM bronze.crm_cust_info;

		----------------------------------------------------------------------
		-- TABLE 2: bronze.crm_prd_info  (CRM product information)
		----------------------------------------------------------------------

		-- Start the stopwatch.
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: bronze.crm_prd_info'
		-- Empty the table before loading.
		TRUNCATE TABLE bronze.crm_prd_info;

		-- (Fixed: the original message said crm_cust_info here by mistake.)
		PRINT '>> Inserting Data Into: bronze.crm_prd_info'
		-- Load the product CSV into the table.
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\pujan\Desktop\Data Engineering\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,           -- skip the header row
			FIELDTERMINATOR = ',',  -- comma separated
			TABLOCK                 -- lock table for speed
		);

		-- Stop the stopwatch and print the duration.
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds.'
		PRINT '----------------------'

		-- Quality checks (optional):
		-- SELECT * FROM bronze.crm_prd_info;
		-- SELECT COUNT(*) FROM bronze.crm_prd_info;

		----------------------------------------------------------------------
		-- TABLE 3: bronze.crm_sales_details  (CRM sales transactions)
		----------------------------------------------------------------------

		-- Start the stopwatch.
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: bronze.crm_sales_details'
		-- Empty the table before loading.
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> Inserting Data Into: bronze.crm_sales_details'
		-- Load the sales CSV into the table.
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\pujan\Desktop\Data Engineering\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,           -- skip the header row
			FIELDTERMINATOR = ',',  -- comma separated
			TABLOCK                 -- lock table for speed
		);

		-- Stop the stopwatch and print the duration.
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds.';
		PRINT '----------------------'

		-- Quality checks (optional):
		-- SELECT * FROM bronze.crm_sales_details;
		-- SELECT COUNT(*) FROM bronze.crm_sales_details;

		----------------------------------------------------------------------
		-- ERP source system tables start here
		----------------------------------------------------------------------

		-- Sub-header for the ERP source system tables.
		PRINT '--------------------------------------------------------'
		PRINT 'Loading ERP Table'
		PRINT '--------------------------------------------------------'

		----------------------------------------------------------------------
		-- TABLE 4: bronze.erp_cust_az12  (ERP customer extra details)
		----------------------------------------------------------------------

		-- Start the stopwatch.
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: bronze.erp_cust_az12'
		-- Empty the table before loading.
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>> Inserting Data Into: bronze.erp_cust_az12'
		-- Load the ERP customer CSV into the table.
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\pujan\Desktop\Data Engineering\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,           -- skip the header row
			FIELDTERMINATOR = ',',  -- comma separated
			TABLOCK                 -- lock table for speed
		);

		-- Stop the stopwatch and print the duration.
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds.';
		PRINT '----------------------'

		-- Quality checks (optional):
		-- SELECT * FROM bronze.erp_cust_az12;
		-- SELECT COUNT(*) FROM bronze.erp_cust_az12;

		----------------------------------------------------------------------
		-- TABLE 5: bronze.erp_loc_a101  (ERP customer locations / country)
		----------------------------------------------------------------------

		-- Start the stopwatch.
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: bronze.erp_loc_a101'
		-- Empty the table before loading.
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>> Inserting Data Into: bronze.erp_loc_a101'
		-- Load the ERP location CSV into the table.
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\pujan\Desktop\Data Engineering\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,           -- skip the header row
			FIELDTERMINATOR = ',',  -- comma separated
			TABLOCK                 -- lock table for speed
		);

		-- Stop the stopwatch and print the duration.
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds.';
		PRINT '----------------------'

		-- Quality checks (optional):
		-- SELECT * FROM bronze.erp_loc_a101;
		-- SELECT COUNT(*) FROM bronze.erp_loc_a101;

		----------------------------------------------------------------------
		-- TABLE 6: bronze.erp_px_cat_g1v2  (ERP product categories)
		----------------------------------------------------------------------

		-- Start the stopwatch.
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2'
		-- Empty the table before loading.
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2'
		-- Load the ERP product category CSV into the table.
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\pujan\Desktop\Data Engineering\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,           -- skip the header row
			FIELDTERMINATOR = ',',  -- comma separated
			TABLOCK                 -- lock table for speed
		);

		-- Stop the stopwatch and print the duration.
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds.';
		PRINT '----------------------'

		-- Quality checks (optional):
		-- SELECT * FROM bronze.erp_px_cat_g1v2;
		-- SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2;

		----------------------------------------------------------------------
		-- Wrap up: total time for the whole bronze load
		----------------------------------------------------------------------

		-- Record the time the whole batch finished.
		SET @batch_end_time = GETDATE();

		-- Print the closing banner.
		PRINT '======================================================================'
		PRINT 'Loading Bronze Layer is Completed.';
		-- Total seconds from the very start of the procedure to now.
		PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds.';
		PRINT '======================================================================'

	-- End of the TRY block. If everything above worked, the CATCH block is skipped.
	END TRY

	-- CATCH block runs ONLY if an error happened inside TRY (e.g. file not found, wrong path, permission issue).
	BEGIN CATCH
		PRINT '======================================================================'
		PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER'
		-- ERROR_MESSAGE() = the text describing what went wrong.
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		-- ERROR_NUMBER() = SQL Server's numeric error code (useful for Googling the error).
		-- (Fixed: the original printed ERROR_MESSAGE() twice; this one now shows the error number.)
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		-- ERROR_STATE() = a number that helps pinpoint where in the code the error came from.
		PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '======================================================================'
	END CATCH

-- End of the stored procedure.
END
