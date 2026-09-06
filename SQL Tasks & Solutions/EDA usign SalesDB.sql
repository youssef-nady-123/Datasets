/*
=============================================================================
script.sql  -  Exploratory Data Analysis (EDA) Project
=============================================================================
Database : SalesDB
Tables   : Sales.Customers, Sales.Employees, Sales.Products,
           Sales.Orders, Sales.OrdersArchive
Dialect  : SQL Server (T-SQL)

Purpose:
  A structured, end-to-end EDA walkthrough of SalesDB - the same kind of
  exploration a data analyst/engineer runs before building any dashboard
  or data model. Each section builds on the last.

Table of Contents:
  01. Database Exploration        - what tables/columns exist
  02. Dimensions Exploration       - distinct values in categorical fields
  03. Date Exploration             - time boundaries and ranges
  04. Measures Exploration         - core business metrics (the "big numbers")
  05. Magnitude Analysis           - measures broken down by dimension
  06. Ranking Analysis             - top / bottom N performers
  07. Change-Over-Time Analysis    - trends by year/month
  08. Cumulative Analysis          - running totals & moving averages
  09. Performance Analysis         - year-over-year growth, vs. average
  10. Part-to-Whole Analysis       - % contribution of each segment
  11. Data Segmentation            - grouping customers/products into bands
  12. Data Quality Checks          - nulls, duplicates, orphans, outliers
  13. Final Reports (Views)        - reusable customer & product summaries
=============================================================================
*/

USE SalesDB;
GO


/*
=============================================================================
01. DATABASE EXPLORATION
    Goal: understand what we're working with before writing a single
    business query - tables, columns, data types.
=============================================================================
*/

-- All tables in the database
SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO

-- All columns, with data types, for every table in the Sales schema
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Sales'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
GO

-- Row counts per table (quick sanity check on load size)
SELECT 'Customers' AS TableName, COUNT(*) AS RowCount FROM Sales.Customers
UNION ALL SELECT 'Employees', COUNT(*) FROM Sales.Employees
UNION ALL SELECT 'Products', COUNT(*) FROM Sales.Products
UNION ALL SELECT 'Orders', COUNT(*) FROM Sales.Orders
UNION ALL SELECT 'OrdersArchive', COUNT(*) FROM Sales.OrdersArchive;
GO


/*
=============================================================================
02. DIMENSIONS EXPLORATION
    Goal: identify the unique values inside the categorical (dimension)
    columns - these become filters, slicers, and GROUP BY candidates.
=============================================================================
*/

-- Which countries do customers come from?
SELECT DISTINCT Country
FROM Sales.Customers
ORDER BY Country;
GO

-- Which departments exist, and how many employees are in each?
SELECT Department, COUNT(*) AS EmployeeCount
FROM Sales.Employees
GROUP BY Department
ORDER BY EmployeeCount DESC;
GO

-- Which product categories exist, and how many products fall into each?
SELECT Category, COUNT(*) AS ProductCount
FROM Sales.Products
GROUP BY Category
ORDER BY ProductCount DESC;
GO

-- Which order statuses exist in the pipeline, and their frequency?
SELECT OrderStatus, COUNT(*) AS OrderCount
FROM Sales.Orders
GROUP BY OrderStatus
ORDER BY OrderCount DESC;
GO

-- Combine all key dimensions into a single "at a glance" summary
SELECT 'Country' AS Dimension, Country AS Value, COUNT(*) AS Frequency
FROM Sales.Customers GROUP BY Country
UNION ALL
SELECT 'Department', Department, COUNT(*)
FROM Sales.Employees GROUP BY Department
UNION ALL
SELECT 'Category', Category, COUNT(*)
FROM Sales.Products GROUP BY Category
UNION ALL
SELECT 'OrderStatus', OrderStatus, COUNT(*)
FROM Sales.Orders GROUP BY OrderStatus
ORDER BY Dimension, Frequency DESC;
GO


