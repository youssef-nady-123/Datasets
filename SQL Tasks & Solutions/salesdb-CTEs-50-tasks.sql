/*
=============================================================================
SalesDB — 50 CTE Practice Tasks & Solutions (T-SQL / SQL Server)
=============================================================================
Purpose:
    50 hands-on tasks covering Common Table Expressions (CTEs) in every
    major flavor, against the SalesDB schema (Sales.Customers,
    Sales.Employees, Sales.Products, Sales.Orders, Sales.OrdersArchive).

Sections:
    A. Simple (Non-Recursive) CTEs               (Tasks 1-10)
    B. Multiple / Chained CTEs                    (Tasks 11-18)
    C. CTEs with Aggregation                      (Tasks 19-26)
    D. CTEs with Window Functions                 (Tasks 27-34)
    E. Recursive CTEs                             (Tasks 35-42)
    F. CTEs for Data Modification (UPDATE/DELETE) (Tasks 43-46)
    G. CTEs for Deduplication                     (Tasks 47-50)

Run against the database created by init-sqlserver-salesdb.sql.
=============================================================================
*/

USE SalesDB;
GO


/* =============================================================================
   SECTION A — SIMPLE (NON-RECURSIVE) CTEs
   A CTE is a named, temporary result set defined with WITH ... AS (...)
   and referenced once in the query that follows it — useful for breaking a
   query into readable, named steps.
============================================================================= */

-- Task 1: Use a CTE to list all customers, then select only those from
--         'USA'.
WITH AllCustomers AS (
    SELECT CustomerID, FirstName, LastName, Country, Score
    FROM Sales.Customers
)
SELECT * FROM AllCustomers WHERE Country = 'USA';
GO

-- Task 2: Use a CTE to isolate 'Delivered' orders, then count them.
WITH DeliveredOrders AS (
    SELECT OrderID, CustomerID, Sales
    FROM Sales.Orders
    WHERE OrderStatus = 'Delivered'
)
SELECT COUNT(*) AS DeliveredCount FROM DeliveredOrders;
GO

-- Task 3: Use a CTE to compute each order's Sales-per-unit, then filter to
--         orders priced above $20/unit.
WITH OrderUnitPrice AS (
    SELECT OrderID, ProductID, Quantity, Sales,
           CASE WHEN Quantity > 0 THEN Sales * 1.0 / Quantity ELSE NULL END AS UnitPrice
    FROM Sales.Orders
)
SELECT * FROM OrderUnitPrice WHERE UnitPrice > 20;
GO

-- Task 4: Use a CTE to list all 'Clothing' products, then order the result
--         by Price descending.
WITH ClothingProducts AS (
    SELECT ProductID, Product, Price
    FROM Sales.Products
    WHERE Category = 'Clothing'
)
SELECT * FROM ClothingProducts ORDER BY Price DESC;
GO

-- Task 5: Use a CTE to find employees with no ManagerID (top of the org
--         chart).
WITH TopLevelEmployees AS (
    SELECT EmployeeID, FirstName, LastName, Department
    FROM Sales.Employees
    WHERE ManagerID IS NULL
)
SELECT * FROM TopLevelEmployees;
GO

-- Task 6: Use a CTE to compute each customer's full name, then filter to
--         names starting with 'M'.
WITH CustomerFullNames AS (
    SELECT CustomerID, FirstName + ' ' + ISNULL(LastName, '') AS FullName
    FROM Sales.Customers
)
SELECT * FROM CustomerFullNames WHERE FullName LIKE 'M%';
GO

-- Task 7: Use a CTE to isolate orders with a NULL ShipAddress, then join
--         back to Customers for context.
WITH MissingShipAddress AS (
    SELECT OrderID, CustomerID
    FROM Sales.Orders
    WHERE ShipAddress IS NULL
)
SELECT m.OrderID, c.FirstName, c.LastName
FROM MissingShipAddress m
JOIN Sales.Customers c ON c.CustomerID = m.CustomerID;
GO

