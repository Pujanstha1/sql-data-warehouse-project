# Project Walkthrough: SQL Server Data Warehouse (Medallion Architecture)

This document explains how the data warehouse was designed and built, from requirements through to the final star schema. It records the decisions I made, the data quality problems I found, how I fixed them, and how to reproduce the project end to end.

> **Looking for the quick version?** See the [README](../README.md). All scripts referenced here live in [`scripts/`](../scripts) and [`tests/`](../tests).

---

## Contents

1. [Project summary](#1-project-summary)
2. [Requirements](#2-requirements)
3. [Architecture and design decisions](#3-architecture-and-design-decisions)
4. [Naming conventions](#4-naming-conventions)
5. [Environment and repository setup](#5-environment-and-repository-setup)
6. [Database initialisation](#6-database-initialisation)
7. [Bronze layer](#7-bronze-layer)
8. [Silver layer](#8-silver-layer)
9. [Gold layer](#9-gold-layer)
10. [Testing and validation](#10-testing-and-validation)
11. [Documentation deliverables](#11-documentation-deliverables)
12. [How to run the project](#12-how-to-run-the-project)
13. [Troubleshooting](#13-troubleshooting)
14. [Key lessons and future improvements](#14-key-lessons-and-future-improvements)
15. [Glossary](#15-glossary)

---

## 1. Project summary

| | |
|---|---|
| **Goal** | Consolidate sales data from a CRM and an ERP into one clean, analytics-ready data warehouse |
| **Platform** | SQL Server (T-SQL), SSMS |
| **Inputs** | 6 CSV files (3 CRM, 3 ERP) |
| **Architecture** | Medallion: Bronze → Silver → Gold |
| **Output** | Star schema: `dim_customers`, `dim_products`, `fact_sales` |
| **Load strategy** | Batch, full load (truncate and insert) |
| **Documentation** | Architecture, data flow, integration model, data model, data catalog, naming conventions |

**Source data**

| Source | File | Contents |
|---|---|---|
| CRM | `cust_info` | Customer master data |
| CRM | `prd_info` | Products, including price history |
| CRM | `sales_details` | Sales transactions |
| ERP | `CUST_AZ12` | Customer birthdate and gender |
| ERP | `LOC_A101` | Customer country |
| ERP | `PX_CAT_G1V2` | Product categories and subcategories |

---

## 2. Requirements

**Objective:** build a modern data warehouse in SQL Server that consolidates sales data and supports analytical reporting and informed decision-making.

| # | Requirement | Design implication |
|---|---|---|
| 1 | Import data from two source systems (ERP and CRM) as CSV files | File-based ingestion with `BULK INSERT` |
| 2 | Cleanse and resolve data quality issues before analysis | Dedicated cleansing layer (Silver) |
| 3 | Combine both sources into one user-friendly model for analytics | Integrated star schema (Gold) |
| 4 | Focus on the latest data; no historisation | Overwrite-style loads; filter historical product rows |
| 5 | Document the data model for business and analytics teams | Data catalog, diagrams, lineage |

A second phase covers **analytics and reporting** (customer behaviour, product performance, sales trends) built on top of the Gold layer.

---

## 3. Architecture and design decisions

### 3.1 Choosing the approach

| Approach | Considered for | Decision |
|---|---|---|
| Data warehouse | Structured data, BI foundation | ✅ **Chosen** (all sources are structured) |
| Data lake | Mixed/unstructured data | Not needed |
| Data lakehouse | Flexible + structured | Not needed |
| Data mesh | Decentralised ownership | Not needed |

Within data warehousing I compared **Inmon**, **Kimball**, **Data Vault** and **Medallion**. I chose **Medallion** because the layer responsibilities are simple to explain, easy to implement, and keep raw data available for traceability.

![Data Architecture](data_architecture.png)

### 3.2 Layer specifications

I defined the purpose, object type, load method, transformations, data model and audience of every layer *before* writing code, then held myself to those rules.

| | **Bronze** | **Silver** | **Gold** |
|---|---|---|---|
| Definition | Raw, unprocessed data as-is from the sources | Clean and standardised data | Business-ready data |
| Objective | Traceability and debugging | Prepare data for analysis | Serve reporting and analytics |
| Object type | Tables | Tables | **Views** |
| Load | Batch · full · truncate and insert | Batch · full · truncate and insert | None (virtual) |
| Transformations | **None** | Cleansing, standardisation, normalisation, derived columns, enrichment | Integration, aggregation, business logic |
| Data model | As-is from source | As-is from source | **Star schema** |
| Audience | Data engineers | Engineers, analysts, data scientists | Analysts and business users |

### 3.3 ETL technique choices

| Decision | Choice |
|---|---|
| Extraction method | Pull |
| Extraction scope | Full |
| Extraction technique | File parsing (CSV) |
| Processing | Batch |
| Load method | Truncate and insert |
| History handling | SCD Type 1 (overwrite, no history) |

### 3.4 Design principle: separation of concerns

Each component has **one job**, and jobs never overlap:

- Cleansing happens only in Silver. Business logic happens only in Gold.
- Every source system loads into Bronze first. Nothing skips a layer.
- Gold reads from Silver, never from Bronze.

This keeps the pipeline predictable, easy to debug, and easy to extend with new sources.

---

## 4. Naming conventions

Agreed before development so every object follows the same standard.

**General:** `snake_case` · English · no SQL reserved words.

| Object | Pattern | Example |
|---|---|---|
| Bronze table | `<source>_<entity>` | `crm_cust_info` |
| Silver table | `<source>_<entity>` (1:1 with Bronze) | `crm_cust_info` |
| Gold table/view | `<category>_<entity>` | `dim_customers`, `fact_sales` |
| Surrogate key | `<entity>_key` | `customer_key` |
| Technical/metadata column | `dwh_<name>` | `dwh_create_date` |
| Stored procedure | `load_<layer>` | `bronze.load_bronze` |

**Gold category prefixes:** `dim_` (dimension) · `fact_` (fact) · `report_` (aggregated reporting view).

---

## 5. Environment and repository setup

**Tools:** SQL Server Express, SSMS, Git/GitHub, draw.io, Notion.

**Project plan.** I tracked the work in Notion using two linked tables: *Epics* (Requirements, Architecture, Initialisation, Bronze, Silver, Gold) and *Tasks* (each with a checkbox and a relation to its epic). A rollup on percentage of completed tasks gave each epic a progress bar. Every layer followed the same task pattern: **Analyse → Code → Validate → Document → Commit**.

**Repository structure**

```
sql-data-warehouse-project/
├── setup/
├── datasets/
│   ├── source_crm/
│   └── source_erp/
├── docs/
├── scripts/
│   ├── init_database.sql
│   ├── bronze/
│   ├── silver/
│   └── gold/
├── tests/
├── LICENSE
└── README.md
```

I committed after every completed step, and every script starts with a header comment (purpose, parameters, warnings, usage).

---

## 6. Database initialisation

Script: [`scripts/init_database.sql`](../scripts/init_database.sql)

It checks whether the `DataWarehouse` database already exists, drops it if so, recreates it, and creates the three schemas (`bronze`, `silver`, `gold`).

```sql
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

CREATE DATABASE DataWarehouse;
GO
USE DataWarehouse;
GO

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
```

> ⚠️ **Warning:** running this script permanently deletes the `DataWarehouse` database. The header comment in the script states this explicitly.

A schema acts like a folder that keeps each layer's objects organised. `GO` is a batch separator that makes SQL Server finish one command before starting the next.

---

## 7. Bronze layer

**Process:** analyse sources → ingest → validate completeness and schema → document → commit.

### 7.1 Source analysis

Before ingesting any source, I work through a standard checklist:

| Area | Questions |
|---|---|
| Business context | Who owns the data? Which business process does it support? |
| Documentation | Is there a data model or data catalog? |
| Technical | Where is it stored? How can it be accessed (API, files, direct connection)? |
| Extraction | Full or incremental? How much history? Expected volume? Performance limits on the source? |
| Access | Authentication and authorisation requirements |

Here the answers were: CSV files in folders, full load, pull model.

### 7.2 Table definitions

Script: [`scripts/bronze/ddl_bronze.sql`](../scripts/bronze/ddl_bronze.sql)

Six tables, one per file. Column names and types mirror the source. Names follow the convention:

| Bronze table | Source file |
|---|---|
| `bronze.crm_cust_info` | CRM `cust_info` |
| `bronze.crm_prd_info` | CRM `prd_info` |
| `bronze.crm_sales_details` | CRM `sales_details` |
| `bronze.erp_cust_az12` | ERP `CUST_AZ12` |
| `bronze.erp_loc_a101` | ERP `LOC_A101` |
| `bronze.erp_px_cat_g1v2` | ERP `PX_CAT_G1V2` |

Each table is preceded by a drop-if-exists check so the script can be re-run after structure changes (SQL Server has no `CREATE OR REPLACE TABLE`):

```sql
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO
```

### 7.3 Loading with BULK INSERT

`BULK INSERT` loads an entire file in one operation, which is much faster than row-by-row inserts.

```sql
TRUNCATE TABLE bronze.crm_cust_info;

BULK INSERT bronze.crm_cust_info
FROM 'C:\sql\dwh_project\datasets\source_crm\cust_info.csv'
WITH (
    FIRSTROW = 2,            -- skip the header row
    FIELDTERMINATOR = ',',   -- comma-delimited
    TABLOCK                  -- table lock for faster loading
);
```

| Option | Reason |
|---|---|
| `TRUNCATE TABLE` first | Makes the load a **full load** and prevents duplicates when re-run |
| `FIRSTROW = 2` | Row 1 is the header |
| `FIELDTERMINATOR` | Must match the file's delimiter |
| `TABLOCK` | Performance optimisation |

### 7.4 Validation after loading

For every table I checked:

1. **Data present** in every column.
2. **Data in the correct column** (no shifted values, which typically indicates a wrong delimiter or wrong DDL).
3. **Row count** equals the file's line count minus the header (e.g. 18,490 rows in `crm_cust_info`).
4. **Idempotency:** running the load twice leaves the row count unchanged.

### 7.5 Stored procedure

Script: [`scripts/bronze/proc_load_bronze.sql`](../scripts/bronze/proc_load_bronze.sql)

`bronze.load_bronze` wraps the six truncate-and-load steps and adds:

- Section banners (CRM / ERP) and a message for each action
- Load duration per table and for the whole batch (`DATEDIFF`)
- `TRY…CATCH` with error message, number and state

```sql
EXEC bronze.load_bronze;
```

Sample output pattern:

```
================================================
Loading Bronze Layer
================================================
------------------------------------------------
Loading CRM Tables
------------------------------------------------
>> Truncating Table: bronze.crm_cust_info
>> Inserting Data Into: bronze.crm_cust_info
>> Load Duration: 0 seconds
```

Durations are near zero locally, but in production they show where bottlenecks are.

### 7.6 Data flow diagram (v1)

![Data Flow](data_flow.png)

Source folders (CRM, ERP) → six Bronze tables, establishing the start of the lineage.

---

## 8. Silver layer

**Process (a loop):** explore → profile quality issues in Bronze → write the transformation → insert → re-check quality in Silver → document → commit.

### 8.1 Understanding the data

Bronze only focused on ingestion, so before cleansing I profiled each table and mapped how they relate.

| Table | Description | Join key |
|---|---|---|
| `crm_cust_info` | Customers | `cst_id`, `cst_key` (customer number) |
| `crm_prd_info` | Products **with history** (start/end dates, changing cost) | `prd_key` (business key) |
| `crm_sales_details` | Transactions | `sls_prd_key` → product; `sls_cust_id` → customer |
| `erp_cust_az12` | Customer birthdate and gender | `cid` ↔ `cst_key` |
| `erp_loc_a101` | Customer country | `cid` ↔ `cst_key` |
| `erp_px_cat_g1v2` | Product categories | `id` ↔ first 5 characters of `prd_key` |

![Data Integration Model](data_integration.png)

### 8.2 Silver table definitions

Script: [`scripts/silver/ddl_silver.sql`](../scripts/silver/ddl_silver.sql)

Silver mirrors Bronze with these deliberate changes:

- **Metadata column** on every table: `dwh_create_date DATETIME2 DEFAULT GETDATE()` records when each row was loaded, supporting auditing and debugging.
- `crm_prd_info`: new derived `cat_id` column; start/end dates changed from `DATETIME` to `DATE`.
- `crm_sales_details`: order, ship and due dates changed from `INT` to `DATE`.

### 8.3 Cleansing rules applied project-wide

- Replace codes and abbreviations with readable values (`F` → `Female`).
- Replace missing text values with `n/a`; missing numeric cost with `0`.
- Always `TRIM` strings; wrap in `UPPER()` when mapping codes so future lowercase values are still matched.
- Store dates as real `DATE` types.
- Investigate one bad record first, build the fix in an isolated `SELECT`, then promote it to the `INSERT`.

### 8.4 Issues found and how I resolved them

| Table | Issue found in Bronze | Resolution |
|---|---|---|
| `crm_cust_info` | Duplicate and NULL customer IDs | `ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC)`, keep rank 1 (latest); drop NULL IDs |
| | Leading/trailing spaces in names | `TRIM()` |
| | Coded gender and marital status, with NULLs | Map to `Male/Female` and `Single/Married`; default `n/a` |
| `crm_prd_info` | Composite `prd_key` mixes category and product | Derive `cat_id` (first 5 characters, `-` → `_`) and `prd_key` (from position 7) |
| | NULL costs | `ISNULL(prd_cost, 0)` |
| | Coded product line | Map to Mountain / Road / Other Sales / Touring; default `n/a` |
| | End dates earlier than start dates and overlapping price periods | Ignore source end date; rebuild as *next start date − 1 day* using `LEAD()`; cast to `DATE` |
| `crm_sales_details` | Dates stored as integers (`YYYYMMDD`), with zeros and malformed values | Convert valid 8-digit values via `VARCHAR` → `DATE`; else `NULL` |
| | NULL, zero or negative sales/price; sales ≠ quantity × price | Recalculate using business rules (below) |
| `erp_cust_az12` | `NAS` prefix on customer ID prevents joining to CRM | Strip prefix |
| | Birthdates in the future | Set to `NULL` |
| | Inconsistent gender values | Standardise to `Male/Female/n/a` |
| `erp_loc_a101` | Hyphen in customer ID (`AW-0001…`) | `REPLACE(cid, '-', '')` |
| | Country codes, variants, blanks, NULLs | Standardise to full names; blanks → `n/a` |
| `erp_px_cat_g1v2` | None found | Loaded as-is through Silver to keep every table on the same path |

### 8.5 Key transformations

**Deduplication and standardisation (customers)**

```sql
SELECT
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname)  AS cst_lastname,
    CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
         WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
         ELSE 'n/a' END AS cst_marital_status,
    CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
         WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
         ELSE 'n/a' END AS cst_gndr,
    cst_create_date
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;
```

**Rebuilding product validity dates**

Swapping start and end dates would have produced overlapping price periods. Instead, each record's end date is derived from the next record's start date:

```sql
CAST(prd_start_dt AS DATE) AS prd_start_dt,
CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
```

The newest record per product gets a `NULL` end date, meaning it is the current record.

**Deriving keys from a composite product key**

```sql
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,   -- matches the ERP category ID
SUBSTRING(prd_key, 7, LEN(prd_key))         AS prd_key   -- matches sales_details
```

**Converting integer dates**

```sql
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
     ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) END AS sls_order_dt
```

SQL Server cannot cast an `INT` directly to `DATE`, so the value is cast to `VARCHAR` first.

**Sales business rules**

The rule applied: *sales = quantity × price*, and none of the three may be NULL, zero or negative.

```sql
CASE WHEN sls_sales IS NULL OR sls_sales <= 0
          OR sls_sales != sls_quantity * ABS(sls_price)
     THEN sls_quantity * ABS(sls_price)
     ELSE sls_sales END AS sls_sales,

CASE WHEN sls_price IS NULL OR sls_price <= 0
     THEN sls_sales / NULLIF(sls_quantity, 0)
     ELSE sls_price END AS sls_price
```

`NULLIF(sls_quantity, 0)` protects against a future divide-by-zero.

**ERP key alignment**

```sql
-- erp_cust_az12: strip 'NAS' prefix
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END AS cid,

-- erp_loc_a101: strip hyphen
REPLACE(cid, '-', '') AS cid
```

After each transformation I confirmed that the cleaned keys fully matched the CRM keys (a `NOT IN` check returning no rows).

### 8.6 Silver load procedure

Script: [`scripts/silver/proc_load_silver.sql`](../scripts/silver/proc_load_silver.sql)

`silver.load_silver` truncates and reloads all six Silver tables from Bronze, using the same logging, timing and `TRY…CATCH` pattern as the Bronze procedure so both follow one standard.

```sql
EXEC silver.load_silver;
```

### 8.7 Types of transformation applied

| Type | Examples |
|---|---|
| Removing duplicates and filtering | Latest record per customer |
| Trimming unwanted spaces | Names, country |
| Handling missing values | Gender, marital status, cost, country |
| Handling invalid values | Future birthdates, malformed dates, key prefixes |
| Standardisation and normalisation | Gender, marital status, product line, country |
| Data type casting | `INT` → `DATE`, `DATETIME` → `DATE` |
| Derived columns | `cat_id`, `prd_key`, recalculated sales and price |
| Data enrichment | Rebuilt product `end date` |

Business rules, aggregations and cross-source integration are intentionally left for Gold.

![Data Flow (Silver)](data_flow_silver.png)

---

## 9. Gold layer

**Process:** identify business objects → integrate → classify (dimension or fact) → rename → validate → document.

### 9.1 Data modelling approach

Modelling can be conceptual, logical or physical. I produced the **logical model** (entities, columns, keys, relationships); the SQL itself acts as the physical model.

| | Star schema | Snowflake schema |
|---|---|---|
| Structure | Fact in the centre, dimensions around it | Dimensions split into sub-dimensions |
| Querying | Simple, fewer joins | More joins |

I chose the **star schema** because it is simple to understand, fast to query and well suited to BI tools.

**Facts vs. dimensions**

- **Dimension:** descriptive (who / what / where): customers, products.
- **Fact:** events with measures (how much / how many): sales. A fact holds keys to dimensions, dates and numeric measures.

### 9.2 Business objects

I tagged every source table with the business object it describes:

| Business object | Source tables |
|---|---|
| Customers | `crm_cust_info`, `erp_cust_az12`, `erp_loc_a101` |
| Products | `crm_prd_info`, `erp_px_cat_g1v2` |
| Sales | `crm_sales_details` |

### 9.3 Join approach

- Start from the master table and use **`LEFT JOIN`** for the rest, so no record is lost when the second source lacks a match.
- After joining, check for **duplicates** (a one-to-many join would multiply rows).
- Unexpected NULLs in joined columns indicate a bad join key.

### 9.4 `gold.dim_customers`

Integrates three tables. **Gender** appears in both CRM and ERP and sometimes conflicts. After defining **CRM as the master source** for customer attributes, the rule is: use CRM gender when available; otherwise fall back to ERP; otherwise `n/a`. A `NULL` arising from the join (no ERP match) is handled with `COALESCE`.

```sql
CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,   -- surrogate key
    ci.cst_id                              AS customer_id,
    ci.cst_key                             AS customer_number,
    ci.cst_firstname                       AS first_name,
    ci.cst_lastname                        AS last_name,
    la.cntry                               AS country,
    ci.cst_marital_status                  AS marital_status,
    CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
         ELSE COALESCE(ca.gen, 'n/a') END  AS gender,
    ca.bdate                               AS birthdate,
    ci.cst_create_date                     AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101  la ON ci.cst_key = la.cid;
```

A **surrogate key** is a system-generated identifier with no business meaning. It decouples the model from source-system keys and gives full control over relationships.

### 9.5 `gold.dim_products`

Joins products to categories. Since only the latest data is required, historical product rows are filtered out: an open record (`prd_end_dt IS NULL`) is the current one.

```sql
CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;
```

### 9.6 `gold.fact_sales`

Sales transactions contain dates, measures and keys to multiple dimensions, so this is a **fact**. A **dimension key lookup** replaces the source business keys with the surrogate keys of the dimensions. Columns are ordered as dimension keys → dates → measures.

```sql
CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,
    cu.customer_key AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products  pr ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu ON sd.sls_cust_id = cu.customer_id;
```

Script containing all three views: [`scripts/gold/ddl_gold.sql`](../scripts/gold/ddl_gold.sql)

### 9.7 Data model

![Star Schema](data_model.png)

Relationships are **one-to-many** from each dimension to the fact: a customer must exist in the dimension but may have zero, one or many orders. The business rule `sales = quantity × price` is annotated on the model.

### 9.8 Data catalog

Column-level documentation for each Gold object is in the [Data Catalog](data_catalog.md). Descriptions include example values (e.g. gender is `Male`, `Female` or `n/a`) so consumers know what to expect without querying the data.

### 9.9 Final lineage

![Data Flow (Gold)](data_flow_gold.png)

| Gold object | Built from |
|---|---|
| `fact_sales` | `crm_sales_details` |
| `dim_customers` | `crm_cust_info`, `erp_cust_az12`, `erp_loc_a101` |
| `dim_products` | `crm_prd_info`, `erp_px_cat_g1v2` |

---

## 10. Testing and validation

Reusable scripts in [`tests/`](../tests). **Every check is expected to return no rows.**

### Silver: [`quality_checks_silver.sql`](../tests/quality_checks_silver.sql)

| Check | Example |
|---|---|
| Null or duplicate primary key | `GROUP BY cst_id HAVING COUNT(*) > 1 OR cst_id IS NULL` |
| Unwanted spaces | `WHERE col != TRIM(col)` |
| Standardisation | `SELECT DISTINCT` on low-cardinality columns |
| Invalid date range / order | `WHERE order_dt > ship_dt OR order_dt > due_dt` |
| Business-rule consistency | `WHERE sales != quantity * price OR … <= 0` |

### Gold: [`quality_checks_gold.sql`](../tests/quality_checks_gold.sql)

```sql
-- Surrogate key uniqueness
SELECT customer_key, COUNT(*) FROM gold.dim_customers GROUP BY customer_key HAVING COUNT(*) > 1;
SELECT product_key,  COUNT(*) FROM gold.dim_products  GROUP BY product_key  HAVING COUNT(*) > 1;

-- Referential integrity: every fact row connects to both dimensions
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products  p ON p.product_key  = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;
```

Run these after every ETL execution, or whenever transformation logic changes.

---

## 11. Documentation deliverables

| Document | Location | Purpose |
|---|---|---|
| README | `README.md` | Project overview and quick start |
| This walkthrough | `docs/project_walkthrough.md` | Detailed design and build record |
| Data architecture diagram | `docs/data_architecture.png` | Layers, tools and flow at a glance |
| Data flow / lineage diagram | `docs/data_flow*.png` | Source → Bronze → Silver → Gold |
| Data integration model | `docs/data_integration.png` | How source tables relate |
| Data model (star schema) | `docs/data_model.png` | How Gold tables connect |
| Data catalog | `docs/data_catalog.md` | Table and column descriptions |
| Quality check scripts | `tests/` | Repeatable validation |

---

## 12. How to run the project

```text
1. scripts/init_database.sql              -- creates DataWarehouse + schemas (destructive!)
2. scripts/bronze/ddl_bronze.sql          -- Bronze tables
3. scripts/silver/ddl_silver.sql          -- Silver tables
4. scripts/bronze/proc_load_bronze.sql    -- creates bronze.load_bronze
5. scripts/silver/proc_load_silver.sql    -- creates silver.load_silver
6. scripts/gold/ddl_gold.sql              -- Gold views
```

Then run the pipeline:

```sql
EXEC bronze.load_bronze;
EXEC silver.load_silver;
```

Gold views read Silver live, so they refresh automatically. Finally, run the scripts in `tests/`.

**Source file location:** the Bronze procedure reads from `C:\sql\dwh_project\datasets\`. Place the `datasets/` folder there or edit the six paths in `proc_load_bronze.sql`.

---

## 13. Troubleshooting

| Problem | Likely cause and fix |
|---|---|
| `BULK INSERT` cannot open file | Wrong path or no read permission for the SQL Server service. The path is resolved on the machine running SQL Server |
| SQL Server running in Docker (Mac/Linux) | The container cannot see local disk. Copy files into the container and use that path |
| Values in wrong columns | Wrong delimiter, DDL column order, or commas inside values |
| Bronze count is one lower than the file | Expected; the header row is skipped |
| Duplicates after re-running a load | Missing `TRUNCATE TABLE` before the insert |
| `CREATE SCHEMA` fails in a batch | Missing `GO` separator |
| Cannot drop database because it is in use | Use the `SINGLE_USER WITH ROLLBACK IMMEDIATE` step in `init_database.sql` |
| Joins return NULLs | Keys not aligned (hyphens, `NAS` prefix, substring position) |
| Row count increases after a join | One-to-many join; run a `GROUP BY … HAVING COUNT(*) > 1` check |

---

## 14. Key lessons and future improvements

### Lessons learned

- **Design before code.** Fixing layer responsibilities and naming rules up front prevented rework.
- **Keep raw data untouched.** Bronze made it easy to trace every Silver and Gold value back to its source file.
- **Validate the way you load.** Row counts, column alignment and idempotency checks caught issues early.
- **Prototype logic in isolation.** Working through the product date problem with a few sample rows led to a rule that avoided overlapping periods.
- **Business rules need agreement.** Choices like "CRM is the master source" and "recalculate sales from quantity × price" should be confirmed with data owners in a real setting.
- **Standards compound.** Consistent naming, logging and headers made the scripts easier to read and maintain.

### Future improvements

- Incremental loads (merge/upsert) with change detection
- SCD Type 2 for product price history
- Audit table for run history, durations and errors
- Scheduling with SQL Server Agent or an orchestration tool
- Automated quality checks that fail the pipeline on violations
- Additional metadata columns (source file, source system)
- Reporting views (`report_customers`, `report_products`) and BI dashboards
- Porting the design to a cloud warehouse

---

## 15. Glossary

| Term | Meaning |
|---|---|
| **ETL / ELT** | Extract-Transform-Load / Extract-Load-Transform |
| **Medallion architecture** | Bronze (raw) → Silver (clean) → Gold (business-ready) |
| **Data lineage** | The traceable path of data from source to final object |
| **Surrogate key** | System-generated unique key with no business meaning |
| **Business key** | Identifier that comes from the source or business |
| **Dimension** | Descriptive table (who / what / where) |
| **Fact** | Event table with measures (how much / how many) |
| **Star schema** | Fact table surrounded by dimension tables |
| **Full load** | Reload all data each run |
| **Incremental load** | Load only new or changed data |
| **SCD** | Slowly Changing Dimension: how history is handled |
| **Idempotent** | Safe to run repeatedly with the same result |
| **Metadata column** | Engineer-added column describing the load (e.g. `dwh_create_date`) |
| **Referential integrity** | Every foreign key has a matching row in the referenced table |
