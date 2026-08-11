/* ============================================================================
   DATA WAREHOUSE + ETL PRACTICE PROJECT — SQL Server
   ============================================================================
   PURPOSE
   This single script builds an end-to-end practice environment:

     1. STAGING layer  (schema: staging) — messy, source-system-style raw
        tables: inconsistent date formats stored as text, currency symbols
        mixed into price columns, mixed casing, NULLs, duplicate rows.
        This is what a real extract from an OLTP system usually looks like,
        so it gives you real cleaning/transformation work to do.

     2. DATA WAREHOUSE layer (schema: dwh) — a classic star schema:
        dim_date, dim_customer (SCD Type 2), dim_product, dim_store,
        fact_sales.

     3. ETL LOGIC — a set of T-SQL stored procedures that clean, conform,
        and load staging -> dwh. Use these as-is to practice SQL Server ETL,
        OR treat staging.* as your SOURCE and dwh.* as your TARGET inside
        Informatica PowerCenter/Developer and build the same mappings there
        (cleansing expressions, lookup transformations for SCD2, aggregator
        transformations, etc.) instead of running the procedures below.

     4. A PRACTICE QUERY LIBRARY at the bottom: window functions, running
        totals, RFM segmentation, YoY growth, top-N-per-group, pivoting,
        gaps-and-islands, and recursive CTEs — all against the finished
        star schema.

   HOW TO USE
     - Run this whole script once to build and populate everything
       (staging + empty dwh tables + calendar dimension).
     - Then either:
         a) EXEC dwh.usp_etl_run_all;   -- run the full T-SQL ETL, or
         b) Point Informatica at staging.* as sources and dwh.* as targets
            and build your own mappings (leave the dwh tables empty and
            skip step a).
     - Finally, run the queries in section 6 to practice.
   ============================================================================ */

-- ============================================================================
-- SECTION 0: DATABASE
-- ============================================================================
USE master;
GO

IF DB_ID('DWH_Practice') IS NOT NULL
BEGIN
    ALTER DATABASE DWH_Practice SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DWH_Practice;
END
GO

CREATE DATABASE DWH_Practice;
GO

USE DWH_Practice;
GO

CREATE SCHEMA staging AUTHORIZATION dbo;
GO
CREATE SCHEMA dwh AUTHORIZATION dbo;
GO

-- ============================================================================
-- SECTION 1: STAGING (RAW / SOURCE) TABLES — deliberately messy
-- ============================================================================

-- Raw customer extract: names have inconsistent casing, some emails/phones
-- are missing, signup_date is TEXT stored in three different formats.
CREATE TABLE staging.raw_customers (
    customer_id  INT,             -- business key from the source system
    first_name   VARCHAR(50),
    last_name    VARCHAR(50),
    email        VARCHAR(100),    -- NULL for ~8% of rows on purpose
    phone        VARCHAR(50),     -- NULL for ~20% of rows on purpose
    city         VARCHAR(50),
    country      VARCHAR(50),
    signup_date  VARCHAR(20),     -- TEXT: mixes 'yyyy-mm-dd', 'dd/mm/yyyy', 'mm/dd/yyyy'
    load_ts      DATETIME DEFAULT GETDATE()
);

-- Raw product catalog: price is TEXT and sometimes has a '$' sign.
CREATE TABLE staging.raw_products (
    product_id   INT,
    product_name VARCHAR(100),
    category     VARCHAR(50),
    subcategory  VARCHAR(50),
    unit_price   VARCHAR(20),     -- TEXT, e.g. '19.99' or '$19.99'
    supplier     VARCHAR(100),
    load_ts      DATETIME DEFAULT GETDATE()
);

-- Raw store list.
CREATE TABLE staging.raw_stores (
    store_id   INT,
    store_name VARCHAR(100),
    region     VARCHAR(50),
    country    VARCHAR(50),
    open_date  VARCHAR(20),
    load_ts    DATETIME DEFAULT GETDATE()
);