/*
=============================================================================
03. DATE EXPLORATION
    Goal: understand the time boundaries of the dataset - how far back
    does it go, how far forward, and how wide is the reporting window?
=============================================================================
*/

-- Earliest and latest order date, and the span in years
SELECT
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate,
    DATEDIFF(MONTH, MIN(OrderDate), MAX(OrderDate)) AS RangeInMonths,
    DATEDIFF(YEAR, MIN(OrderDate), MAX(OrderDate)) AS RangeInYears
FROM Sales.Orders;
GO

-- Same, for the archive table (older historical data)
SELECT
    MIN(OrderDate) AS FirstArchivedOrder,
    MAX(OrderDate) AS LastArchivedOrder
FROM Sales.OrdersArchive;
GO

-- Oldest and youngest employee (age range of the workforce)
SELECT
    MIN(BirthDate) AS OldestBirthDate,
    MAX(BirthDate) AS YoungestBirthDate,
    DATEDIFF(YEAR, MIN(BirthDate), GETDATE()) AS OldestEmployeeAge,
    DATEDIFF(YEAR, MAX(BirthDate), GETDATE()) AS YoungestEmployeeAge
FROM Sales.Employees;
GO

-- How many orders fall in each calendar year? (spot data-entry anomalies too)
SELECT YEAR(OrderDate) AS OrderYear, COUNT(*) AS OrderCount
FROM Sales.Orders
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;
GO


/*
=============================================================================
04. MEASURES EXPLORATION
    Goal: calculate the core, single-number business metrics - the
    "headline KPIs" that would sit at the top of a dashboard.
=============================================================================
*/

-- Total revenue (sum of all order Sales)
SELECT SUM(Sales) AS TotalRevenue FROM Sales.Orders;
GO

-- Total number of orders placed
SELECT COUNT(OrderID) AS TotalOrders FROM Sales.Orders;
GO

-- Total quantity of items sold
SELECT SUM(Quantity) AS TotalQuantitySold FROM Sales.Orders;
GO

-- Average order value
SELECT AVG(Sales) AS AvgOrderValue FROM Sales.Orders;
GO

-- Total number of customers, and how many have placed at least one order
SELECT
    (SELECT COUNT(*) FROM Sales.Customers) AS TotalCustomers,
    (SELECT COUNT(DISTINCT CustomerID) FROM Sales.Orders) AS CustomersWithOrders;
GO

-- Total number of products, and how many have actually been sold
SELECT
    (SELECT COUNT(*) FROM Sales.Products) AS TotalProducts,
    (SELECT COUNT(DISTINCT ProductID) FROM Sales.Orders) AS ProductsSold;
GO

-- One consolidated "KPI report" combining all headline measures
SELECT 'Total Revenue' AS Metric, CAST(SUM(Sales) AS VARCHAR(20)) AS Value FROM Sales.Orders
UNION ALL
SELECT 'Total Orders', CAST(COUNT(*) AS VARCHAR(20)) FROM Sales.Orders
UNION ALL
SELECT 'Total Quantity Sold', CAST(SUM(Quantity) AS VARCHAR(20)) FROM Sales.Orders
UNION ALL
SELECT 'Avg Order Value', CAST(ROUND(AVG(CAST(Sales AS FLOAT)), 2) AS VARCHAR(20)) FROM Sales.Orders
UNION ALL
SELECT 'Total Customers', CAST(COUNT(*) AS VARCHAR(20)) FROM Sales.Customers
UNION ALL
SELECT 'Total Products', CAST(COUNT(*) AS VARCHAR(20)) FROM Sales.Products
UNION ALL
SELECT 'Total Employees', CAST(COUNT(*) AS VARCHAR(20)) FROM Sales.Employees;
GO


/*
=============================================================================
05. MAGNITUDE ANALYSIS
    Goal: break the headline measures down by a dimension to see where
    the business volume actually concentrates.
=============================================================================
*/