-- Task 8: Use a CTE to flag high-value orders (Sales > 50), then select
--         only their OrderID and OrderDate.
WITH HighValueOrders AS (
    SELECT OrderID, OrderDate, Sales
    FROM Sales.Orders
    WHERE Sales > 50
)
SELECT OrderID, OrderDate FROM HighValueOrders;
GO

-- Task 9: Use a CTE to compute product profit margin category via CASE,
--         then filter to 'Premium' items only (Price >= 25).
WITH PricedProducts AS (
    SELECT ProductID, Product, Price,
           CASE WHEN Price >= 25 THEN 'Premium' ELSE 'Standard' END AS PriceTier
    FROM Sales.Products
)
SELECT * FROM PricedProducts WHERE PriceTier = 'Premium';
GO

-- Task 10: Use a CTE to list all archived orders from 2024, then count
--          them by OrderStatus.
WITH Archive2024 AS (
    SELECT OrderID, OrderStatus
    FROM Sales.OrdersArchive
    WHERE YEAR(OrderDate) = 2024
)
SELECT OrderStatus, COUNT(*) AS StatusCount
FROM Archive2024
GROUP BY OrderStatus;
GO


/* =============================================================================
   SECTION B — MULTIPLE / CHAINED CTEs
   A single WITH clause can define several CTEs (comma-separated), and a
   later CTE can reference an earlier one — building a readable pipeline.
============================================================================= */

-- Task 11: Chain two CTEs: first compute customer order totals, then
--          filter to customers whose total exceeds 50.
WITH CustomerTotals AS (
    SELECT CustomerID, SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
),
BigSpenders AS (
    SELECT CustomerID, TotalSales
    FROM CustomerTotals
    WHERE TotalSales > 50
)
SELECT c.FirstName, c.LastName, b.TotalSales
FROM BigSpenders b
JOIN Sales.Customers c ON c.CustomerID = b.CustomerID;
GO

-- Task 12: Chain CTEs to find the best-selling product per category:
--          first aggregate revenue per product, then rank within
--          category.
WITH ProductRevenue AS (
    SELECT p.ProductID, p.Product, p.Category, SUM(o.Sales) AS Revenue
    FROM Sales.Products p
    JOIN Sales.Orders o ON o.ProductID = p.ProductID
    GROUP BY p.ProductID, p.Product, p.Category
),
RankedByCategory AS (
    SELECT *, RANK() OVER (PARTITION BY Category ORDER BY Revenue DESC) AS CategoryRank
    FROM ProductRevenue
)
SELECT ProductID, Product, Category, Revenue
FROM RankedByCategory
WHERE CategoryRank = 1;
GO

-- Task 13: Chain three CTEs: orders -> customer totals -> country
--          averages, to find each country's average customer spend.
WITH OrderTotals AS (
    SELECT CustomerID, SUM(Sales) AS CustomerTotal
    FROM Sales.Orders
    GROUP BY CustomerID
),
CustomerWithCountry AS (
    SELECT c.Country, ot.CustomerTotal
    FROM OrderTotals ot
    JOIN Sales.Customers c ON c.CustomerID = ot.CustomerID
),
CountryAverages AS (
    SELECT Country, AVG(CustomerTotal) AS AvgCustomerSpend
    FROM CustomerWithCountry
    GROUP BY Country
)
SELECT * FROM CountryAverages ORDER BY AvgCustomerSpend DESC;
GO

-- Task 14: Chain CTEs to identify salespeople whose orders average above
--          the company-wide average order value.
WITH CompanyAvg AS (
    SELECT AVG(Sales) AS OverallAvg FROM Sales.Orders
),
SalesPersonAvg AS (
    SELECT SalesPersonID, AVG(Sales) AS PersonAvg
    FROM Sales.Orders
    GROUP BY SalesPersonID
)
SELECT sp.SalesPersonID, sp.PersonAvg, ca.OverallAvg
FROM SalesPersonAvg sp
CROSS JOIN CompanyAvg ca
WHERE sp.PersonAvg > ca.OverallAvg;
GO