-- Raw sales transactions: quantity/price/discount are all TEXT, discount
-- sometimes carries a trailing '%'.
CREATE TABLE staging.raw_sales (
    transaction_id INT,
    customer_id    INT,
    product_id     INT,
    store_id       INT,
    quantity       VARCHAR(10),
    sale_date      VARCHAR(20),
    unit_price     VARCHAR(20),
    discount_pct   VARCHAR(10),   -- e.g. '10' or '10%'
    payment_method VARCHAR(20),
    load_ts        DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- SECTION 2: POPULATE STAGING WITH SYNTHETIC "MESSY" DATA
-- (no external data file needed — generated purely with T-SQL)
-- ============================================================================

-- ---- 2.1 Customers (~2,000 rows, plus 30 intentional duplicates) ----------
;WITH tally AS (
    SELECT TOP (2000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO staging.raw_customers (customer_id, first_name, last_name, email, phone, city, country, signup_date)
SELECT
    n,
    CASE n % 10
        WHEN 0 THEN 'ahmed'  WHEN 1 THEN 'Sara'  WHEN 2 THEN 'MOHAMED' WHEN 3 THEN 'laila'
        WHEN 4 THEN 'Omar'   WHEN 5 THEN 'Nour'   WHEN 6 THEN 'khaled'  WHEN 7 THEN 'Mona'
        WHEN 8 THEN 'Youssef' ELSE 'Hana' END,
    CASE n % 7
        WHEN 0 THEN 'hassan' WHEN 1 THEN 'Ali' WHEN 2 THEN 'IBRAHIM' WHEN 3 THEN 'saeed'
        WHEN 4 THEN 'Mostafa' WHEN 5 THEN 'Fathy' ELSE 'gomaa' END,
    CASE WHEN n % 13 = 0 THEN NULL ELSE 'customer' + CAST(n AS VARCHAR) + '@mail.com' END,
    CASE WHEN n % 5 = 0 THEN NULL
         ELSE '01' + RIGHT('000000000' + CAST(ABS(CHECKSUM(NEWID())) % 999999999 AS VARCHAR), 9) END,
    CASE n % 6
        WHEN 0 THEN 'Cairo' WHEN 1 THEN 'Giza' WHEN 2 THEN 'Alexandria'
        WHEN 3 THEN 'Mansoura' WHEN 4 THEN 'Aswan' ELSE 'Luxor' END,
    'Egypt',
    -- three different text date formats mixed on purpose
    CASE n % 3
        WHEN 0 THEN CONVERT(VARCHAR, DATEADD(DAY, -n, '2024-06-01'), 23)   -- yyyy-mm-dd
        WHEN 1 THEN CONVERT(VARCHAR, DATEADD(DAY, -n, '2024-06-01'), 103)  -- dd/mm/yyyy
        ELSE        CONVERT(VARCHAR, DATEADD(DAY, -n, '2024-06-01'), 101)  -- mm/dd/yyyy
    END
FROM tally;

-- inject 30 duplicate customer rows (same business key) for dedup practice
INSERT INTO staging.raw_customers (customer_id, first_name, last_name, email, phone, city, country, signup_date)
SELECT TOP (30) customer_id, first_name, last_name, email, phone, city, country, signup_date
FROM staging.raw_customers
ORDER BY NEWID();
GO

-- ---- 2.2 Products (~200 rows) ---------------------------------------------
;WITH tally AS (
    SELECT TOP (200) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO staging.raw_products (product_id, product_name, category, subcategory, unit_price, supplier)
SELECT
    n,
    'Product ' + CAST(n AS VARCHAR),
    CASE n % 5
        WHEN 0 THEN 'Electronics' WHEN 1 THEN 'Grocery' WHEN 2 THEN 'Home & Kitchen'
        WHEN 3 THEN 'Apparel' ELSE 'Beauty' END,
    CASE n % 5
        WHEN 0 THEN 'Mobile Accessories' WHEN 1 THEN 'Snacks' WHEN 2 THEN 'Cookware'
        WHEN 3 THEN 'Men' ELSE 'Skincare' END,
    -- mix plain numbers with '$' prefixed strings
    CASE WHEN n % 4 = 0
         THEN '$' + CAST(CAST((5 + (n % 50) + 0.99) AS DECIMAL(10,2)) AS VARCHAR)
         ELSE CAST(CAST((5 + (n % 50) + 0.99) AS DECIMAL(10,2)) AS VARCHAR)
    END,
    'Supplier ' + CAST(1 + (n % 15) AS VARCHAR)
FROM tally;
GO

-- ---- 2.3 Stores (15 rows) ---------------------------------------------
;WITH tally AS (SELECT TOP (15) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects)
INSERT INTO staging.raw_stores (store_id, store_name, region, country, open_date)
SELECT
    n,
    'Store ' + CAST(n AS VARCHAR),
    CASE n % 4 WHEN 0 THEN 'Cairo Region' WHEN 1 THEN 'Delta Region'
                WHEN 2 THEN 'Upper Egypt' ELSE 'Red Sea Region' END,
    'Egypt',
    CONVERT(VARCHAR, DATEADD(YEAR, -(n % 5), '2023-01-01'), 23)
FROM tally;
GO

-- ---- 2.4 Sales transactions (~120,000 rows) --------------------------------
-- Random but reproducible-ish spread across ~2 years, random FKs, messy
-- price/quantity/discount text formatting.
;WITH tally AS (
    SELECT TOP (120000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO staging.raw_sales (transaction_id, customer_id, product_id, store_id,
                                quantity, sale_date, unit_price, discount_pct, payment_method)
SELECT
    n,
    1 + (ABS(CHECKSUM(NEWID())) % 2000),   -- customer_id 1..2000
    1 + (ABS(CHECKSUM(NEWID())) % 200),    -- product_id  1..200
    1 + (ABS(CHECKSUM(NEWID())) % 15),     -- store_id    1..15
    CAST(1 + (ABS(CHECKSUM(NEWID())) % 5) AS VARCHAR),   -- quantity 1..5
    CONVERT(VARCHAR, DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 730), '2026-08-01'), 23), -- yyyy-mm-dd
    CAST(CAST((5 + (ABS(CHECKSUM(NEWID())) % 50) + 0.99) AS DECIMAL(10,2)) AS VARCHAR),
    CASE WHEN ABS(CHECKSUM(NEWID())) % 3 = 0
         THEN CAST(ABS(CHECKSUM(NEWID())) % 30 AS VARCHAR) + '%'
         ELSE CAST(ABS(CHECKSUM(NEWID())) % 30 AS VARCHAR)
    END,
    CASE ABS(CHECKSUM(NEWID())) % 4
        WHEN 0 THEN 'Cash' WHEN 1 THEN 'Credit Card' WHEN 2 THEN 'Debit Card' ELSE 'Mobile Wallet' END
FROM tally;
GO

-- sanity check on staging row counts
SELECT 'raw_customers' AS tbl, COUNT(*) AS rows_ FROM staging.raw_customers
UNION ALL SELECT 'raw_products', COUNT(*) FROM staging.raw_products
UNION ALL SELECT 'raw_stores', COUNT(*) FROM staging.raw_stores
UNION ALL SELECT 'raw_sales', COUNT(*) FROM staging.raw_sales;
GO

-- ============================================================================
-- SECTION 3: DATA WAREHOUSE (STAR SCHEMA) TABLES
-- ============================================================================

-- ---- dim_date: standard calendar dimension, pre-built (not part of ETL) ---
CREATE TABLE dwh.dim_date (
    date_key      INT PRIMARY KEY,        -- yyyymmdd
    full_date     DATE NOT NULL,
    day_of_week   TINYINT,
    day_name      VARCHAR(10),
    day_of_month  TINYINT,
    month_number  TINYINT,
    month_name    VARCHAR(10),
    quarter       TINYINT,
    year          SMALLINT,
    is_weekend    BIT
);

-- ---- dim_customer: SCD Type 2 -----------------------------------------
CREATE TABLE dwh.dim_customer (
    customer_key   INT IDENTITY(1,1) PRIMARY KEY,   -- surrogate key
    customer_id    INT NOT NULL,                    -- business key from source
    first_name     VARCHAR(50),
    last_name      VARCHAR(50),
    email          VARCHAR(100),
    phone          VARCHAR(50),
    city           VARCHAR(50),
    country        VARCHAR(50),
    signup_date    DATE,
    valid_from     DATETIME NOT NULL,
    valid_to       DATETIME NULL,
    is_current     BIT NOT NULL DEFAULT 1
);

-- ---- dim_product (Type 1 — overwrite on change, simple for practice) ------
CREATE TABLE dwh.dim_product (
    product_key   INT IDENTITY(1,1) PRIMARY KEY,
    product_id    INT NOT NULL UNIQUE,
    product_name  VARCHAR(100),
    category      VARCHAR(50),
    subcategory   VARCHAR(50),
    unit_price    DECIMAL(10,2),
    supplier      VARCHAR(100)
);

-- ---- dim_store --------------------------------------------------------
CREATE TABLE dwh.dim_store (
    store_key   INT IDENTITY(1,1) PRIMARY KEY,
    store_id    INT NOT NULL UNIQUE,
    store_name  VARCHAR(100),
    region      VARCHAR(50),
    country     VARCHAR(50),
    open_date   DATE
);

-- ---- fact_sales ---------------------------------------------------------
CREATE TABLE dwh.fact_sales (
    sales_key       BIGINT IDENTITY(1,1) PRIMARY KEY,
    transaction_id  INT NOT NULL,
    date_key        INT NOT NULL REFERENCES dwh.dim_date(date_key),
    customer_key    INT NOT NULL REFERENCES dwh.dim_customer(customer_key),
    product_key     INT NOT NULL REFERENCES dwh.dim_product(product_key),
    store_key       INT NOT NULL REFERENCES dwh.dim_store(store_key),
    quantity        INT,
    unit_price      DECIMAL(10,2),
    discount_pct    DECIMAL(5,2),
    gross_amount    AS (CAST(quantity AS DECIMAL(10,2)) * unit_price) PERSISTED,
    net_amount      AS (CAST(quantity AS DECIMAL(10,2)) * unit_price
                         * (1 - discount_pct / 100.0)) PERSISTED,
    payment_method  VARCHAR(20)
);
GO

-- ============================================================================
-- SECTION 4: ETL — CLEAN + LOAD STAGING -> DWH  (T-SQL version)
-- If you are practicing with Informatica instead, skip this whole section:
-- point Informatica sources at staging.* and targets at dwh.*, and build the
-- equivalent Expression / Lookup / Aggregator transformations yourself.
-- ============================================================================

-- ---- 4.1 dim_date loader: builds one row per day across the sales range ---
CREATE OR ALTER PROCEDURE dwh.usp_etl_load_dim_date
    @start_date DATE = '2023-01-01',
    @end_date   DATE = '2026-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE dwh.dim_date;

    ;WITH dates AS (
        SELECT @start_date AS d
        UNION ALL
        SELECT DATEADD(DAY, 1, d) FROM dates WHERE d < @end_date
    )
    INSERT INTO dwh.dim_date (date_key, full_date, day_of_week, day_name, day_of_month,
                               month_number, month_name, quarter, year, is_weekend)
    SELECT
        CONVERT(INT, CONVERT(VARCHAR(8), d, 112))         AS date_key,
        d                                                   AS full_date,
        DATEPART(WEEKDAY, d)                                AS day_of_week,
        DATENAME(WEEKDAY, d)                                AS day_name,
        DAY(d)                                              AS day_of_month,
        MONTH(d)                                            AS month_number,
        DATENAME(MONTH, d)                                  AS month_name,
        DATEPART(QUARTER, d)                                AS quarter,
        YEAR(d)                                             AS year,
        CASE WHEN DATENAME(WEEKDAY, d) IN ('Friday','Saturday') THEN 1 ELSE 0 END AS is_weekend
    FROM dates
    OPTION (MAXRECURSION 0);
END
GO

-- ---- 4.2 dim_customer loader: clean + dedup + SCD2 merge -------------------
CREATE OR ALTER PROCEDURE dwh.usp_etl_load_dim_customer
AS
BEGIN
    SET NOCOUNT ON;

    -- Step 1: clean staging data into a temp working set
    --   - proper-case names
    --   - trim whitespace
    --   - parse the three mixed text date formats into a real DATE
    --   - dedup: keep the most recently loaded row per customer_id
    IF OBJECT_ID('tempdb..#clean_customers') IS NOT NULL DROP TABLE #clean_customers;

    SELECT *
    INTO #clean_customers
    FROM (
        SELECT
            customer_id,
            CONCAT(UPPER(LEFT(LTRIM(RTRIM(first_name)), 1)), LOWER(SUBSTRING(LTRIM(RTRIM(first_name)), 2, 49))) AS first_name,
            CONCAT(UPPER(LEFT(LTRIM(RTRIM(last_name)), 1)),  LOWER(SUBSTRING(LTRIM(RTRIM(last_name)), 2, 49)))  AS last_name,
            NULLIF(LTRIM(RTRIM(email)), '')                 AS email,
            NULLIF(LTRIM(RTRIM(phone)), '')                 AS phone,
            LTRIM(RTRIM(city))                               AS city,
            LTRIM(RTRIM(country))                            AS country,
            -- try each known source format in turn until one parses
            COALESCE(
                TRY_CONVERT(DATE, signup_date, 23),   -- yyyy-mm-dd
                TRY_CONVERT(DATE, signup_date, 103),  -- dd/mm/yyyy
                TRY_CONVERT(DATE, signup_date, 101)   -- mm/dd/yyyy
            ) AS signup_date,
            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY load_ts DESC) AS rn
        FROM staging.raw_customers
    ) x
    WHERE rn = 1;   -- dedup: one row per business key

    -- Step 2: close out changed records (SCD2) — any current dim row whose
    -- tracked attributes differ from the cleaned source gets end-dated.
    UPDATE d
    SET d.valid_to = SYSDATETIME(), d.is_current = 0
    FROM dwh.dim_customer d
    JOIN #clean_customers c ON c.customer_id = d.customer_id
    WHERE d.is_current = 1
      AND (  ISNULL(d.email,'') <> ISNULL(c.email,'')
          OR ISNULL(d.phone,'') <> ISNULL(c.phone,'')
          OR ISNULL(d.city,'')  <> ISNULL(c.city,'') );

    -- Step 3: insert brand-new customers, and new versions of changed ones
    INSERT INTO dwh.dim_customer (customer_id, first_name, last_name, email, phone,
                                   city, country, signup_date, valid_from, valid_to, is_current)
    SELECT
        c.customer_id, c.first_name, c.last_name, c.email, c.phone,
        c.city, c.country, c.signup_date, SYSDATETIME(), NULL, 1
    FROM #clean_customers c
    LEFT JOIN dwh.dim_customer d
        ON d.customer_id = c.customer_id AND d.is_current = 1
    WHERE d.customer_key IS NULL;
END
GO

-- ---- 4.3 dim_product loader: clean price text, Type-1 upsert --------------
CREATE OR ALTER PROCEDURE dwh.usp_etl_load_dim_product
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH clean AS (
        SELECT
            product_id,
            LTRIM(RTRIM(product_name)) AS product_name,
            category, subcategory,
            -- strip a leading '$' before casting to money
            TRY_CONVERT(DECIMAL(10,2), REPLACE(unit_price, '$', '')) AS unit_price,
            supplier,
            ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY load_ts DESC) AS rn
        FROM staging.raw_products
    )
    MERGE dwh.dim_product AS tgt
    USING (SELECT * FROM clean WHERE rn = 1) AS src
        ON tgt.product_id = src.product_id
    WHEN MATCHED THEN
        UPDATE SET product_name = src.product_name, category = src.category,
                   subcategory = src.subcategory, unit_price = src.unit_price,
                   supplier = src.supplier
    WHEN NOT MATCHED THEN
        INSERT (product_id, product_name, category, subcategory, unit_price, supplier)
        VALUES (src.product_id, src.product_name, src.category, src.subcategory,
                src.unit_price, src.supplier);
END
GO

-- ---- 4.4 dim_store loader ---------------------------------------------
CREATE OR ALTER PROCEDURE dwh.usp_etl_load_dim_store
AS
BEGIN
    SET NOCOUNT ON;

    MERGE dwh.dim_store AS tgt
    USING (
        SELECT store_id, LTRIM(RTRIM(store_name)) AS store_name, region, country,
               TRY_CONVERT(DATE, open_date, 23) AS open_date
        FROM staging.raw_stores
    ) AS src
        ON tgt.store_id = src.store_id
    WHEN MATCHED THEN
        UPDATE SET store_name = src.store_name, region = src.region,
                   country = src.country, open_date = src.open_date
    WHEN NOT MATCHED THEN
        INSERT (store_id, store_name, region, country, open_date)
        VALUES (src.store_id, src.store_name, src.region, src.country, src.open_date);
END
GO

-- ---- 4.5 fact_sales loader: clean numeric text, resolve dim surrogate keys
CREATE OR ALTER PROCEDURE dwh.usp_etl_load_fact_sales
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE dwh.fact_sales;

    ;WITH clean AS (
        SELECT
            s.transaction_id,
            TRY_CONVERT(DATE, s.sale_date, 23)                                   AS sale_date,
            s.customer_id,
            s.product_id,
            s.store_id,
            TRY_CONVERT(INT, s.quantity)                                          AS quantity,
            TRY_CONVERT(DECIMAL(10,2), REPLACE(s.unit_price, '$', ''))            AS unit_price,
            TRY_CONVERT(DECIMAL(5,2), REPLACE(s.discount_pct, '%', ''))           AS discount_pct,
            s.payment_method,
            ROW_NUMBER() OVER (PARTITION BY s.transaction_id ORDER BY s.load_ts DESC) AS rn
        FROM staging.raw_sales s
    )
    INSERT INTO dwh.fact_sales (transaction_id, date_key, customer_key, product_key,
                                 store_key, quantity, unit_price, discount_pct, payment_method)
    SELECT
        c.transaction_id,
        CONVERT(INT, CONVERT(VARCHAR(8), c.sale_date, 112)) AS date_key,
        dc.customer_key,
        dp.product_key,
        ds.store_key,
        c.quantity,
        c.unit_price,
        ISNULL(c.discount_pct, 0),
        c.payment_method
    FROM clean c
    JOIN dwh.dim_customer dc ON dc.customer_id = c.customer_id AND dc.is_current = 1
    JOIN dwh.dim_product  dp ON dp.product_id  = c.product_id
    JOIN dwh.dim_store    ds ON ds.store_id    = c.store_id
    WHERE c.rn = 1
      AND c.sale_date IS NOT NULL
      AND c.quantity IS NOT NULL
      AND c.unit_price IS NOT NULL;
END
GO

-- ---- 4.6 master ETL runner: correct load order (dims before fact) ---------
CREATE OR ALTER PROCEDURE dwh.usp_etl_run_all
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dwh.usp_etl_load_dim_date;
    EXEC dwh.usp_etl_load_dim_customer;
    EXEC dwh.usp_etl_load_dim_product;
    EXEC dwh.usp_etl_load_dim_store;
    EXEC dwh.usp_etl_load_fact_sales;
END
GO

-- ---- run the full ETL now --------------------------------------------
EXEC dwh.usp_etl_run_all;
GO

-- ---- post-load validation: row counts + orphan check ----------------------
SELECT 'dim_date' AS tbl, COUNT(*) AS rows_ FROM dwh.dim_date
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dwh.dim_customer
UNION ALL SELECT 'dim_product', COUNT(*) FROM dwh.dim_product
UNION ALL SELECT 'dim_store', COUNT(*) FROM dwh.dim_store
UNION ALL SELECT 'fact_sales', COUNT(*) FROM dwh.fact_sales;

-- rows dropped during fact load (bad dates/quantities/prices) — expected > 0,
-- this is the "data quality exception count" you'd report on in a real ETL
SELECT COUNT(*) AS staging_sales_rows,
       (SELECT COUNT(*) FROM dwh.fact_sales) AS loaded_fact_rows,
       COUNT(*) - (SELECT COUNT(*) FROM dwh.fact_sales) AS rows_rejected_or_deduped
FROM staging.raw_sales;
GO


-- ============================================================================
-- SECTION 5: HELPFUL INDEXES FOR ANALYTICAL QUERIES
-- ============================================================================
CREATE INDEX ix_fact_sales_date     ON dwh.fact_sales(date_key);
CREATE INDEX ix_fact_sales_customer ON dwh.fact_sales(customer_key);
CREATE INDEX ix_fact_sales_product  ON dwh.fact_sales(product_key);
CREATE INDEX ix_fact_sales_store    ON dwh.fact_sales(store_key);
GO


-- ============================================================================
-- SECTION 6: COMPLEX QUERY PRACTICE LIBRARY
-- Run these one at a time against the finished star schema.
-- ============================================================================

-- 6.1 Running total of net revenue per month (window function: SUM OVER)
SELECT
    dd.year, dd.month_number, dd.month_name,
    SUM(f.net_amount) AS monthly_net_revenue,
    SUM(SUM(f.net_amount)) OVER (ORDER BY dd.year, dd.month_number
                                  ROWS UNBOUNDED PRECEDING) AS running_total_revenue
FROM dwh.fact_sales f
JOIN dwh.dim_date dd ON dd.date_key = f.date_key
GROUP BY dd.year, dd.month_number, dd.month_name
ORDER BY dd.year, dd.month_number;
GO

-- 6.2 Year-over-year revenue growth % per month (LAG window function)
;WITH monthly AS (
    SELECT dd.year, dd.month_number, SUM(f.net_amount) AS revenue
    FROM dwh.fact_sales f JOIN dwh.dim_date dd ON dd.date_key = f.date_key
    GROUP BY dd.year, dd.month_number
)
SELECT
    year, month_number, revenue,
    LAG(revenue, 12) OVER (ORDER BY year, month_number) AS revenue_same_month_last_year,
    CAST(
        100.0 * (revenue - LAG(revenue, 12) OVER (ORDER BY year, month_number))
        / NULLIF(LAG(revenue, 12) OVER (ORDER BY year, month_number), 0)
    AS DECIMAL(6,2)) AS yoy_growth_pct
FROM monthly
ORDER BY year, month_number;
GO

-- 6.3 Top 3 best-selling products per category (RANK / PARTITION BY)
;WITH product_sales AS (
    SELECT dp.category, dp.product_name, SUM(f.net_amount) AS revenue,
           RANK() OVER (PARTITION BY dp.category ORDER BY SUM(f.net_amount) DESC) AS rnk
    FROM dwh.fact_sales f
    JOIN dwh.dim_product dp ON dp.product_key = f.product_key
    GROUP BY dp.category, dp.product_name
)
SELECT * FROM product_sales WHERE rnk <= 3 ORDER BY category, rnk;
GO

-- 6.4 RFM segmentation (Recency, Frequency, Monetary) — classic warehouse exercise
;WITH rfm_base AS (
    SELECT
        dc.customer_id,
        DATEDIFF(DAY, MAX(dd.full_date), (SELECT MAX(full_date) FROM dwh.dim_date)) AS recency_days,
        COUNT(DISTINCT f.transaction_id) AS frequency,
        SUM(f.net_amount) AS monetary
    FROM dwh.fact_sales f
    JOIN dwh.dim_customer dc ON dc.customer_key = f.customer_key
    JOIN dwh.dim_date dd ON dd.date_key = f.date_key
    GROUP BY dc.customer_id
),
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,  -- more recent = higher score
        NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)        AS m_score
    FROM rfm_base
)
SELECT *,
    (r_score + f_score + m_score) AS rfm_total,
    CASE WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
         WHEN r_score <= 2 AND f_score <= 2 THEN 'At Risk'
         ELSE 'Regular' END AS segment
