/*
=============================================================================
SalesDB — 20 View Practice Tasks & Solutions (T-SQL / SQL Server)
=============================================================================
Purpose:
    20 hands-on tasks covering the major VIEW types in SQL Server, all built
    against the SalesDB schema (Sales.Customers, Sales.Employees,
    Sales.Products, Sales.Orders, Sales.OrdersArchive). Each task creates a
    view and then demonstrates it with a sample SELECT against it.

Sections:
    A. Simple Views                              (Tasks 1-3)
    B. Join Views                                (Tasks 4-6)
    C. Aggregation Views                         (Tasks 7-9)
    D. Views with Window Functions / CTEs        (Tasks 10-11)
    E. Views with Subqueries                     (Tasks 12-13)
    F. Views combining Sets (UNION)              (Task 14)
    G. Updatable Views & CHECK OPTION            (Tasks 15-16)
    H. Schema-Bound & Indexed Views              (Tasks 17-18)
    I. Encrypted View & Nested View               (Tasks 19-20)

Run against the database created by init-sqlserver-salesdb.sql.
Each task: DROP VIEW IF EXISTS ... ; GO ; CREATE VIEW ... ; GO ; demo SELECT.
=============================================================================
*/

USE SalesDB;
GO


/* =============================================================================
   SECTION A — SIMPLE VIEWS
   A view over a single table: a filtered column list and/or row filter.
============================================================================= */

-- Task 1: Create a view exposing only public-safe customer info
--         (no Score column) for general use.
DROP VIEW IF EXISTS Sales.vw_CustomerDirectory;
GO
CREATE VIEW Sales.vw_CustomerDirectory AS
SELECT CustomerID, FirstName, LastName, Country
FROM Sales.Customers;
GO
SELECT * FROM Sales.vw_CustomerDirectory;
GO

-- Task 2: Create a view listing only 'Delivered' orders.
DROP VIEW IF EXISTS Sales.vw_DeliveredOrders;
GO
CREATE VIEW Sales.vw_DeliveredOrders AS
SELECT OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, Sales
FROM Sales.Orders
WHERE OrderStatus = 'Delivered';
GO
SELECT * FROM Sales.vw_DeliveredOrders;
GO

-- Task 3: Create a view listing active (non-manager-less) employees with
--         a computed FullName column.
DROP VIEW IF EXISTS Sales.vw_EmployeeDirectory;
GO
CREATE VIEW Sales.vw_EmployeeDirectory AS
SELECT
    EmployeeID,
    FirstName + ' ' + ISNULL(LastName, '') AS FullName,
    Department,
    ManagerID
FROM Sales.Employees;
GO
SELECT * FROM Sales.vw_EmployeeDirectory;
GO


/* =============================================================================
   SECTION B — JOIN VIEWS
   Views that combine two or more tables into a single reusable result set.
============================================================================= */

-- Task 4: Create a view showing each order with its customer's name and
--         the product name/category ordered.
DROP VIEW IF EXISTS Sales.vw_OrderDetails;
GO
CREATE VIEW Sales.vw_OrderDetails AS
SELECT
    o.OrderID,
    o.OrderDate,
    c.FirstName + ' ' + ISNULL(c.LastName, '') AS CustomerName,
    p.Product,
    p.Category,
    o.Quantity,
    o.Sales
FROM Sales.Orders o
JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
JOIN Sales.Products p ON p.ProductID = o.ProductID;
GO
SELECT * FROM Sales.vw_OrderDetails;
GO

-- Task 5: Create a view showing each order with the salesperson's name and
--         their manager's name (self-join on Employees inside the view).
DROP VIEW IF EXISTS Sales.vw_OrderSalesTeam;
GO
CREATE VIEW Sales.vw_OrderSalesTeam AS
SELECT
    o.OrderID,
    o.Sales,
    emp.FirstName AS SalesPersonFirstName,
    mgr.FirstName AS ManagerFirstName