-- Task 15: Chain CTEs to find customers whose orders touch more than one
--          product category (cross-category shoppers).
WITH OrderCategories AS (
    SELECT o.CustomerID, p.Category
    FROM Sales.Orders o
    JOIN Sales.Products p ON p.ProductID = o.ProductID
),
DistinctCategoryCounts AS (
    SELECT CustomerID, COUNT(DISTINCT Category) AS CategoryCount
    FROM OrderCategories
    GROUP BY CustomerID
)
SELECT c.FirstName, c.LastName, d.CategoryCount
FROM DistinctCategoryCounts d
JOIN Sales.Customers c ON c.CustomerID = d.CustomerID
WHERE d.CategoryCount > 1;
GO

-- Task 16: Chain CTEs to find each department's highest-paid employee's
--          name, using an aggregate CTE joined back to Employees.
WITH DeptMaxSalary AS (
    SELECT Department, MAX(Salary) AS MaxSalary
    FROM Sales.Employees
    GROUP BY Department
)
SELECT e.Department, e.FirstName, e.LastName, e.Salary
FROM Sales.Employees e
JOIN DeptMaxSalary d ON d.Department = e.Department AND d.MaxSalary = e.Salary;
GO

-- Task 17: Chain CTEs to compare current-year vs archive-year total sales
--          per customer.
WITH CurrentTotals AS (
    SELECT CustomerID, SUM(Sales) AS CurrentSales
    FROM Sales.Orders
    GROUP BY CustomerID
),
ArchiveTotals AS (
    SELECT CustomerID, SUM(Sales) AS ArchiveSales
    FROM Sales.OrdersArchive
    GROUP BY CustomerID
)
SELECT
    c.CustomerID,
    ISNULL(ct.CurrentSales, 0)  AS CurrentSales,
    ISNULL(at.ArchiveSales, 0) AS ArchiveSales
FROM Sales.Customers c
LEFT JOIN CurrentTotals ct ON ct.CustomerID = c.CustomerID
LEFT JOIN ArchiveTotals at ON at.CustomerID = c.CustomerID;
GO

-- Task 18: Chain CTEs to find products that are in the top 3 by revenue
--          AND also appear in more than 2 distinct orders.
WITH ProductRevenue AS (
    SELECT ProductID, SUM(Sales) AS Revenue, COUNT(*) AS OrderCount
    FROM Sales.Orders
    GROUP BY ProductID
),
TopRevenue AS (
    SELECT TOP 3 ProductID, Revenue FROM ProductRevenue ORDER BY Revenue DESC
),
FrequentlyOrdered AS (
    SELECT ProductID FROM ProductRevenue WHERE OrderCount > 2
)
SELECT p.ProductID, p.Product, tr.Revenue
FROM TopRevenue tr
JOIN FrequentlyOrdered fo ON fo.ProductID = tr.ProductID
JOIN Sales.Products p ON p.ProductID = tr.ProductID;
GO


/* =============================================================================
   SECTION C — CTEs WITH AGGREGATION
   CTEs commonly pre-aggregate data (GROUP BY/HAVING) so the outer query
   can filter, join, or further transform that summary cleanly.
============================================================================= */

-- Task 19: Use a CTE to find categories with total revenue above 100.
WITH CategoryRevenue AS (
    SELECT p.Category, SUM(o.Sales) AS TotalRevenue
    FROM Sales.Orders o
    JOIN Sales.Products p ON p.ProductID = o.ProductID
    GROUP BY p.Category
)
SELECT * FROM CategoryRevenue WHERE TotalRevenue > 100;
GO

-- Task 20: Use a CTE to find the average Quantity ordered per
--          OrderStatus.
WITH StatusQuantity AS (
    SELECT OrderStatus, AVG(Quantity) AS AvgQuantity
    FROM Sales.Orders
    GROUP BY OrderStatus
)
SELECT * FROM StatusQuantity ORDER BY AvgQuantity DESC;
GO

-- Task 21: Use a CTE to find salespeople with more than 3 total orders
--          across Orders + OrdersArchive combined.
WITH AllOrders AS (
    SELECT SalesPersonID FROM Sales.Orders
    UNION ALL
    SELECT SalesPersonID FROM Sales.OrdersArchive
),
SalesPersonCounts AS (
    SELECT SalesPersonID, COUNT(*) AS TotalOrders
    FROM AllOrders
    GROUP BY SalesPersonID
)
SELECT e.FirstName, e.LastName, sp.TotalOrders
FROM SalesPersonCounts sp
JOIN Sales.Employees e ON e.EmployeeID = sp.SalesPersonID
WHERE sp.TotalOrders > 3;
GO