-- Revenue by customer country
SELECT c.Country, SUM(o.Sales) AS TotalRevenue, COUNT(o.OrderID) AS OrderCount
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY TotalRevenue DESC;
GO

-- Revenue by product category
SELECT p.Category, SUM(o.Sales) AS TotalRevenue, SUM(o.Quantity) AS TotalQuantity
FROM Sales.Orders o
INNER JOIN Sales.Products p ON o.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY TotalRevenue DESC;
GO

-- Revenue by department (via the salesperson who closed the order)
SELECT e.Department, SUM(o.Sales) AS TotalRevenue, COUNT(o.OrderID) AS OrderCount
FROM Sales.Orders o
INNER JOIN Sales.Employees e ON o.SalesPersonID = e.EmployeeID
GROUP BY e.Department
ORDER BY TotalRevenue DESC;
GO

-- Employee headcount and average salary by department and gender
SELECT Department, Gender, COUNT(*) AS Headcount, AVG(Salary) AS AvgSalary
FROM Sales.Employees
GROUP BY Department, Gender
ORDER BY Department, Gender;
GO

-- Order volume by OrderStatus (where is the pipeline getting stuck?)
SELECT OrderStatus, COUNT(*) AS OrderCount, SUM(Sales) AS TotalValue
FROM Sales.Orders
GROUP BY OrderStatus
ORDER BY OrderCount DESC;
GO


/*
=============================================================================
06. RANKING ANALYSIS
    Goal: find the top and bottom performers - the customers, products,
    and salespeople driving (or dragging down) the business.
=============================================================================
*/

-- Top 10 customers by total spend
SELECT TOP 10 c.CustomerID, c.FirstName, c.LastName, c.Country,
       SUM(o.Sales) AS TotalSpend
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Country
ORDER BY TotalSpend DESC;
GO

-- Bottom 5 customers by total spend (among those who ordered at all)
SELECT TOP 5 c.CustomerID, c.FirstName, c.LastName, SUM(o.Sales) AS TotalSpend
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpend ASC;
GO

-- Top 5 best-selling products by revenue
SELECT TOP 5 p.ProductID, p.Product, p.Category, SUM(o.Sales) AS TotalRevenue
FROM Sales.Orders o
INNER JOIN Sales.Products p ON o.ProductID = p.ProductID
GROUP BY p.ProductID, p.Product, p.Category
ORDER BY TotalRevenue DESC;
GO

-- Top 5 salespeople by revenue generated, using RANK() for ties
SELECT * FROM (
    SELECT e.EmployeeID, e.FirstName + ' ' + e.LastName AS SalesPerson,
           SUM(o.Sales) AS TotalRevenue,
           RANK() OVER (ORDER BY SUM(o.Sales) DESC) AS SalesRank
    FROM Sales.Orders o
    INNER JOIN Sales.Employees e ON o.SalesPersonID = e.EmployeeID
    GROUP BY e.EmployeeID, e.FirstName, e.LastName
) ranked
WHERE SalesRank <= 5;
GO

-- Highest-paid employee per department (window function ranking)
SELECT EmployeeID, FirstName, LastName, Department, Salary
FROM (
    SELECT *, RANK() OVER (PARTITION BY Department ORDER BY Salary DESC) AS rnk
    FROM Sales.Employees
) r
WHERE rnk = 1;
GO


/*
=============================================================================
07. CHANGE-OVER-TIME ANALYSIS
    Goal: track how key measures evolve month by month and year by year
    - the foundation of any trend chart.
=============================================================================
*/

-- Monthly revenue and order count trend
SELECT
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonthNum,
    DATENAME(MONTH, OrderDate) AS OrderMonthName,
    COUNT(OrderID) AS OrderCount,
    SUM(Sales) AS TotalRevenue
FROM Sales.Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY OrderYear, OrderMonthNum;
GO