FROM rfm_scored
ORDER BY rfm_total DESC;
GO

-- 6.5 Customer purchase "gaps and islands": find consecutive months a customer
-- was active (classic advanced SQL interview pattern)
;WITH cust_months AS (
    SELECT DISTINCT dc.customer_id, dd.year, dd.month_number,
           dd.year * 12 + dd.month_number AS month_seq
    FROM dwh.fact_sales f
    JOIN dwh.dim_customer dc ON dc.customer_key = f.customer_key
    JOIN dwh.dim_date dd ON dd.date_key = f.date_key
),
grp AS (
    SELECT *,
        month_seq - ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY month_seq) AS island_id
    FROM cust_months
)
SELECT customer_id, MIN(month_seq) AS start_month_seq, MAX(month_seq) AS end_month_seq,
       COUNT(*) AS consecutive_months_active
FROM grp
GROUP BY customer_id, island_id
HAVING COUNT(*) >= 3          -- customers active 3+ consecutive months
ORDER BY consecutive_months_active DESC;
GO

-- 6.6 Pivot: revenue by payment method per quarter
SELECT * FROM (
    SELECT dd.year, dd.quarter, f.payment_method, f.net_amount
    FROM dwh.fact_sales f JOIN dwh.dim_date dd ON dd.date_key = f.date_key
) src
PIVOT (
    SUM(net_amount) FOR payment_method IN ([Cash], [Credit Card], [Debit Card], [Mobile Wallet])
) pvt
ORDER BY year, quarter;
GO