-- Task 22: Use a CTE to compute total and average Salary per Gender.
WITH GenderPay AS (
    SELECT Gender, SUM(Salary) AS TotalSalary, AVG(Salary) AS AvgSalary
    FROM Sales.Employees
    GROUP BY Gender
)
SELECT * FROM GenderPay;
GO

-- Task 23: Use a CTE to find customers with more than one order and their
--          combined Sales total.
WITH CustomerOrderStats AS (
    SELECT CustomerID, COUNT(*) AS OrderCount, SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
)
SELECT c.FirstName, c.LastName, cos.OrderCount, cos.TotalSales
FROM CustomerOrderStats cos
JOIN Sales.Customers c ON c.CustomerID = cos.CustomerID
WHERE cos.OrderCount > 1;
GO

-- Task 24: Use a CTE to find the monthly total Sales for 2025.
WITH MonthlySales AS (
    SELECT MONTH(OrderDate) AS OrderMonth, SUM(Sales) AS MonthTotal
    FROM Sales.Orders
    WHERE YEAR(OrderDate) = 2025
    GROUP BY MONTH(OrderDate)
)
SELECT * FROM MonthlySales ORDER BY OrderMonth;
GO

-- Task 25: Use a CTE to find managers whose direct reports collectively
--          earn more than 100000 in total Salary.
WITH ReportTotals AS (
    SELECT ManagerID, SUM(Salary) AS TotalReportSalary
    FROM Sales.Employees
    WHERE ManagerID IS NOT NULL
    GROUP BY ManagerID
)
SELECT m.FirstName, m.LastName, rt.TotalReportSalary
FROM ReportTotals rt
JOIN Sales.Employees m ON m.EmployeeID = rt.ManagerID
WHERE rt.TotalReportSalary > 100000;
GO

-- Task 26: Use a CTE to find the average order Sales value per Country,
--          then show only countries above the global average.
WITH CountryAvg AS (
    SELECT c.Country, AVG(o.Sales) AS AvgSales
    FROM Sales.Orders o
    JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
    GROUP BY c.Country
)
SELECT * FROM CountryAvg
WHERE AvgSales > (SELECT AVG(Sales) FROM Sales.Orders);
GO


/* =============================================================================
   SECTION D — CTEs WITH WINDOW FUNCTIONS
   CTEs are the standard way to compute a window function and then filter
   on it, since window functions can't be referenced directly in WHERE.
============================================================================= */

-- Task 27: Use a CTE + ROW_NUMBER() to find each customer's most recent
--          order.
WITH RankedOrders AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC) AS rn
    FROM Sales.Orders
)
SELECT OrderID, CustomerID, OrderDate, Sales
FROM RankedOrders
WHERE rn = 1;
GO

-- Task 28: Use a CTE + RANK() to find the top 2 highest-priced products
--          per category.
WITH RankedProducts AS (
    SELECT *, RANK() OVER (PARTITION BY Category ORDER BY Price DESC) AS PriceRank
    FROM Sales.Products
)
SELECT ProductID, Product, Category, Price
FROM RankedProducts
WHERE PriceRank <= 2;
GO

-- Task 29: Use a CTE + running total to find the order where each
--          customer's cumulative Sales first exceeds 40.
WITH RunningTotals AS (
    SELECT
        OrderID, CustomerID, OrderDate, Sales,
        SUM(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate, OrderID) AS RunningTotal
    FROM Sales.Orders
)
SELECT CustomerID, MIN(OrderID) AS FirstOrderOverThreshold
FROM RunningTotals
WHERE RunningTotal > 40
GROUP BY CustomerID;
GO

-- Task 30: Use a CTE + LAG() to find orders where Sales dropped compared
--          to the same customer's previous order.
WITH OrderWithPrev AS (
    SELECT
        OrderID, CustomerID, OrderDate, Sales,
        LAG(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate, OrderID) AS PrevSales
    FROM Sales.Orders
)
SELECT * FROM OrderWithPrev WHERE Sales < PrevSales;
GO