FROM Sales.Orders o
JOIN Sales.Employees emp ON emp.EmployeeID = o.SalesPersonID
LEFT JOIN Sales.Employees mgr ON mgr.EmployeeID = emp.ManagerID;
GO
SELECT * FROM Sales.vw_OrderSalesTeam;
GO

-- Task 6: Create a view combining Customers with a LEFT JOIN to Orders so
--         customers with zero orders still appear (with NULL order fields).
DROP VIEW IF EXISTS Sales.vw_CustomerOrdersLeft;
GO
CREATE VIEW Sales.vw_CustomerOrdersLeft AS
SELECT
    c.CustomerID,
    c.FirstName,
    c.Country,
    o.OrderID,
    o.Sales
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON o.CustomerID = c.CustomerID;
GO
SELECT * FROM Sales.vw_CustomerOrdersLeft;
GO


/* =============================================================================
   SECTION C — AGGREGATION VIEWS
   Views built on GROUP BY / HAVING to pre-summarize data for reporting.
============================================================================= */

-- Task 7: Create a view summarizing total Sales and order count per
--         customer.
DROP VIEW IF EXISTS Sales.vw_CustomerSalesSummary;
GO
CREATE VIEW Sales.vw_CustomerSalesSummary AS
SELECT
    CustomerID,
    COUNT(*)   AS OrderCount,
    SUM(Sales) AS TotalSales,
    AVG(Sales) AS AvgOrderValue
FROM Sales.Orders
GROUP BY CustomerID;
GO
SELECT * FROM Sales.vw_CustomerSalesSummary;
GO

-- Task 8: Create a view summarizing revenue per product category.
DROP VIEW IF EXISTS Sales.vw_CategoryRevenue;
GO
CREATE VIEW Sales.vw_CategoryRevenue AS
SELECT
    p.Category,
    SUM(o.Sales)    AS TotalRevenue,
    SUM(o.Quantity) AS TotalQuantity
FROM Sales.Orders o
JOIN Sales.Products p ON p.ProductID = o.ProductID
GROUP BY p.Category;
GO
SELECT * FROM Sales.vw_CategoryRevenue;
GO

-- Task 9: Create a view listing only salespeople whose total Sales exceed
--         100 (aggregation view with HAVING).
DROP VIEW IF EXISTS Sales.vw_TopSalesPeople;
GO
CREATE VIEW Sales.vw_TopSalesPeople AS
SELECT
    o.SalesPersonID,
    e.FirstName,
    SUM(o.Sales) AS TotalSales
FROM Sales.Orders o
JOIN Sales.Employees e ON e.EmployeeID = o.SalesPersonID
GROUP BY o.SalesPersonID, e.FirstName
HAVING SUM(o.Sales) > 100;
GO
SELECT * FROM Sales.vw_TopSalesPeople;
GO


/* =============================================================================
   SECTION D — VIEWS WITH WINDOW FUNCTIONS / CTEs
   Views can wrap analytic (window) functions and CTEs for ranked reporting.
============================================================================= */

-- Task 10: Create a view ranking products by total revenue using RANK().
DROP VIEW IF EXISTS Sales.vw_ProductRevenueRank;
GO
CREATE VIEW Sales.vw_ProductRevenueRank AS
SELECT
    p.ProductID,
    p.Product,
    SUM(o.Sales) AS Revenue,
    RANK() OVER (ORDER BY SUM(o.Sales) DESC) AS RevenueRank
FROM Sales.Products p
JOIN Sales.Orders o ON o.ProductID = p.ProductID
GROUP BY p.ProductID, p.Product;
GO
SELECT * FROM Sales.vw_ProductRevenueRank ORDER BY RevenueRank;
GO

