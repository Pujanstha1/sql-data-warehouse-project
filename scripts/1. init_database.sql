
/*
====================================================
CREATE DATABASE AND SCHEMAS
====================================================

SCRIPT PURPOSE:

This script creates a new database called 'DataWarehouse'
and sets up three schemas inside it:

    1. bronze - Stores raw data directly from source systems.
    2. silver - Stores cleaned, transformed, and standardised data.
    3. gold   - Stores business-ready data for reporting and analytics.

WHAT IS A DATABASE?
A database is an organised collection of data that can be
stored, managed, retrieved, and manipulated using SQL.

WHAT IS A SCHEMA?
A schema is a logical container inside a database that
organises database objects such as tables, views, and procedures.

WARNING:
If the 'DataWarehouse' database already exists, this script
will permanently delete it and recreate it.

All existing tables, records, views, stored procedures,
and other objects inside the database will be lost.

Make sure you have a backup before executing this script.
====================================================
*/


-- ==================================================
-- STEP 1: SWITCH TO THE MASTER DATABASE
-- ==================================================

-- USE master;
-- 'master' is a system database in SQL Server.
-- It contains server-level information, including details
-- about all databases available on the SQL Server instance.
--
-- We use 'master' because we need to check whether
-- DataWarehouse exists before creating or dropping it.
--
-- You cannot drop a database while you are actively
-- connected to that same database.

USE master;

-- GO;
-- GO is a batch separator recognised by SQL Server tools
-- such as SQL Server Management Studio (SSMS).
--
-- It tells SSMS to execute all statements written before GO
-- as one batch.
--
-- GO is NOT a SQL statement. It is a command understood
-- by SQL Server client tools.

GO


-- ==================================================
-- STEP 2: CHECK IF THE DATABASE ALREADY EXISTS
-- ==================================================

-- IF EXISTS:
-- Checks whether the condition inside the parentheses
-- returns at least one record.
--
-- SELECT 1:
-- Returns the constant value 1 for each matching record.
-- We only need to check whether a record exists, so
-- retrieving actual database information is unnecessary.
--
-- FROM sys.databases:
-- sys.databases is a SQL Server system catalog view.
-- It contains information about databases on the server.
--
-- WHERE name = 'DataWarehouse':
-- Filters the results to find a database named DataWarehouse.
--
-- If the database exists, the IF condition evaluates to TRUE
-- and the BEGIN...END block is executed.

IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = 'DataWarehouse'
)

BEGIN

    -- ==================================================
    -- STEP 3: CHANGE THE DATABASE ACCESS MODE
    -- ==================================================

    -- ALTER DATABASE DataWarehouse:
    -- Modifies the configuration of the existing database.

    -- SET SINGLE_USER:
    -- Restricts database access to only ONE user at a time.
    --
    -- This helps prevent other users or applications from
    -- connecting to the database while we are dropping it.

    -- WITH ROLLBACK IMMEDIATE:
    -- Immediately terminates existing connections to the
    -- database and rolls back any unfinished transactions.
    --
    -- IMPORTANT:
    -- Any uncommitted work from those connections will be lost.

    ALTER DATABASE DataWarehouse
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;


    -- ==================================================
    -- STEP 4: DROP THE EXISTING DATABASE
    -- ==================================================

    -- DROP DATABASE:
    -- Permanently deletes the DataWarehouse database.
    --
    -- This removes all database objects and stored data,
    -- including tables, records, views, and procedures.
    --
    -- We do this so that the script can start with a
    -- completely clean database environment.

    DROP DATABASE DataWarehouse;

END

-- GO;
-- Executes the database deletion batch before proceeding
-- to the next batch.

GO


-- ==================================================
-- STEP 5: CREATE A NEW DATABASE
-- ==================================================

-- CREATE DATABASE:
-- Creates a completely new database on the SQL Server instance.
--
-- The new database will be named 'DataWarehouse'.
--
-- At this point, the database is empty.
-- We will create schemas and tables inside it later.

CREATE DATABASE DataWarehouse;

GO


-- ==================================================
-- STEP 6: SWITCH TO THE NEW DATABASE
-- ==================================================

-- USE DataWarehouse:
-- Changes the current database context to DataWarehouse.
--
-- This means that subsequent database objects, such as
-- schemas and tables, will be created inside this database
-- rather than inside the master database.

USE DataWarehouse;

GO


-- ==================================================
-- STEP 7: CREATE THE BRONZE SCHEMA
-- ==================================================

-- CREATE SCHEMA:
-- Creates a logical container inside the current database.
--
-- BRONZE LAYER:
-- The bronze layer stores raw data extracted from source systems.
--
-- Examples:
--   - ERP customer CSV files
--   - CRM customer CSV files
--   - Sales transaction CSV files
--
-- The data is generally loaded with minimal transformation
-- to preserve the original source information.

CREATE SCHEMA bronze;

GO


-- ==================================================
-- STEP 8: CREATE THE SILVER SCHEMA
-- ==================================================

-- SILVER LAYER:
-- Stores cleaned, validated, and transformed data.
--
-- Typical operations performed in this layer include:
--   - Removing duplicate records.
--   - Handling NULL and missing values.
--   - Standardising dates and text formats.
--   - Correcting inconsistent data.
--   - Resolving data quality issues.
--   - Integrating data from multiple source systems.
--
-- The silver layer provides reliable and consistent data
-- for downstream analytical processing.

CREATE SCHEMA silver;

GO


-- ==================================================
-- STEP 9: CREATE THE GOLD SCHEMA
-- ==================================================

-- GOLD LAYER:
-- Stores business-ready data designed for reporting,
-- dashboards, and analytical queries.
--
-- Typical objects in this layer include:
--   - Fact tables (e.g. FactSales).
--   - Dimension tables (e.g. DimCustomers).
--   - Aggregated business metrics.
--   - Analytical views.
--
-- This layer is designed to make data easier for
-- business users, analysts, and reporting tools to consume.
--
-- Example:
-- A Power BI dashboard can use gold-layer tables
-- to report total revenue, customer performance,
-- and product sales trends.

CREATE SCHEMA gold;

GO


/*
====================================================
END OF SCRIPT
====================================================

DATABASE CREATED: DataWarehouse

SCHEMAS CREATED:
    1. bronze
    2. silver
    3. gold

NEXT STEPS:
    1. Import raw ERP and CRM CSV files into bronze.
    2. Clean and transform the data into silver.
    3. Build analytical fact and dimension tables in gold.
    4. Write SQL queries to generate business insights.

====================================================
*/