-- Task 31: Use a CTE + NTILE(4) to bucket orders into Sales quartiles,
--          then show only the top quartile.
WITH SalesQuartiles AS (
    SELECT OrderID, Sales, NTILE(4) OVER (ORDER BY Sales DESC) AS Quartile
    FROM Sales.Orders
)
SELECT * FROM SalesQuartiles WHERE Quartile = 1;
GO

-- Task 32: Use a CTE + DENSE_RANK() to find the 2nd highest Salary in the
--          company (a classic "Nth highest" pattern).
WITH SalaryRanks AS (
    SELECT EmployeeID, FirstName, Salary, DENSE_RANK() OVER (ORDER BY Salary DESC) AS SalaryRank
    FROM Sales.Employees
)
SELECT * FROM SalaryRanks WHERE SalaryRank = 2;
GO

-- Task 33: Use a CTE + moving average window frame to find orders whose
--          Sales exceed their own trailing 3-order moving average.
WITH MovingAvgOrders AS (
    SELECT
        OrderID, CustomerID, OrderDate, Sales,
        AVG(Sales) OVER (
            PARTITION BY CustomerID ORDER BY OrderDate, OrderID
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS MovingAvg3
    FROM Sales.Orders
)
SELECT * FROM MovingAvgOrders WHERE Sales > MovingAvg3;
GO

-- Task 34: Use a CTE + PERCENT_RANK() to find products in the top 25th
--          percentile by price.
WITH ProductPercentiles AS (
    SELECT ProductID, Product, Price, PERCENT_RANK() OVER (ORDER BY Price) AS PctRank
    FROM Sales.Products
)
SELECT * FROM ProductPercentiles WHERE PctRank >= 0.75;
GO


/* =============================================================================
   SECTION E — RECURSIVE CTEs
   A recursive CTE has an "anchor" member (base case) UNION ALL'd with a
   "recursive" member that references the CTE itself, ideal for
   hierarchies (org charts) and generated sequences.
============================================================================= */

-- Task 35: Recursively build the full organizational chart starting from
--          the top-level employee(s), showing each employee's hierarchy
--          level.
WITH OrgChart AS (
    -- Anchor: top-level employees (no manager)
    SELECT EmployeeID, FirstName, LastName, ManagerID, 1 AS OrgLevel
    FROM Sales.Employees
    WHERE ManagerID IS NULL

    UNION ALL

    -- Recursive: each employee whose manager is already in the chart
    SELECT e.EmployeeID, e.FirstName, e.LastName, e.ManagerID, oc.OrgLevel + 1
    FROM Sales.Employees e
    JOIN OrgChart oc ON e.ManagerID = oc.EmployeeID
)
SELECT * FROM OrgChart ORDER BY OrgLevel, EmployeeID;
GO

-- Task 36: Recursively find every employee who reports (directly or
--          indirectly) up to a specific manager, e.g., EmployeeID = 1.
WITH Subordinates AS (
    SELECT EmployeeID, FirstName, LastName, ManagerID
    FROM Sales.Employees
    WHERE ManagerID = 1

    UNION ALL

    SELECT e.EmployeeID, e.FirstName, e.LastName, e.ManagerID
    FROM Sales.Employees e
    JOIN Subordinates s ON e.ManagerID = s.EmployeeID
)
SELECT * FROM Subordinates;
GO

-- Task 37: Recursively walk UP the chain of command from a given employee
--          to the top of the org (management chain / "breadcrumb" path).
WITH ManagementChain AS (
    SELECT EmployeeID, FirstName, LastName, ManagerID, 0 AS StepsUp
    FROM Sales.Employees
    WHERE EmployeeID = 5

    UNION ALL

    SELECT e.EmployeeID, e.FirstName, e.LastName, e.ManagerID, mc.StepsUp + 1
    FROM Sales.Employees e
    JOIN ManagementChain mc ON e.EmployeeID = mc.ManagerID
)
SELECT * FROM ManagementChain ORDER BY StepsUp;
GO

-- Task 38: Recursively generate a calendar/date sequence for every day in
--          January 2025.
WITH DateSequence AS (
    SELECT CAST('2025-01-01' AS DATE) AS CalendarDate

    UNION ALL

    SELECT DATEADD(DAY, 1, CalendarDate)
    FROM DateSequence
    WHERE CalendarDate < '2025-01-31'
)
SELECT * FROM DateSequence
OPTION (MAXRECURSION 100);
GO

-- Task 39: Recursively generate a numbers sequence from 1 to 20 and join
--          it against Sales.Orders to spot any "missing" OrderIDs in that
--          range.
WITH Numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM Numbers WHERE n < 20
)
SELECT n AS MissingOrderID
FROM Numbers
WHERE n NOT IN (SELECT OrderID FROM Sales.Orders)
OPTION (MAXRECURSION 100);
GO