-- 6.7 Store ranking with dense_rank + percent of total (window aggregate)
SELECT
    ds.store_name, ds.region,
    SUM(f.net_amount) AS store_revenue,
    DENSE_RANK() OVER (ORDER BY SUM(f.net_amount) DESC) AS store_rank,
    CAST(100.0 * SUM(f.net_amount) / SUM(SUM(f.net_amount)) OVER () AS DECIMAL(5,2)) AS pct_of_total_revenue
FROM dwh.fact_sales f
JOIN dwh.dim_store ds ON ds.store_key = f.store_key
GROUP BY ds.store_name, ds.region
ORDER BY store_rank;
GO

-- 6.8 New vs. returning customer revenue split per month
;WITH first_purchase AS (
    SELECT customer_key, MIN(date_key) AS first_date_key
    FROM dwh.fact_sales
    GROUP BY customer_key
)
SELECT
    dd.year, dd.month_number,
    SUM(CASE WHEN f.date_key = fp.first_date_key THEN f.net_amount ELSE 0 END) AS new_customer_revenue,
    SUM(CASE WHEN f.date_key <> fp.first_date_key THEN f.net_amount ELSE 0 END) AS returning_customer_revenue
FROM dwh.fact_sales f
JOIN dwh.dim_date dd ON dd.date_key = f.date_key
JOIN first_purchase fp ON fp.customer_key = f.customer_key
GROUP BY dd.year, dd.month_number
ORDER BY dd.year, dd.month_number;
GO