-- Task 11: Create a view (built on a CTE) showing each customer's running
--          total of Sales ordered chronologically.
DROP VIEW IF EXISTS Sales.vw_CustomerRunningTotal;
GO
CREATE VIEW Sales.vw_CustomerRunningTotal AS
WITH OrderedSales AS (
    SELECT
        CustomerID,
        OrderID,
        OrderDate,
        Sales,
        SUM(Sales) OVER (
            PARTITION BY CustomerID
            ORDER BY OrderDate, OrderID
            ROWS UNBOUNDED PRECEDING
        ) AS RunningTotal
    FROM Sales.Orders
)
SELECT CustomerID, OrderID, OrderDate, Sales, RunningTotal
FROM OrderedSales;
GO
SELECT * FROM Sales.vw_CustomerRunningTotal ORDER BY CustomerID, OrderDate;
GO


/* =============================================================================
   SECTION E — VIEWS WITH SUBQUERIES
   Views whose SELECT list or WHERE clause relies on scalar/correlated
   subqueries.
============================================================================= */

-- Task 12: Create a view showing each customer with their order count,
--          computed via a correlated scalar subquery in the SELECT list.
DROP VIEW IF EXISTS Sales.vw_CustomerOrderCounts;
GO
CREATE VIEW Sales.vw_CustomerOrderCounts AS
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    (SELECT COUNT(*) FROM Sales.Orders o WHERE o.CustomerID = c.CustomerID) AS OrderCount
FROM Sales.Customers c;
GO
SELECT * FROM Sales.vw_CustomerOrderCounts;
GO

-- Task 13: Create a view showing only customers whose Score is above the
--          overall average Score (WHERE filter driven by a scalar
--          subquery).
DROP VIEW IF EXISTS Sales.vw_AboveAverageCustomers;
GO
CREATE VIEW Sales.vw_AboveAverageCustomers AS
SELECT CustomerID, FirstName, LastName, Score
FROM Sales.Customers
WHERE Score > (SELECT AVG(Score) FROM Sales.Customers);
GO
SELECT * FROM Sales.vw_AboveAverageCustomers;
GO


/* =============================================================================
   SECTION F — VIEWS COMBINING SETS (UNION)
   A view that merges rows from two structurally similar tables.
============================================================================= */

-- Task 14: Create a view that unions current Orders with OrdersArchive,
--          tagging each row with its source.
DROP VIEW IF EXISTS Sales.vw_AllOrdersCombined;
GO
CREATE VIEW Sales.vw_AllOrdersCombined AS
SELECT OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, Sales, 'Current' AS SourceTable
FROM Sales.Orders
UNION ALL
SELECT OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, Sales, 'Archive' AS SourceTable
FROM Sales.OrdersArchive;
GO
SELECT * FROM Sales.vw_AllOrdersCombined;
GO


/* =============================================================================
   SECTION G — UPDATABLE VIEWS & CHECK OPTION
   A view on a single base table with no aggregation is updatable; INSERTs
   and UPDATEs pass through to the underlying table. WITH CHECK OPTION
   prevents changes that would make a row fall outside the view's WHERE.
============================================================================= */

-- Task 15: Create a simple updatable view over Products (single table, no
--          aggregation) and demonstrate an UPDATE through it.
DROP VIEW IF EXISTS Sales.vw_ProductPrices;
GO
CREATE VIEW Sales.vw_ProductPrices AS
SELECT ProductID, Product, Price
FROM Sales.Products;
GO
-- Demonstration: raise the price of ProductID 101 through the view.
UPDATE Sales.vw_ProductPrices
SET Price = Price + 1
WHERE ProductID = 101;
GO
SELECT * FROM Sales.vw_ProductPrices;
GO

-- Task 16: Create a view restricted to 'Clothing' products WITH CHECK
--          OPTION, so no INSERT/UPDATE through the view can create a row
--          that falls outside the 'Clothing' filter.
DROP VIEW IF EXISTS Sales.vw_ClothingProducts;
GO
CREATE VIEW Sales.vw_ClothingProducts AS
SELECT ProductID, Product, Category, Price
FROM Sales.Products
WHERE Category = 'Clothing'
WITH CHECK OPTION;
GO
-- Demonstration: this INSERT succeeds because Category = 'Clothing'.
INSERT INTO Sales.vw_ClothingProducts (ProductID, Product, Category, Price)
VALUES (106, 'Beanie', 'Clothing', 18);
GO
-- The following would be REJECTED by CHECK OPTION (left commented out)
-- because Category <> 'Clothing':
-- INSERT INTO Sales.vw_ClothingProducts (ProductID, Product, Category, Price)
-- VALUES (107, 'Pump', 'Accessories', 12);
SELECT * FROM Sales.vw_ClothingProducts;
GO