-- Task 40: Recursively compute, for every day between the earliest and
--          latest OrderDate, a running count of how many orders had been
--          placed by that day (date scaffold + join).
WITH DateRange AS (
    SELECT MIN(OrderDate) AS CalendarDate FROM Sales.Orders

    UNION ALL

    SELECT DATEADD(DAY, 1, CalendarDate)
    FROM DateRange
    WHERE CalendarDate < (SELECT MAX(OrderDate) FROM Sales.Orders)
)
SELECT
    d.CalendarDate,
    (SELECT COUNT(*) FROM Sales.Orders o WHERE o.OrderDate <= d.CalendarDate) AS OrdersToDate
FROM DateRange d
OPTION (MAXRECURSION 1000);
GO

-- Task 41: Recursively count how many people (directly + indirectly)
--          report to each manager, using the org chart recursion plus an
--          aggregate wrap.
WITH OrgChart AS (
    SELECT EmployeeID, ManagerID, EmployeeID AS RootManager
    FROM Sales.Employees
    WHERE ManagerID IS NOT NULL

    UNION ALL

    SELECT e.EmployeeID, e.ManagerID, oc.RootManager
    FROM Sales.Employees e
    JOIN OrgChart oc ON e.ManagerID = oc.EmployeeID
),
AllReports AS (
    SELECT ManagerID AS TopManager, EmployeeID FROM Sales.Employees WHERE ManagerID IS NOT NULL
    UNION ALL
    SELECT oc.RootManager, oc.EmployeeID FROM OrgChart oc
)
SELECT
    m.FirstName + ' ' + ISNULL(m.LastName,'') AS ManagerName,
    COUNT(DISTINCT ar.EmployeeID) AS TotalReports
FROM AllReports ar
JOIN Sales.Employees m ON m.EmployeeID = ar.TopManager
GROUP BY m.FirstName, m.LastName;
GO

-- Task 42: Recursively generate a simple multiplication/quantity ladder:
--          for ProductID 101, list cumulative cost for buying 1 through 5
--          units at its current Price.
WITH QuantityLadder AS (
    SELECT 1 AS Qty, Price AS CumulativeCost
    FROM Sales.Products WHERE ProductID = 101

    UNION ALL

    SELECT ql.Qty + 1, ql.CumulativeCost + p.Price
    FROM QuantityLadder ql
    JOIN Sales.Products p ON p.ProductID = 101
    WHERE ql.Qty < 5
)
SELECT * FROM QuantityLadder
OPTION (MAXRECURSION 10);
GO


/* =============================================================================
   SECTION F — CTEs FOR DATA MODIFICATION (UPDATE / DELETE)
   A CTE can sit directly in front of UPDATE/DELETE, letting you filter or
   pre-compute (e.g., with a window function) the exact rows to modify.
============================================================================= */

-- Task 43: Use a CTE to apply a 10% Score bonus to every customer whose
--          current Score is below the overall average.
WITH BelowAverageCustomers AS (
    SELECT CustomerID, Score
    FROM Sales.Customers
    WHERE Score < (SELECT AVG(Score) FROM Sales.Customers)
)
UPDATE BelowAverageCustomers
SET Score = Score + (Score * 0.10);
GO
SELECT CustomerID, Score FROM Sales.Customers;
GO

