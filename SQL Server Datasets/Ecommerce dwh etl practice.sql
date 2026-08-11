/* ============================================================================
   E-COMMERCE ORDERS DATA WAREHOUSE + ETL PRACTICE PROJECT — SQL Server
   ============================================================================
   A second, different practice project from the retail/sales one — new
   domain, and a deliberately different modeling challenge: TWO fact tables
   at different grains (fact_orders = one row per order header, fact_order_items
   = one row per order line), so you get practice with multi-grain star
   schemas, header/line joins, and basket-style analysis.

   LAYERS
     1. staging  — messy raw e-commerce extract (orders, order_items,
        customers, products, employees/sales reps, shipping methods)
     2. dwh      — star schema: dim_date, dim_customer (SCD2), dim_product,
        dim_employee, dim_ship_method, fact_orders (header grain),
        fact_order_items (line grain)
     3. T-SQL ETL procedures — clean + load staging -> dwh
        (or use staging.* / dwh.* as Informatica source/target instead)
     4. A new complex-query practice library: basket analysis, employee
        performance ranking, cohort retention, snowflaked category rollups,
        order-to-shipping SLA analysis, and more.

   USAGE: run top to bottom in SSMS / Azure Data Studio against SQL Server
   (Developer Edition is fine). Builds and drops ECommerce_DWH_Practice.
   ============================================================================ */

-- ============================================================================
-- SECTION 0: DATABASE
-- ============================================================================
USE master;
GO
IF DB_ID('ECommerce_DWH_Practice') IS NOT NULL
BEGIN
    ALTER DATABASE ECommerce_DWH_Practice SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ECommerce_DWH_Practice;
END
GO
CREATE DATABASE ECommerce_DWH_Practice;
GO
USE ECommerce_DWH_Practice;
GO
CREATE SCHEMA staging AUTHORIZATION dbo;
GO
CREATE SCHEMA dwh AUTHORIZATION dbo;
GO

-- ============================================================================
-- SECTION 1: STAGING TABLES — messy raw e-commerce extract
-- ============================================================================

CREATE TABLE staging.raw_customers (
    customer_id  INT,
    full_name    VARCHAR(100),      -- messy: "first last" combined, mixed case
    email        VARCHAR(100),
    country      VARCHAR(50),
    signup_date  VARCHAR(20),       -- mixed text formats
    loyalty_tier VARCHAR(20),       -- inconsistent casing: 'gold','Gold','GOLD'
    load_ts      DATETIME DEFAULT GETDATE()
);

CREATE TABLE staging.raw_products (
    product_id   INT,
    product_name VARCHAR(100),
    category     VARCHAR(50),
    list_price   VARCHAR(20),       -- text, sometimes '$' prefixed
    is_active    VARCHAR(5),        -- text: 'Y'/'N'/'yes'/'no'/'1'/'0'
    load_ts      DATETIME DEFAULT GETDATE()
);

CREATE TABLE staging.raw_employees (
    employee_id INT,
    employee_name VARCHAR(100),
    department  VARCHAR(50),
    hire_date   VARCHAR(20),
    load_ts     DATETIME DEFAULT GETDATE()
);

CREATE TABLE staging.raw_ship_methods (
    ship_method_id INT,
    method_name    VARCHAR(50),
    carrier        VARCHAR(50),
    avg_days       VARCHAR(5),
    load_ts        DATETIME DEFAULT GETDATE()
);

-- header grain: one row per order
CREATE TABLE staging.raw_orders (
    order_id       INT,
    customer_id    INT,
    employee_id    INT,             -- sales rep who handled the order (nullable)
    ship_method_id INT,
    order_date     VARCHAR(20),
    ship_date      VARCHAR(20),     -- sometimes NULL = not yet shipped
    order_status   VARCHAR(20),     -- 'Completed','Cancelled','Returned','Pending'
    load_ts        DATETIME DEFAULT GETDATE()
);

