
/*
=========================================================
CREATE BRONZE LAYER TABLES
=========================================================

SCRIPT PURPOSE:
    This script creates six tables inside the bronze schema
    of the DataWarehouse database.

    These tables will store raw data extracted from two
    different source systems:

    CRM (Customer Relationship Management):
        1. crm_cust_info
        2. crm_prd_info
        3. crm_sales_details

    ERP (Enterprise Resource Planning):
        4. erp_cust_az12
        5. erp_loc_a101
        6. erp_px_cat_g1v2

IMPORTANT:
    - Bronze tables store raw source data.
    - Minimal transformations should be performed here.
    - These tables will be populated later using CSV files.
    - DROP TABLE deletes the existing table and its data.
    - Running this script again will recreate empty tables.

=========================================================
*/


-- =======================================================
-- TABLE 1: CRM CUSTOMER INFORMATION
-- =======================================================

-- OBJECT_ID():
-- A SQL Server system function that returns the internal
-- object ID of a database object, such as a table or view.
--
-- Syntax:
-- OBJECT_ID('schema_name.object_name', 'object_type')
--
-- 'bronze.crm_cust_info':
-- Specifies the fully qualified table name.
-- bronze = schema name
-- crm_cust_info = table name
--
-- 'U':
-- Represents a user-defined table in SQL Server.
--
-- IS NOT NULL:
-- Checks whether the table already exists.
-- If it exists, OBJECT_ID returns an ID.
-- If it does not exist, OBJECT_ID returns NULL.

IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
    -- DROP TABLE:
    -- Deletes the existing table from the database.
    --
    -- IMPORTANT:
    -- This also permanently deletes all records stored
    -- inside that table.
    --
    -- We drop the table before recreating it to ensure
    -- that the structure matches the latest definition.




-- CREATE TABLE:
-- Creates a new table called crm_cust_info
-- inside the bronze schema.
--
-- Each column defines a particular attribute of a customer.
--
-- INT:
-- Stores whole numbers.
--
-- NVARCHAR(50):
-- Stores Unicode text with a maximum length of 50 characters.
-- Unicode supports different languages and special characters.
--
-- DATE:
-- Stores a date without a time component.

CREATE TABLE bronze.crm_cust_info (
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE
);
    -- Customer ID:
    -- Unique identifier assigned to each customer.
    -- INT is used because customer IDs are numeric.

    -- Customer Key:
    -- Business identifier used to identify a customer.
    -- NVARCHAR(50) allows letters, numbers and special characters.

    -- Customer First Name:
    -- Stores the customer's first name.

    -- Customer Last Name:
    -- Stores the customer's surname.

    -- Customer Marital Status:
    -- Stores marital status information.
    -- Examples: Married, Single, Divorced.

    -- Customer Gender:
    -- Stores the customer's gender information.
    -- Examples: Male, Female, Unknown.

    -- Customer Creation Date:
    -- Stores the date when the customer record was created.
    -- DATE stores only the date, not hours or minutes.



-- =======================================================
-- TABLE 2: CRM PRODUCT INFORMATION
-- =======================================================

-- Check whether the CRM product table already exists.
-- If it exists, delete it before creating a new version.

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL

    DROP TABLE bronze.crm_prd_info;


-- Create the CRM product information table.
--
-- This table stores information about products available
-- in the CRM source system.

CREATE TABLE bronze.crm_prd_info (

    -- Product ID:
    -- Numeric identifier assigned to a product.

    prd_id INT,

    -- Product Key:
    -- Business identifier used to identify a product.
    -- May contain letters, numbers or special characters.

    prd_key NVARCHAR(50),

    -- Product Name:
    -- Stores the name or description of the product.

    prd_nm NVARCHAR(50),

    -- Product Cost:
    -- Stores the product cost as a whole number.
    -- INT does not support decimal places.
    -- The source data may determine whether this is appropriate.

    prd_cost INT,

    -- Product Line:
    -- Stores the category or product line.
    -- Examples: Road, Mountain, Touring.

    prd_line NVARCHAR(50),

    -- Product Start Date:
    -- Specifies when the product became active or available.
    --
    -- DATETIME stores both date and time information.
    -- Example: 2026-01-15 10:30:00.

    prd_start_dt DATETIME,

    -- Product End Date:
    -- Specifies when the product's validity or availability ends.
    -- May be NULL if the product is currently active.
    --
    -- This can help identify product validity periods.

    prd_end_dt DATETIME
);


-- =======================================================
-- TABLE 3: CRM SALES DETAILS
-- =======================================================

-- Check whether the CRM sales details table already exists.
-- If it exists, drop it before creating a new table.

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL

    DROP TABLE bronze.crm_sales_details;


-- Create the CRM sales details table.
--
-- This table contains transactional sales information.
-- Each record represents a sales transaction or sales line.
--
-- Sales data is particularly important because it allows
-- us to calculate revenue, quantity sold, and order trends.