-- Yearly revenue trend with year-over-year change
WITH YearlyRevenue AS (
    SELECT YEAR(OrderDate) AS OrderYear, SUM(Sales) AS TotalRevenue
    FROM Sales.Orders
    GROUP BY YEAR(OrderDate)
)
SELECT OrderYear, TotalRevenue,
       LAG(TotalRevenue) OVER (ORDER BY OrderYear) AS PrevYearRevenue,
       TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY OrderYear) AS YoY_Change
FROM YearlyRevenue
ORDER BY OrderYear;
GO

-- New customers acquired per month (first order date = acquisition date)
WITH FirstOrderPerCustomer AS (
    SELECT CustomerID, MIN(OrderDate) AS FirstOrderDate
    FROM Sales.Orders
    GROUP BY CustomerID
)
SELECT YEAR(FirstOrderDate) AS AcqYear, MONTH(FirstOrderDate) AS AcqMonth,
       COUNT(*) AS NewCustomers
FROM FirstOrderPerCustomer
GROUP BY YEAR(FirstOrderDate), MONTH(FirstOrderDate)
ORDER BY AcqYear, AcqMonth;
GO


/*
=============================================================================
08. CUMULATIVE ANALYSIS
    Goal: track running totals and moving averages - useful for growth
    charts and smoothing out noisy month-to-month swings.
=============================================================================
*/