-- line grain: one row per product within an order
CREATE TABLE staging.raw_order_items (
    order_item_id INT,
    order_id      INT,
    product_id    INT,
    quantity      VARCHAR(10),
    unit_price    VARCHAR(20),      -- price at time of sale, may differ from catalog
    discount_pct  VARCHAR(10),
    load_ts       DATETIME DEFAULT GETDATE()
);
GO

-- ============================================================================
-- SECTION 2: GENERATE SYNTHETIC MESSY DATA
-- ============================================================================

-- ---- 2.1 customers (~1,500) ------------------------------------------------
;WITH tally AS (
    SELECT TOP (1500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO staging.raw_customers (customer_id, full_name, email, country, signup_date, loyalty_tier)
SELECT
    n,
    (CASE n % 8 WHEN 0 THEN 'ahmed hassan' WHEN 1 THEN 'Sara Ali' WHEN 2 THEN 'MOHAMED IBRAHIM'
                WHEN 3 THEN 'laila saeed' WHEN 4 THEN 'Omar Mostafa' WHEN 5 THEN 'Nour Fathy'
                WHEN 6 THEN 'khaled gomaa' ELSE 'Mona Sami' END),
    CASE WHEN n % 11 = 0 THEN NULL ELSE 'cust' + CAST(n AS VARCHAR) + '@shop.com' END,
    CASE n % 5 WHEN 0 THEN 'Egypt' WHEN 1 THEN 'UAE' WHEN 2 THEN 'Saudi Arabia'
                WHEN 3 THEN 'Jordan' ELSE 'Qatar' END,
    CASE n % 3
        WHEN 0 THEN CONVERT(VARCHAR, DATEADD(DAY, -n, '2024-03-01'), 23)
        WHEN 1 THEN CONVERT(VARCHAR, DATEADD(DAY, -n, '2024-03-01'), 103)
        ELSE        CONVERT(VARCHAR, DATEADD(DAY, -n, '2024-03-01'), 101)
    END,
    CASE n % 4 WHEN 0 THEN 'gold' WHEN 1 THEN 'Silver' WHEN 2 THEN 'BRONZE' ELSE 'Gold' END
FROM tally;
GO

-- ---- 2.2 products (~150) ---------------------------------------------
;WITH tally AS (SELECT TOP (150) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects)
INSERT INTO staging.raw_products (product_id, product_name, category, list_price, is_active)
SELECT
    n,
    'SKU-' + CAST(n AS VARCHAR),
    CASE n % 6 WHEN 0 THEN 'Electronics' WHEN 1 THEN 'Home' WHEN 2 THEN 'Fashion'
                WHEN 3 THEN 'Toys' WHEN 4 THEN 'Sports' ELSE 'Books' END,
    CASE WHEN n % 4 = 0 THEN '$' + CAST(CAST((10 + (n % 80) + 0.5) AS DECIMAL(10,2)) AS VARCHAR)
         ELSE CAST(CAST((10 + (n % 80) + 0.5) AS DECIMAL(10,2)) AS VARCHAR) END,
    CASE n % 5 WHEN 0 THEN 'N' WHEN 1 THEN 'no' WHEN 2 THEN '0' WHEN 3 THEN 'Y' ELSE 'yes' END
FROM tally;
GO

-- ---- 2.3 employees (12 sales reps) -------------------------------------
;WITH tally AS (SELECT TOP (12) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects)
INSERT INTO staging.raw_employees (employee_id, employee_name, department, hire_date)
SELECT n, 'Rep ' + CAST(n AS VARCHAR),
       CASE n % 3 WHEN 0 THEN 'Online Sales' WHEN 1 THEN 'Support' ELSE 'Key Accounts' END,
       CONVERT(VARCHAR, DATEADD(YEAR, -(n % 6), '2023-01-01'), 23)
FROM tally;
GO

-- ---- 2.4 ship methods -------------------------------------------------
INSERT INTO staging.raw_ship_methods (ship_method_id, method_name, carrier, avg_days) VALUES
(1, 'Standard', 'Aramex', '5'),
(2, 'Express', 'DHL', '2'),
(3, 'Economy', 'Egypt Post', '9'),
(4, 'Same-Day', 'Local Courier', '1');
GO

-- ---- 2.5 orders (~40,000 headers) --------------------------------------
;WITH tally AS (
    SELECT TOP (40000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO staging.raw_orders (order_id, customer_id, employee_id, ship_method_id,
                                 order_date, ship_date, order_status)
SELECT
    n,
    1 + (ABS(CHECKSUM(NEWID())) % 1500),
    CASE WHEN ABS(CHECKSUM(NEWID())) % 5 = 0 THEN NULL ELSE 1 + (ABS(CHECKSUM(NEWID())) % 12) END,
    1 + (ABS(CHECKSUM(NEWID())) % 4),
    CONVERT(VARCHAR, DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 730), '2026-08-01'), 23),
    CASE WHEN ABS(CHECKSUM(NEWID())) % 6 = 0 THEN NULL   -- not yet shipped
         ELSE CONVERT(VARCHAR, DATEADD(DAY, (ABS(CHECKSUM(NEWID())) % 7) + 1,
                       DATEADD(DAY, -(ABS(CHECKSUM(NEWID())) % 730), '2026-08-01')), 23) END,
    CASE ABS(CHECKSUM(NEWID())) % 10
        WHEN 0 THEN 'Cancelled' WHEN 1 THEN 'Returned' WHEN 2 THEN 'Pending'
        ELSE 'Completed' END
FROM tally;
GO

-- ---- 2.6 order items (~1-4 lines per order, ~100,000 rows) ---------------
;WITH lines AS (
    SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO staging.raw_order_items (order_item_id, order_id, product_id, quantity, unit_price, discount_pct)
SELECT
    n,
    1 + (ABS(CHECKSUM(NEWID())) % 40000),      -- order_id
    1 + (ABS(CHECKSUM(NEWID())) % 150),        -- product_id
    CAST(1 + (ABS(CHECKSUM(NEWID())) % 4) AS VARCHAR),
    CAST(CAST((10 + (ABS(CHECKSUM(NEWID())) % 80) + 0.5) AS DECIMAL(10,2)) AS VARCHAR),
    CASE WHEN ABS(CHECKSUM(NEWID())) % 3 = 0
         THEN CAST(ABS(CHECKSUM(NEWID())) % 25 AS VARCHAR) + '%'
         ELSE CAST(ABS(CHECKSUM(NEWID())) % 25 AS VARCHAR) END
FROM lines;
GO

SELECT 'raw_customers' t, COUNT(*) rows_ FROM staging.raw_customers
UNION ALL SELECT 'raw_products', COUNT(*) FROM staging.raw_products
UNION ALL SELECT 'raw_employees', COUNT(*) FROM staging.raw_employees
UNION ALL SELECT 'raw_ship_methods', COUNT(*) FROM staging.raw_ship_methods
UNION ALL SELECT 'raw_orders', COUNT(*) FROM staging.raw_orders
UNION ALL SELECT 'raw_order_items', COUNT(*) FROM staging.raw_order_items;
GO

-- ============================================================================
-- SECTION 3: DWH STAR SCHEMA (multi-grain: order header + order line facts)
-- ============================================================================

CREATE TABLE dwh.dim_date (
    date_key INT PRIMARY KEY, full_date DATE NOT NULL, day_of_week TINYINT,
    day_name VARCHAR(10), day_of_month TINYINT, month_number TINYINT,
    month_name VARCHAR(10), quarter TINYINT, year SMALLINT, is_weekend BIT
);

CREATE TABLE dwh.dim_customer (
    customer_key  INT IDENTITY(1,1) PRIMARY KEY,
    customer_id   INT NOT NULL,
    first_name    VARCHAR(50),
    last_name     VARCHAR(50),
    email         VARCHAR(100),
    country       VARCHAR(50),
    signup_date   DATE,
    loyalty_tier  VARCHAR(20),
    valid_from    DATETIME NOT NULL,
    valid_to      DATETIME NULL,
    is_current    BIT NOT NULL DEFAULT 1
);

CREATE TABLE dwh.dim_product (
    product_key   INT IDENTITY(1,1) PRIMARY KEY,
    product_id    INT NOT NULL UNIQUE,
    product_name  VARCHAR(100),
    category      VARCHAR(50),
    list_price    DECIMAL(10,2),
    is_active     BIT
);

CREATE TABLE dwh.dim_employee (
    employee_key  INT IDENTITY(1,1) PRIMARY KEY,
    employee_id   INT NOT NULL UNIQUE,
    employee_name VARCHAR(100),
    department    VARCHAR(50),
    hire_date     DATE
);

CREATE TABLE dwh.dim_ship_method (
    ship_method_key INT IDENTITY(1,1) PRIMARY KEY,
    ship_method_id  INT NOT NULL UNIQUE,
    method_name     VARCHAR(50),
    carrier         VARCHAR(50),
    avg_days        INT
);

-- header-grain fact: one row per order
CREATE TABLE dwh.fact_orders (
    order_key       BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id        INT NOT NULL,
    order_date_key  INT NOT NULL REFERENCES dwh.dim_date(date_key),
    ship_date_key   INT NULL REFERENCES dwh.dim_date(date_key),   -- NULL if not shipped yet
    customer_key    INT NOT NULL REFERENCES dwh.dim_customer(customer_key),
    employee_key    INT NULL REFERENCES dwh.dim_employee(employee_key),
    ship_method_key INT NOT NULL REFERENCES dwh.dim_ship_method(ship_method_key),
    order_status    VARCHAR(20)
);

-- line-grain fact: one row per product per order (finer grain than fact_orders)
CREATE TABLE dwh.fact_order_items (
    order_item_key  BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_item_id   INT NOT NULL,
    order_key       BIGINT NOT NULL REFERENCES dwh.fact_orders(order_key),
    product_key     INT NOT NULL REFERENCES dwh.dim_product(product_key),
    quantity        INT,
    unit_price      DECIMAL(10,2),
    discount_pct    DECIMAL(5,2),
    gross_amount    AS (CAST(quantity AS DECIMAL(10,2)) * unit_price) PERSISTED,
    net_amount      AS (CAST(quantity AS DECIMAL(10,2)) * unit_price
                         * (1 - discount_pct / 100.0)) PERSISTED
);
GO

-- ============================================================================
-- SECTION 4: ETL — clean + load staging -> dwh (T-SQL version)
-- (or treat staging.*/dwh.* as Informatica source/target instead of running this)
-- ============================================================================

CREATE OR ALTER PROCEDURE dwh.usp_etl_load_dim_date
    @start_date DATE = '2023-01-01', @end_date DATE = '2026-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE dwh.dim_date;
    ;WITH dates AS (
        SELECT @start_date AS d
        UNION ALL SELECT DATEADD(DAY,1,d) FROM dates WHERE d < @end_date
    )
    INSERT INTO dwh.dim_date
    SELECT CONVERT(INT, CONVERT(VARCHAR(8), d, 112)), d, DATEPART(WEEKDAY,d),
           DATENAME(WEEKDAY,d), DAY(d), MONTH(d), DATENAME(MONTH,d),
           DATEPART(QUARTER,d), YEAR(d),
           CASE WHEN DATENAME(WEEKDAY,d) IN ('Friday','Saturday') THEN 1 ELSE 0 END
    FROM dates OPTION (MAXRECURSION 0);
END
GO

CREATE OR ALTER PROCEDURE dwh.usp_etl_load_dim_customer
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('tempdb..#cc') IS NOT NULL DROP TABLE #cc;

    -- split "full_name" into first/last, normalize loyalty_tier casing,
    -- parse mixed-format signup_date, dedup on customer_id
    SELECT *
    INTO #cc
    FROM (
        SELECT
            customer_id,
            LTRIM(RTRIM(LEFT(full_name, CHARINDEX(' ', full_name + ' ') - 1)))            AS first_name_raw,
            LTRIM(RTRIM(SUBSTRING(full_name, CHARINDEX(' ', full_name + ' ') + 1, 60)))   AS last_name_raw,
            NULLIF(LTRIM(RTRIM(email)), '') AS email,
            country,
            COALESCE(TRY_CONVERT(DATE, signup_date, 23),
                     TRY_CONVERT(DATE, signup_date, 103),
                     TRY_CONVERT(DATE, signup_date, 101)) AS signup_date,
            UPPER(LEFT(LTRIM(RTRIM(loyalty_tier)),1)) + LOWER(SUBSTRING(LTRIM(RTRIM(loyalty_tier)),2,20)) AS loyalty_tier,
            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY load_ts DESC) AS rn
        FROM staging.raw_customers
    ) x WHERE rn = 1;

    UPDATE d SET d.valid_to = SYSDATETIME(), d.is_current = 0
    FROM dwh.dim_customer d
    JOIN #cc c ON c.customer_id = d.customer_id
    WHERE d.is_current = 1
      AND (ISNULL(d.loyalty_tier,'') <> ISNULL(c.loyalty_tier,'')
        OR ISNULL(d.email,'') <> ISNULL(c.email,''));

    INSERT INTO dwh.dim_customer (customer_id, first_name, last_name, email, country,
                                   signup_date, loyalty_tier, valid_from, valid_to, is_current)
    SELECT c.customer_id,
           UPPER(LEFT(c.first_name_raw,1)) + LOWER(SUBSTRING(c.first_name_raw,2,49)),
           UPPER(LEFT(c.last_name_raw,1)) + LOWER(SUBSTRING(c.last_name_raw,2,49)),
           c.email, c.country, c.signup_date, c.loyalty_tier, SYSDATETIME(), NULL, 1
    FROM #cc c
    LEFT JOIN dwh.dim_customer d ON d.customer_id = c.customer_id AND d.is_current = 1
    WHERE d.customer_key IS NULL;
END
GO

CREATE OR ALTER PROCEDURE dwh.usp_etl_load_dim_product
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH clean AS (
        SELECT product_id, LTRIM(RTRIM(product_name)) AS product_name, category,
               TRY_CONVERT(DECIMAL(10,2), REPLACE(list_price,'$','')) AS list_price,
               CASE WHEN LOWER(LTRIM(RTRIM(is_active))) IN ('y','yes','1') THEN 1 ELSE 0 END AS is_active,
               ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY load_ts DESC) AS rn
        FROM staging.raw_products
    )
    MERGE dwh.dim_product AS tgt
    USING (SELECT * FROM clean WHERE rn = 1) AS src ON tgt.product_id = src.product_id
    WHEN MATCHED THEN UPDATE SET product_name = src.product_name, category = src.category,
                                  list_price = src.list_price, is_active = src.is_active
    WHEN NOT MATCHED THEN INSERT (product_id, product_name, category, list_price, is_active)
                          VALUES (src.product_id, src.product_name, src.category, src.list_price, src.is_active);
END
GO

CREATE OR ALTER PROCEDURE dwh.usp_etl_load_dim_employee
AS
BEGIN
    SET NOCOUNT ON;
    MERGE dwh.dim_employee AS tgt
    USING (SELECT employee_id, LTRIM(RTRIM(employee_name)) AS employee_name, department,
                  TRY_CONVERT(DATE, hire_date, 23) AS hire_date FROM staging.raw_employees) AS src
        ON tgt.employee_id = src.employee_id
    WHEN MATCHED THEN UPDATE SET employee_name = src.employee_name, department = src.department, hire_date = src.hire_date
    WHEN NOT MATCHED THEN INSERT (employee_id, employee_name, department, hire_date)
                          VALUES (src.employee_id, src.employee_name, src.department, src.hire_date);
END
GO

CREATE OR ALTER PROCEDURE dwh.usp_etl_load_dim_ship_method
AS
BEGIN
    SET NOCOUNT ON;
    MERGE dwh.dim_ship_method AS tgt
    USING (SELECT ship_method_id, method_name, carrier, TRY_CONVERT(INT, avg_days) AS avg_days
           FROM staging.raw_ship_methods) AS src
        ON tgt.ship_method_id = src.ship_method_id
    WHEN MATCHED THEN UPDATE SET method_name = src.method_name, carrier = src.carrier, avg_days = src.avg_days
    WHEN NOT MATCHED THEN INSERT (ship_method_id, method_name, carrier, avg_days)
                          VALUES (src.ship_method_id, src.method_name, src.carrier, src.avg_days);
END
GO

CREATE OR ALTER PROCEDURE dwh.usp_etl_load_fact_orders
AS
BEGIN
    SET NOCOUNT ON;
    TRUNCATE TABLE dwh.fact_order_items;  -- child depends on fact_orders, clear first
    TRUNCATE TABLE dwh.fact_orders;

    ;WITH clean AS (
        SELECT
            o.order_id,
            TRY_CONVERT(DATE, o.order_date, 23) AS order_date,
            TRY_CONVERT(DATE, o.ship_date, 23)  AS ship_date,
            o.customer_id, o.employee_id, o.ship_method_id, o.order_status,
            ROW_NUMBER() OVER (PARTITION BY o.order_id ORDER BY o.load_ts DESC) AS rn
        FROM staging.raw_orders o
    )
    INSERT INTO dwh.fact_orders (order_id, order_date_key, ship_date_key, customer_key,
                                  employee_key, ship_method_key, order_status)
    SELECT
        c.order_id,
        CONVERT(INT, CONVERT(VARCHAR(8), c.order_date, 112)),
        CASE WHEN c.ship_date IS NULL THEN NULL
             ELSE CONVERT(INT, CONVERT(VARCHAR(8), c.ship_date, 112)) END,
        dc.customer_key,
        de.employee_key,
        dsm.ship_method_key,
        c.order_status
    FROM clean c
    JOIN dwh.dim_customer dc ON dc.customer_id = c.customer_id AND dc.is_current = 1
    LEFT JOIN dwh.dim_employee de ON de.employee_id = c.employee_id
    JOIN dwh.dim_ship_method dsm ON dsm.ship_method_id = c.ship_method_id
    WHERE c.rn = 1 AND c.order_date IS NOT NULL;
END
GO

CREATE OR ALTER PROCEDURE dwh.usp_etl_load_fact_order_items
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH clean AS (
        SELECT
            oi.order_item_id, oi.order_id, oi.product_id,
            TRY_CONVERT(INT, oi.quantity) AS quantity,
            TRY_CONVERT(DECIMAL(10,2), REPLACE(oi.unit_price,'$','')) AS unit_price,
            TRY_CONVERT(DECIMAL(5,2), REPLACE(oi.discount_pct,'%','')) AS discount_pct,
            ROW_NUMBER() OVER (PARTITION BY oi.order_item_id ORDER BY oi.load_ts DESC) AS rn
        FROM staging.raw_order_items oi
    )
    INSERT INTO dwh.fact_order_items (order_item_id, order_key, product_key, quantity, unit_price, discount_pct)
    SELECT c.order_item_id, fo.order_key, dp.product_key, c.quantity, c.unit_price, ISNULL(c.discount_pct,0)
    FROM clean c
    JOIN dwh.fact_orders fo ON fo.order_id = c.order_id
    JOIN dwh.dim_product dp ON dp.product_id = c.product_id
    WHERE c.rn = 1 AND c.quantity IS NOT NULL AND c.unit_price IS NOT NULL;
END
GO

CREATE OR ALTER PROCEDURE dwh.usp_etl_run_all
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dwh.usp_etl_load_dim_date;
    EXEC dwh.usp_etl_load_dim_customer;
    EXEC dwh.usp_etl_load_dim_product;
    EXEC dwh.usp_etl_load_dim_employee;
    EXEC dwh.usp_etl_load_dim_ship_method;
    EXEC dwh.usp_etl_load_fact_orders;       -- must run before fact_order_items (FK dependency)
    EXEC dwh.usp_etl_load_fact_order_items;
END
GO

EXEC dwh.usp_etl_run_all;
GO

SELECT 'dim_date' t, COUNT(*) rows_ FROM dwh.dim_date
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dwh.dim_customer
UNION ALL SELECT 'dim_product', COUNT(*) FROM dwh.dim_product
UNION ALL SELECT 'dim_employee', COUNT(*) FROM dwh.dim_employee
UNION ALL SELECT 'dim_ship_method', COUNT(*) FROM dwh.dim_ship_method
UNION ALL SELECT 'fact_orders', COUNT(*) FROM dwh.fact_orders
UNION ALL SELECT 'fact_order_items', COUNT(*) FROM dwh.fact_order_items;
GO

CREATE INDEX ix_fact_orders_date       ON dwh.fact_orders(order_date_key);
CREATE INDEX ix_fact_orders_customer   ON dwh.fact_orders(customer_key);
CREATE INDEX ix_fact_order_items_order ON dwh.fact_order_items(order_key);
CREATE INDEX ix_fact_order_items_prod  ON dwh.fact_order_items(product_key);
GO

-- ============================================================================
-- SECTION 5: NEW COMPLEX QUERY PRACTICE LIBRARY (different from the retail set)
-- ============================================================================

-- 5.1 Header + line join: net revenue per order status, completed orders only
SELECT fo.order_status, COUNT(DISTINCT fo.order_key) AS num_orders,
       SUM(foi.net_amount) AS total_net_revenue,
       CAST(SUM(foi.net_amount) / NULLIF(COUNT(DISTINCT fo.order_key),0) AS DECIMAL(10,2)) AS avg_order_value
FROM dwh.fact_orders fo
JOIN dwh.fact_order_items foi ON foi.order_key = fo.order_key
GROUP BY fo.order_status
ORDER BY total_net_revenue DESC;
GO

-- 5.2 Market-basket style: products most frequently bought together
-- (self-join order_items on order_key, dedup pairs)
SELECT dp1.product_name AS product_a, dp2.product_name AS product_b, COUNT(*) AS times_bought_together
FROM dwh.fact_order_items a
JOIN dwh.fact_order_items b ON a.order_key = b.order_key AND a.product_key < b.product_key
JOIN dwh.dim_product dp1 ON dp1.product_key = a.product_key
JOIN dwh.dim_product dp2 ON dp2.product_key = b.product_key
GROUP BY dp1.product_name, dp2.product_name
HAVING COUNT(*) >= 5
ORDER BY times_bought_together DESC;
GO

-- 5.3 Employee performance ranking: revenue handled + rank within department
;WITH emp_rev AS (
    SELECT de.employee_key, de.employee_name, de.department, SUM(foi.net_amount) AS revenue
    FROM dwh.fact_orders fo
    JOIN dwh.fact_order_items foi ON foi.order_key = fo.order_key
    JOIN dwh.dim_employee de ON de.employee_key = fo.employee_key
    WHERE fo.order_status = 'Completed'
    GROUP BY de.employee_key, de.employee_name, de.department
)
SELECT *, RANK() OVER (PARTITION BY department ORDER BY revenue DESC) AS dept_rank
FROM emp_rev
ORDER BY department, dept_rank;
GO

-- 5.4 Shipping SLA analysis: actual vs. promised avg_days per method
SELECT dsm.method_name, dsm.carrier, dsm.avg_days AS promised_days,
       AVG(DATEDIFF(DAY, od.full_date, sd.full_date)) AS actual_avg_days,
       SUM(CASE WHEN DATEDIFF(DAY, od.full_date, sd.full_date) > dsm.avg_days THEN 1 ELSE 0 END) AS late_shipments,
       COUNT(*) AS shipped_orders
FROM dwh.fact_orders fo
JOIN dwh.dim_ship_method dsm ON dsm.ship_method_key = fo.ship_method_key
JOIN dwh.dim_date od ON od.date_key = fo.order_date_key
JOIN dwh.dim_date sd ON sd.date_key = fo.ship_date_key
WHERE fo.ship_date_key IS NOT NULL
GROUP BY dsm.method_name, dsm.carrier, dsm.avg_days
ORDER BY late_shipments DESC;
GO

-- 5.5 Monthly cohort retention: % of each signup-month cohort still ordering N months later
;WITH cohort AS (
    SELECT dc.customer_key,
           DATEFROMPARTS(YEAR(dc.signup_date), MONTH(dc.signup_date), 1) AS cohort_month
    FROM dwh.dim_customer dc
    WHERE dc.is_current = 1
),
activity AS (
    SELECT fo.customer_key, DATEFROMPARTS(dd.year, dd.month_number, 1) AS activity_month
    FROM dwh.fact_orders fo
    JOIN dwh.dim_date dd ON dd.date_key = fo.order_date_key
    GROUP BY fo.customer_key, DATEFROMPARTS(dd.year, dd.month_number, 1)
)
SELECT
    c.cohort_month,
    DATEDIFF(MONTH, c.cohort_month, a.activity_month) AS months_since_signup,
    COUNT(DISTINCT a.customer_key) AS active_customers
FROM cohort c
JOIN activity a ON a.customer_key = c.customer_key AND a.activity_month >= c.cohort_month
GROUP BY c.cohort_month, DATEDIFF(MONTH, c.cohort_month, a.activity_month)
ORDER BY c.cohort_month, months_since_signup;
GO

-- 5.6 Category rollup with subtotals (GROUPING SETS — snowflake-style rollup practice)
SELECT
    dp.category,
    dd.year,
    SUM(foi.net_amount) AS net_revenue,
    GROUPING(dp.category) AS is_category_subtotal,
    GROUPING(dd.year) AS is_year_subtotal
FROM dwh.fact_order_items foi
JOIN dwh.dim_product dp ON dp.product_key = foi.product_key
JOIN dwh.fact_orders fo ON fo.order_key = foi.order_key
JOIN dwh.dim_date dd ON dd.date_key = fo.order_date_key
GROUP BY GROUPING SETS ((dp.category, dd.year), (dp.category), ())
ORDER BY dp.category, dd.year;
GO

-- 5.7 Loyalty tier vs. average order value (does Gold actually spend more?)
SELECT dc.loyalty_tier,
       COUNT(DISTINCT fo.order_key) AS orders,
       CAST(SUM(foi.net_amount) / NULLIF(COUNT(DISTINCT fo.order_key),0) AS DECIMAL(10,2)) AS avg_order_value
FROM dwh.fact_orders fo
JOIN dwh.fact_order_items foi ON foi.order_key = fo.order_key
JOIN dwh.dim_customer dc ON dc.customer_key = fo.customer_key
WHERE fo.order_status = 'Completed'
GROUP BY dc.loyalty_tier
ORDER BY avg_order_value DESC;
GO

-- 5.8 First N vs. Nth+ order value per customer (window function ROW_NUMBER + CASE)
;WITH ordered AS (
    SELECT fo.customer_key, fo.order_key, dd.full_date,
           SUM(foi.net_amount) OVER (PARTITION BY fo.order_key) AS order_value,
           ROW_NUMBER() OVER (PARTITION BY fo.customer_key ORDER BY dd.full_date) AS order_seq
    FROM dwh.fact_orders fo
    JOIN dwh.fact_order_items foi ON foi.order_key = fo.order_key
    JOIN dwh.dim_date dd ON dd.date_key = fo.order_date_key
)
SELECT
    CASE WHEN order_seq = 1 THEN 'First Order' ELSE 'Repeat Order' END AS order_type,
    COUNT(DISTINCT order_key) AS num_orders,
    AVG(order_value) AS avg_order_value
FROM ordered
GROUP BY CASE WHEN order_seq = 1 THEN 'First Order' ELSE 'Repeat Order' END;
GO

/* ============================================================================
   NEXT STEPS
   - Practice Slowly Changing Dimension Type 2 further by re-running the
     customer generator with different loyalty_tier values and re-executing
     dwh.usp_etl_load_dim_customer — inspect how history rows accumulate.
   - Rebuild fact_order_items grain up to fact_orders using a snapshot
     aggregation and compare to a stored "order total" for reconciliation practice.
   - Port SECTION 4 into Informatica: staging.raw_orders + staging.raw_order_items
     as two source qualifiers, a Joiner, Expression transformations for the
     text cleaning, and an Update Strategy for the dim_customer SCD2 logic.
   ============================================================================ */