/* =============================================================================
   SECTION H — SCHEMA-BOUND & INDEXED VIEWS
   WITH SCHEMABINDING locks the view to the exact schema of its base
   table(s) (columns can't be dropped/altered while the view exists) and is
   a prerequisite for creating an indexed (materialized) view.
============================================================================= */

-- Task 17: Create a schema-bound view over Sales.Orders exposing OrderID,
--          Sales and Quantity (two-part table names required for
--          schemabinding).
DROP VIEW IF EXISTS Sales.vw_OrdersSchemaBound;
GO
CREATE VIEW Sales.vw_OrdersSchemaBound
WITH SCHEMABINDING
AS
SELECT OrderID, ProductID, CustomerID, Quantity, Sales
FROM Sales.Orders;
GO
SELECT * FROM Sales.vw_OrdersSchemaBound;
GO

-- Task 18: Create an indexed (materialized) view: a schema-bound
--          aggregation view over Orders with a unique clustered index,
--          which physically stores and maintains the summary data.
DROP VIEW IF EXISTS Sales.vw_ProductSalesIndexed;
GO
CREATE VIEW Sales.vw_ProductSalesIndexed
WITH SCHEMABINDING
AS
SELECT
    ProductID,
    SUM(Sales) AS TotalSales,
    COUNT_BIG(*) AS OrderCount
FROM Sales.Orders
GROUP BY ProductID;
GO
CREATE UNIQUE CLUSTERED INDEX IX_vw_ProductSalesIndexed
ON Sales.vw_ProductSalesIndexed (ProductID);
GO
SELECT * FROM Sales.vw_ProductSalesIndexed;
GO


/* =============================================================================
   SECTION I — ENCRYPTED VIEW & NESTED VIEW
   WITH ENCRYPTION obfuscates the view's definition in system metadata.
   A "nested" view is a view built on top of another view.
============================================================================= */

-- Task 19: Create an encrypted view hiding employee salary logic — the
--          view's definition text will not be visible via
--          sys.sql_modules / sp_helptext after creation.
DROP VIEW IF EXISTS Sales.vw_SalaryBandsEncrypted;
GO
CREATE VIEW Sales.vw_SalaryBandsEncrypted
WITH ENCRYPTION
AS
SELECT
    EmployeeID,
    FirstName,
    CASE
        WHEN Salary < 60000 THEN 'Band 1'
        WHEN Salary BETWEEN 60000 AND 80000 THEN 'Band 2'
        ELSE 'Band 3'
    END AS SalaryBand
FROM Sales.Employees;
GO
SELECT * FROM Sales.vw_SalaryBandsEncrypted;
-- Verify the definition is hidden (returns NULL for an encrypted view):
SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.vw_SalaryBandsEncrypted')) AS HiddenDefinition;
GO

-- Task 20: Create a nested view built on top of Sales.vw_OrderDetails
--          (Task 4), further filtering it down to high-value Clothing
--          orders only — demonstrating a view that queries another view.
DROP VIEW IF EXISTS Sales.vw_HighValueClothingOrders;
GO
CREATE VIEW Sales.vw_HighValueClothingOrders AS
SELECT OrderID, OrderDate, CustomerName, Product, Sales
FROM Sales.vw_OrderDetails
WHERE Category = 'Clothing'
  AND Sales > 20;
GO
SELECT * FROM Sales.vw_HighValueClothingOrders;
GO

/* =============================================================================
   END OF SCRIPT — 20 view tasks complete.
============================================================================= */