-- Running total of revenue over time (monthly)
WITH MonthlyRevenue AS (
    SELECT
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
        SUM(Sales) AS MonthlyRevenue
    FROM Sales.Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT OrderMonth, MonthlyRevenue,
       SUM(MonthlyRevenue) OVER (ORDER BY OrderMonth
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotalRevenue,
       AVG(MonthlyRevenue) OVER (ORDER BY OrderMonth
                                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MovingAvg3Month
FROM MonthlyRevenue
ORDER BY OrderMonth;
GO

-- Running total of orders per customer, in chronological order
SELECT OrderID, CustomerID, OrderDate, Sales,
       SUM(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate, OrderID
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeCustomerSpend
FROM Sales.Orders
ORDER BY CustomerID, OrderDate;
GO


/*
=============================================================================
09. PERFORMANCE ANALYSIS
    Goal: compare each entity's performance against a benchmark - its own
    history, or the average of its peer group.
=============================================================================
*/

-- Each product's revenue vs. the average revenue across all products
WITH ProductRevenue AS (
    SELECT p.ProductID, p.Product, p.Category, SUM(o.Sales) AS TotalRevenue
    FROM Sales.Orders o
    INNER JOIN Sales.Products p ON o.ProductID = p.ProductID
    GROUP BY p.ProductID, p.Product, p.Category
)
SELECT ProductID, Product, Category, TotalRevenue,
       AVG(TotalRevenue) OVER () AS AvgProductRevenue,
       TotalRevenue - AVG(TotalRevenue) OVER () AS DiffFromAvg,
       CASE
           WHEN TotalRevenue > AVG(TotalRevenue) OVER () THEN 'Above Average'
           WHEN TotalRevenue < AVG(TotalRevenue) OVER () THEN 'Below Average'
           ELSE 'At Average'
       END AS Performance
FROM ProductRevenue
ORDER BY TotalRevenue DESC;
GO

-- Each salesperson's revenue vs. their department's average
WITH SalespersonRevenue AS (
    SELECT e.EmployeeID, e.FirstName + ' ' + e.LastName AS SalesPerson,
           e.Department, SUM(o.Sales) AS TotalRevenue
    FROM Sales.Orders o
    INNER JOIN Sales.Employees e ON o.SalesPersonID = e.EmployeeID
    GROUP BY e.EmployeeID, e.FirstName, e.LastName, e.Department
)
SELECT EmployeeID, SalesPerson, Department, TotalRevenue,
       AVG(TotalRevenue) OVER (PARTITION BY Department) AS DeptAvgRevenue,
       TotalRevenue - AVG(TotalRevenue) OVER (PARTITION BY Department) AS DiffFromDeptAvg
FROM SalespersonRevenue
ORDER BY Department, TotalRevenue DESC;
GO

-- Year-over-year performance per product category
WITH CategoryYearRevenue AS (
    SELECT p.Category, YEAR(o.OrderDate) AS OrderYear, SUM(o.Sales) AS TotalRevenue
    FROM Sales.Orders o
    INNER JOIN Sales.Products p ON o.ProductID = p.ProductID
    GROUP BY p.Category, YEAR(o.OrderDate)
)
SELECT Category, OrderYear, TotalRevenue,
       LAG(TotalRevenue) OVER (PARTITION BY Category ORDER BY OrderYear) AS PrevYearRevenue,
       TotalRevenue - LAG(TotalRevenue) OVER (PARTITION BY Category ORDER BY OrderYear) AS YoY_Change
FROM CategoryYearRevenue
ORDER BY Category, OrderYear;
GO


/*
=============================================================================
10. PART-TO-WHOLE ANALYSIS
    Goal: express each segment as a percentage of the total - "what
    share of revenue does this category/country/product represent?"
=============================================================================
*/

-- Each category's share of total revenue
WITH CategoryRevenue AS (
    SELECT p.Category, SUM(o.Sales) AS TotalRevenue
    FROM Sales.Orders o
    INNER JOIN Sales.Products p ON o.ProductID = p.ProductID
    GROUP BY p.Category
)
SELECT Category, TotalRevenue,
       SUM(TotalRevenue) OVER () AS GrandTotal,
       CAST(TotalRevenue AS FLOAT) / SUM(TotalRevenue) OVER () * 100 AS PctOfTotal
FROM CategoryRevenue
ORDER BY PctOfTotal DESC;
GO

-- Each country's share of total customers
SELECT Country, COUNT(*) AS CustomerCount,
       CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER () * 100 AS PctOfCustomers
FROM Sales.Customers
GROUP BY Country
ORDER BY PctOfCustomers DESC;
GO

-- Each OrderStatus's share of total order volume
SELECT OrderStatus, COUNT(*) AS OrderCount,
       CAST(COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER () * 100 AS PctOfOrders
FROM Sales.Orders
GROUP BY OrderStatus
ORDER BY PctOfOrders DESC;
GO


/*
=============================================================================
11. DATA SEGMENTATION
    Goal: bucket customers and products into meaningful bands - the
    groundwork for segmentation-driven reporting (VIP tiers, price tiers).
=============================================================================
*/

-- Segment customers into spend tiers
WITH CustomerSpend AS (
    SELECT c.CustomerID, c.FirstName, c.LastName, c.Country,
           ISNULL(SUM(o.Sales), 0) AS TotalSpend
    FROM Sales.Customers c
    LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Country
)
SELECT
    CASE
        WHEN TotalSpend = 0 THEN 'No Purchases'
        WHEN TotalSpend < 500 THEN 'Low Value (< 500)'
        WHEN TotalSpend BETWEEN 500 AND 1500 THEN 'Mid Value (500-1500)'
        ELSE 'High Value (> 1500)'
    END AS SpendSegment,
    COUNT(*) AS CustomerCount,
    SUM(TotalSpend) AS SegmentRevenue
FROM CustomerSpend
GROUP BY
    CASE
        WHEN TotalSpend = 0 THEN 'No Purchases'
        WHEN TotalSpend < 500 THEN 'Low Value (< 500)'
        WHEN TotalSpend BETWEEN 500 AND 1500 THEN 'Mid Value (500-1500)'
        ELSE 'High Value (> 1500)'
    END
ORDER BY SegmentRevenue DESC;
GO

-- Segment products into price tiers
SELECT
    CASE
        WHEN Price < 100 THEN 'Budget (< 100)'
        WHEN Price BETWEEN 100 AND 300 THEN 'Mid-range (100-300)'
        ELSE 'Premium (> 300)'
    END AS PriceTier,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPriceInTier
FROM Sales.Products
GROUP BY
    CASE
        WHEN Price < 100 THEN 'Budget (< 100)'
        WHEN Price BETWEEN 100 AND 300 THEN 'Mid-range (100-300)'
        ELSE 'Premium (> 300)'
    END
ORDER BY AvgPriceInTier;
GO

-- Segment customers by recency: active in last 90 days of the dataset vs. lapsed
WITH LastOrderPerCustomer AS (
    SELECT CustomerID, MAX(OrderDate) AS LastOrderDate
    FROM Sales.Orders
    GROUP BY CustomerID
),
DatasetMax AS (
    SELECT MAX(OrderDate) AS MaxDate FROM Sales.Orders
)
SELECT
    CASE
        WHEN DATEDIFF(DAY, l.LastOrderDate, d.MaxDate) <= 90 THEN 'Active (last 90 days)'
        ELSE 'Lapsed (90+ days inactive)'
    END AS RecencySegment,
    COUNT(*) AS CustomerCount
FROM LastOrderPerCustomer l
CROSS JOIN DatasetMax d
GROUP BY
    CASE
        WHEN DATEDIFF(DAY, l.LastOrderDate, d.MaxDate) <= 90 THEN 'Active (last 90 days)'
        ELSE 'Lapsed (90+ days inactive)'
    END;
GO


/*
=============================================================================
12. DATA QUALITY CHECKS
    Goal: before trusting any of the numbers above, confirm the
    underlying data is clean - nulls, duplicates, orphans, and outliers.
=============================================================================
*/

-- Missing values in key Customers columns
SELECT
    SUM(CASE WHEN FirstName IS NULL THEN 1 ELSE 0 END) AS MissingFirstName,
    SUM(CASE WHEN LastName IS NULL THEN 1 ELSE 0 END) AS MissingLastName,
    SUM(CASE WHEN Score IS NULL THEN 1 ELSE 0 END) AS MissingScore
FROM Sales.Customers;
GO

-- Missing or blank addresses in Orders (NULL and empty-string both count)
SELECT
    SUM(CASE WHEN ShipAddress IS NULL OR ShipAddress = '' THEN 1 ELSE 0 END) AS MissingShipAddress,
    SUM(CASE WHEN BillAddress IS NULL OR BillAddress = '' THEN 1 ELSE 0 END) AS MissingBillAddress
FROM Sales.Orders;
GO

-- Duplicate CustomerID values (should be none, given the PRIMARY KEY - but
-- double-check for defensive data engineering, e.g. after a bad ETL load)
SELECT CustomerID, COUNT(*) AS Occurrences
FROM Sales.Customers
GROUP BY CustomerID
HAVING COUNT(*) > 1;
GO

-- Duplicate OrderID values inside OrdersArchive (this table has no PK,
-- so duplicates ARE expected here - worth quantifying)
SELECT OrderID, COUNT(*) AS Occurrences
FROM Sales.OrdersArchive
GROUP BY OrderID
HAVING COUNT(*) > 1
ORDER BY Occurrences DESC;
GO

-- Orders referencing a CustomerID/ProductID/SalesPersonID that doesn't exist
SELECT o.OrderID, 'Invalid CustomerID' AS Issue
FROM Sales.Orders o
LEFT JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL
UNION ALL
SELECT o.OrderID, 'Invalid ProductID'
FROM Sales.Orders o
LEFT JOIN Sales.Products p ON o.ProductID = p.ProductID
WHERE p.ProductID IS NULL
UNION ALL
SELECT o.OrderID, 'Invalid SalesPersonID'
FROM Sales.Orders o
LEFT JOIN Sales.Employees e ON o.SalesPersonID = e.EmployeeID
WHERE e.EmployeeID IS NULL;
GO

-- Orders where ShipDate is before OrderDate (impossible sequence)
SELECT OrderID, OrderDate, ShipDate
FROM Sales.Orders
WHERE ShipDate < OrderDate;
GO

-- Orders with zero Quantity but nonzero Sales, or vice versa (inconsistent)
SELECT OrderID, Quantity, Sales
FROM Sales.Orders
WHERE (Quantity = 0 AND Sales <> 0)
   OR (Quantity <> 0 AND Sales = 0);
GO

-- Outlier check: orders with unusually high Sales (more than 3x the average)
SELECT OrderID, CustomerID, Sales
FROM Sales.Orders
WHERE Sales > (SELECT AVG(Sales) * 3 FROM Sales.Orders)
ORDER BY Sales DESC;
GO


/*
=============================================================================
13. FINAL REPORTS (VIEWS)
    Goal: package the most useful EDA findings into two reusable views -
    a Customer Report and a Product Report - so downstream dashboards
    and stakeholders don't have to re-derive this logic every time.
=============================================================================
*/

-- ---------------------------------------------------------------------------
-- Sales.vw_CustomerReport
-- One row per customer: identity, order behavior, spend, and segment.
-- ---------------------------------------------------------------------------
CREATE OR ALTER VIEW Sales.vw_CustomerReport AS
WITH CustomerOrders AS (
    SELECT
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        c.Country,
        c.Score,
        COUNT(o.OrderID) AS TotalOrders,
        ISNULL(SUM(o.Sales), 0) AS TotalSpend,
        MIN(o.OrderDate) AS FirstOrderDate,
        MAX(o.OrderDate) AS LastOrderDate
    FROM Sales.Customers c
    LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Country, c.Score
)
SELECT
    CustomerID,
    CustomerName,
    Country,
    Score,
    TotalOrders,
    TotalSpend,
    CASE WHEN TotalOrders = 0 THEN NULL
         ELSE TotalSpend / TotalOrders END AS AvgOrderValue,
    FirstOrderDate,
    LastOrderDate,
    CASE
        WHEN TotalSpend = 0 THEN 'No Purchases'
        WHEN TotalSpend < 500 THEN 'Low Value'
        WHEN TotalSpend BETWEEN 500 AND 1500 THEN 'Mid Value'
        ELSE 'High Value'
    END AS SpendSegment
FROM CustomerOrders;
GO

SELECT * FROM Sales.vw_CustomerReport ORDER BY TotalSpend DESC;
GO

-- ---------------------------------------------------------------------------
-- Sales.vw_ProductReport
-- One row per product: identity, sales volume, revenue, and price tier.
-- ---------------------------------------------------------------------------
CREATE OR ALTER VIEW Sales.vw_ProductReport AS
WITH ProductOrders AS (
    SELECT
        p.ProductID,
        p.Product,
        p.Category,
        p.Price,
        COUNT(o.OrderID) AS TimesOrdered,
        ISNULL(SUM(o.Quantity), 0) AS TotalQuantitySold,
        ISNULL(SUM(o.Sales), 0) AS TotalRevenue
    FROM Sales.Products p
    LEFT JOIN Sales.Orders o ON p.ProductID = o.ProductID
    GROUP BY p.ProductID, p.Product, p.Category, p.Price
)
SELECT
    ProductID,
    Product,
    Category,
    Price,
    CASE
        WHEN Price < 100 THEN 'Budget'
        WHEN Price BETWEEN 100 AND 300 THEN 'Mid-range'
        ELSE 'Premium'
    END AS PriceTier,
    TimesOrdered,
    TotalQuantitySold,
    TotalRevenue,
    RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
FROM ProductOrders;
GO

SELECT * FROM Sales.vw_ProductReport ORDER BY RevenueRank;
GO

/*
=============================================================================
END OF EDA PROJECT
=============================================================================
*/