-- 6.9 Moving average (3-month) of revenue — window frame practice
;WITH monthly AS (
    SELECT dd.year, dd.month_number, SUM(f.net_amount) AS revenue
    FROM dwh.fact_sales f JOIN dwh.dim_date dd ON dd.date_key = f.date_key
    GROUP BY dd.year, dd.month_number
)
SELECT year, month_number, revenue,
    AVG(revenue) OVER (ORDER BY year, month_number
                        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3mo
FROM monthly
ORDER BY year, month_number;
GO

-- 6.10 Recursive CTE: build a date spine per customer between first and last
-- purchase (useful for churn/activity-gap analysis)
;WITH cust_range AS (
    SELECT customer_key, MIN(date_key) AS min_dk, MAX(date_key) AS max_dk
    FROM dwh.fact_sales
    GROUP BY customer_key
)
SELECT customer_key, COUNT(*) AS days_in_lifecycle
FROM (
    SELECT cr.customer_key, dd.date_key
    FROM cust_range cr
    JOIN dwh.dim_date dd ON dd.date_key BETWEEN cr.min_dk AND cr.max_dk
) spine
GROUP BY customer_key
ORDER BY days_in_lifecycle DESC;
GO

/* ============================================================================
   NEXT STEPS FOR PRACTICE
   - Re-run staging generation with different messiness (add more NULLs, bad
     FKs, negative quantities) and adjust the ETL procs to handle them.
   - Convert usp_etl_load_dim_customer's SCD2 logic into an Informatica
     mapping using a Lookup + Expression + Update Strategy transformation.
   - Add a dim_promotion or dim_channel and extend fact_sales — practice
     schema evolution.
   - Wrap SECTION 4 procs in a SQL Server Agent job or an SSIS package to
     practice orchestration on top of the ETL logic.
   ============================================================================ */