-- Task 44: Use a CTE + ROW_NUMBER() to delete duplicate rows from
--          Sales.OrdersArchive, keeping only the earliest CreationTime for
--          each (OrderID, ShipAddress) combination.
WITH DuplicateArchiveRows AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY OrderID, ShipAddress
            ORDER BY CreationTime ASC
        ) AS rn
    FROM Sales.OrdersArchive
)
DELETE FROM DuplicateArchiveRows WHERE rn > 1;
GO
SELECT * FROM Sales.OrdersArchive ORDER BY OrderID, CreationTime;
GO

-- Task 45: Use a CTE to standardize NULL LastName values in
--          Sales.Customers to 'Unknown'.
WITH CustomersMissingLastName AS (
    SELECT CustomerID, LastName
    FROM Sales.Customers
    WHERE LastName IS NULL
)
UPDATE CustomersMissingLastName
SET LastName = 'Unknown';
GO
SELECT * FROM Sales.Customers;
GO

-- Task 46: Use a CTE to delete orders from Sales.OrdersArchive that are
--          older than 2 years relative to the most recent archive
--          CreationTime.
WITH OldArchiveOrders AS (
    SELECT OrderID, CreationTime
    FROM Sales.OrdersArchive
    WHERE CreationTime < DATEADD(YEAR, -2, (SELECT MAX(CreationTime) FROM Sales.OrdersArchive))
)
DELETE FROM OldArchiveOrders;
GO
SELECT COUNT(*) AS RemainingArchiveRows FROM Sales.OrdersArchive;
GO


/* =============================================================================
   SECTION G — CTEs FOR DEDUPLICATION
   A very common real-world CTE pattern: use ROW_NUMBER() partitioned by
   the "duplicate key" to identify and isolate redundant rows.
============================================================================= */

-- Task 47: Identify duplicate rows in Sales.OrdersArchive that share the
--          same OrderID, ProductID, CustomerID, and CreationTime date
--          (ignoring time) — a read-only duplicate report.
WITH FlaggedDuplicates AS (
    SELECT
        OrderID, ProductID, CustomerID, CreationTime,
        ROW_NUMBER() OVER (
            PARTITION BY OrderID, ProductID, CustomerID, CAST(CreationTime AS DATE)
            ORDER BY CreationTime
        ) AS DuplicateRank
    FROM Sales.OrdersArchive
)
SELECT * FROM FlaggedDuplicates WHERE DuplicateRank > 1;
GO

-- Task 48: Identify OrderIDs that appear more than once in
--          Sales.OrdersArchive, showing the total occurrence count for
--          each.
WITH OrderCounts AS (
    SELECT OrderID, COUNT(*) AS Occurrences,
           ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY (SELECT NULL)) AS rn
    FROM Sales.OrdersArchive
    GROUP BY OrderID
)
SELECT OrderID, Occurrences
FROM (
    SELECT OrderID, COUNT(*) AS Occurrences
    FROM Sales.OrdersArchive
    GROUP BY OrderID
) AS grouped
WHERE Occurrences > 1;
GO

-- Task 49: Use a CTE to return only the single "best" archive record per
--          duplicated OrderID — the one with the latest CreationTime (a
--          non-destructive way to preview what Task 44's cleanup keeps).
WITH RankedArchive AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY CreationTime DESC) AS rn
    FROM Sales.OrdersArchive
)
SELECT OrderID, ShipAddress, BillAddress, OrderStatus, CreationTime
FROM RankedArchive
WHERE rn = 1;
GO

-- Task 50: Use a CTE to detect duplicate customers by (FirstName,
--          LastName, Country) — same person entered more than once — and
--          list all but the first (lowest CustomerID) occurrence of each.
WITH DuplicateCustomers AS (
    SELECT
        CustomerID, FirstName, LastName, Country,
        ROW_NUMBER() OVER (
            PARTITION BY FirstName, LastName, Country
            ORDER BY CustomerID
        ) AS rn
    FROM Sales.Customers
)
SELECT * FROM DuplicateCustomers WHERE rn > 1;
GO

/* =============================================================================
   END OF SCRIPT — 50 CTE tasks complete.
============================================================================= */