CREATE TABLE bronze.crm_sales_details (

    -- Sales Order Number:
    -- Identifies the sales order associated with the transaction.
    -- NVARCHAR is used because order numbers may contain letters
    -- or special characters.

    sls_ord_num NVARCHAR(50),

    -- Sales Product Key:
    -- Identifies which product was sold.
    -- Can later be used to connect sales with product information.

    sls_prd_key NVARCHAR(50),

    -- Sales Customer ID:
    -- Identifies the customer who placed the order.
    -- Can later be used to connect sales with customer information.

    sls_cust_id INT,

    -- Sales Order Date:
    -- Stores the order date.
    --
    -- IMPORTANT:
    -- This column is defined as INT instead of DATE.
    -- The source system may provide dates in YYYYMMDD format.
    --
    -- Example:
    -- 20261124 represents 24 November 2026.
    --
    -- Conversion and validation will be performed later
    -- in the Silver layer.

    sls_order_dt INT,

    -- Sales Shipping Date:
    -- Stores the date when the order was shipped.
    -- Currently stored as INT, possibly in YYYYMMDD format.

    sls_ship_dt INT,

    -- Sales Due Date:
    -- Stores the expected delivery or due date.
    -- Currently stored as INT, possibly in YYYYMMDD format.

    sls_due_dt INT,

    -- Sales Amount:
    -- Stores the sales revenue or sales amount.
    -- INT stores whole numbers only.
    -- Verify the source data to determine whether decimal
    -- values or a different currency representation are used.

    sls_sales INT,

    -- Sales Quantity:
    -- Stores the number of units sold in the transaction.

    sls_quantity INT,

    -- Sales Price:
    -- Stores the selling price of the product.
    -- INT is used here, so decimal values cannot be stored.

    sls_price INT
);


-- =======================================================
-- TABLE 4: ERP CUSTOMER INFORMATION
-- =======================================================

-- Check whether the ERP customer table already exists.
-- If it exists, delete the existing table.

IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL

    DROP TABLE bronze.erp_cust_az12;


-- Create the ERP customer information table.
--
-- This table contains additional customer information
-- received from the ERP source system.
--
-- It can later be integrated with CRM customer data.

CREATE TABLE bronze.erp_cust_az12 (

    -- Customer ID:
    -- Identifies a customer in the ERP system.
    --
    -- NVARCHAR(50) is used because ERP customer identifiers
    -- may contain letters and numbers.
    --
    -- This identifier may need to be standardised before
    -- joining it with the CRM customer table.

    CID NVARCHAR(50),

    -- Birth Date:
    -- Stores the customer's date of birth.
    -- DATE stores the date without a time component.

    BDATE DATE,

    -- Gender:
    -- Stores gender information received from ERP.
    -- NVARCHAR allows text values.

    GEN NVARCHAR(50)
);


-- =======================================================
-- TABLE 5: ERP CUSTOMER LOCATION
-- =======================================================

-- Check whether the ERP location table already exists.
-- If it exists, drop it before recreating it.

IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL

    DROP TABLE bronze.erp_loc_a101;


-- Create the ERP customer location table.
--
-- This table contains geographical information associated
-- with customers in the ERP system.

CREATE TABLE bronze.erp_loc_a101 (

    -- Customer ID:
    -- Identifies the customer associated with the location.
    -- Can be used to link customer location data with
    -- other customer information.

    CID NVARCHAR(50),

    -- Country:
    -- Stores the country associated with the customer.
    -- Examples: Australia, Nepal, United States.

    CNTRY NVARCHAR(50)
);


-- =======================================================
-- TABLE 6: ERP PRODUCT CATEGORY INFORMATION
-- =======================================================

-- Check whether the ERP product category table exists.
-- If it exists, drop the existing table.

IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL

    DROP TABLE bronze.erp_px_cat_g1v2;


-- Create the ERP product category table.
--
-- This table contains product classification information.
-- It provides additional details about product categories,
-- subcategories, and maintenance requirements.

CREATE TABLE bronze.erp_px_cat_g1v2 (

    -- Product Category ID:
    -- Identifies a product category or classification.
    -- Can later be used to integrate category information
    -- with product records.

    ID NVARCHAR(50),

    -- Category:
    -- Stores the main product category.
    -- Example: Bikes, Components, Clothing.

    CAT NVARCHAR(50),

    -- Subcategory:
    -- Stores a more specific classification within a category.
    -- Example: Mountain Bikes, Road Bikes, Helmets.

    SUBCAT NVARCHAR(50),

    -- Maintenance:
    -- Stores information about whether maintenance is required
    -- or the relevant maintenance classification.

    MAINTENANCE NVARCHAR(50)
);


-- =======================================================
-- END OF SCRIPT
-- =======================================================

-- At this stage, we have created six empty tables
-- inside the bronze schema.
--
-- These tables are ready to receive raw data from
-- the CRM and ERP CSV files.
--
-- NEXT STEPS:
--
-- 1. Load CRM CSV files into the three CRM tables.
-- 2. Load ERP CSV files into the three ERP tables.
-- 3. Validate the imported data.
-- 4. Check record counts and data quality.
-- 5. Transform and clean data in the Silver layer.
--
-- IMPORTANT:
-- Creating a table only defines its structure.
-- It does NOT automatically import data into the table.
--
-- Data loading will be performed using SQL Server
-- import tools, BULK INSERT, or another ETL process.

-- =======================================================
