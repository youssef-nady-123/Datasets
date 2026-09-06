/*
=============================================================
SalesDB_tasks.sql
Intermediate SQL Server (T-SQL) Practice Tasks & Solutions
=============================================================
Database : SalesDB
Tables   : Sales.Customers, Sales.Employees, Sales.Products,
           Sales.Orders, Sales.OrdersArchive

Format   : Each task is a numbered comment block followed
           immediately by its solution query.

Topics covered:
  01-10  Filtering, Sorting, TOP
  11-20  Aggregation / GROUP BY / HAVING
  21-35  Joins (INNER, LEFT, RIGHT, FULL, SELF, CROSS)
  36-45  Subqueries (scalar, correlated, EXISTS, IN, ANY/ALL)
  46-60  Window Functions (RANK, ROW_NUMBER, LAG/LEAD, running totals)
  61-70  CTEs & Recursive CTEs
  71-78  String Functions
  79-86  Date Functions
  87-93  CASE Expressions
  94-98  Set Operations (UNION, INTERSECT, EXCEPT)
  99-105 NULL Handling, Data Modification, Misc

Run this script after running SalesDB.sql to build the database.
=============================================================
*/

USE SalesDB;
GO

/*
=============================================================
SECTION 1: FILTERING, SORTING, TOP  (Tasks 1-10)
=============================================================
*/

-- Task 1: List all customers from 'Germany', ordered by Score descending.
SELECT CustomerID, FirstName, LastName, Country, Score
FROM Sales.Customers
WHERE Country = 'Germany'
ORDER BY Score DESC;
GO

-- Task 2: Find the top 5 highest-paid employees.
SELECT TOP 5 EmployeeID, FirstName, LastName, Department, Salary
FROM Sales.Employees
ORDER BY Salary DESC;
GO

-- Task 3: List products priced between 100 and 300, ordered by Price ascending.
SELECT ProductID, Product, Category, Price
FROM Sales.Products
WHERE Price BETWEEN 100 AND 300
ORDER BY Price ASC;
GO

-- Task 4: Find all orders with status 'Cancelled' or 'Delivered'.
SELECT OrderID, OrderStatus, OrderDate, Sales
FROM Sales.Orders
WHERE OrderStatus IN ('Cancelled', 'Delivered');
GO

-- Task 5: List customers whose LastName starts with 'M'.
SELECT CustomerID, FirstName, LastName
FROM Sales.Customers
WHERE LastName LIKE 'M%';
GO

-- Task 6: Find the 3 most recent orders (by OrderDate).
SELECT TOP 3 OrderID, OrderDate, Sales
FROM Sales.Orders
ORDER BY OrderDate DESC;
GO

-- Task 7: List employees NOT in the 'Sales' or 'IT' departments.
SELECT EmployeeID, FirstName, LastName, Department
FROM Sales.Employees
WHERE Department NOT IN ('Sales', 'IT');
GO

-- Task 8: Find orders where Quantity is 0 (likely cancelled/void orders).
SELECT OrderID, CustomerID, Quantity, Sales, OrderStatus
FROM Sales.Orders
WHERE Quantity = 0;
GO

-- Task 9: List the bottom 5 customers by Score (lowest scores).
SELECT TOP 5 CustomerID, FirstName, LastName, Score
FROM Sales.Customers
ORDER BY Score ASC;
GO

-- Task 10: Find products in the 'Electronics' category priced above the overall average product price.
SELECT ProductID, Product, Price
FROM Sales.Products
WHERE Category = 'Electronics'
  AND Price > (SELECT AVG(Price) FROM Sales.Products);
GO


/*
=============================================================
SECTION 2: AGGREGATION / GROUP BY / HAVING  (Tasks 11-20)
=============================================================
*/

-- Task 11: Count the number of customers per country.
SELECT Country, COUNT(*) AS CustomerCount
FROM Sales.Customers
GROUP BY Country
ORDER BY CustomerCount DESC;
GO

-- Task 12: Find the average salary per department.
SELECT Department, AVG(Salary) AS AvgSalary
FROM Sales.Employees
GROUP BY Department
ORDER BY AvgSalary DESC;
GO

-- Task 13: Find total Sales and total Quantity per OrderStatus.
SELECT OrderStatus, SUM(Sales) AS TotalSales, SUM(Quantity) AS TotalQty
FROM Sales.Orders
GROUP BY OrderStatus
ORDER BY TotalSales DESC;
GO

-- Task 14: Find product categories that have more than 20 products.
SELECT Category, COUNT(*) AS ProductCount
FROM Sales.Products
GROUP BY Category
HAVING COUNT(*) > 20;
GO

-- Task 15: Find countries where the average customer Score is above 600.
SELECT Country, AVG(Score) AS AvgScore
FROM Sales.Customers
GROUP BY Country
HAVING AVG(Score) > 600;
GO

-- Task 16: Find the min, max, and average Price per product Category.
SELECT Category,
       MIN(Price) AS MinPrice,
       MAX(Price) AS MaxPrice,
       AVG(Price) AS AvgPrice
FROM Sales.Products
GROUP BY Category;
GO

-- Task 17: Find each salesperson's total sales, only for salespeople with more than 3 orders.
SELECT SalesPersonID, COUNT(*) AS OrderCount, SUM(Sales) AS TotalSales
FROM Sales.Orders
GROUP BY SalesPersonID
HAVING COUNT(*) > 3
ORDER BY TotalSales DESC;
GO

-- Task 18: Find the number of male and female employees per department.
SELECT Department, Gender, COUNT(*) AS EmployeeCount
FROM Sales.Employees
GROUP BY Department, Gender
ORDER BY Department, Gender;
GO

-- Task 19: Find the total sales per year of OrderDate.
SELECT YEAR(OrderDate) AS OrderYear, SUM(Sales) AS TotalSales
FROM Sales.Orders
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;
GO

-- Task 20: Find customers (by CustomerID) who placed more than 1 order, along with their order count and total spend.
SELECT CustomerID, COUNT(*) AS OrderCount, SUM(Sales) AS TotalSpend
FROM Sales.Orders
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY TotalSpend DESC;
GO


/*
=============================================================
SECTION 3: JOINS  (Tasks 21-35)
=============================================================
*/

-- Task 21: List each order with the customer's full name.
SELECT o.OrderID, c.FirstName + ' ' + c.LastName AS CustomerName,
       o.OrderDate, o.Sales
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID;
GO

-- Task 22: List each order with the product name and category.
SELECT o.OrderID, p.Product, p.Category, o.Quantity, o.Sales
FROM Sales.Orders o
INNER JOIN Sales.Products p ON o.ProductID = p.ProductID;
GO

-- Task 23: List each order with the salesperson's name
-- (SalesPersonID -> Employees.EmployeeID).
SELECT o.OrderID, e.FirstName + ' ' + e.LastName AS SalesPerson, o.Sales
FROM Sales.Orders o
INNER JOIN Sales.Employees e ON o.SalesPersonID = e.EmployeeID;
GO

-- Task 24: Find customers who have never placed an order (LEFT JOIN).
SELECT c.CustomerID, c.FirstName, c.LastName
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;
GO

-- Task 25: Find products that have never been ordered (LEFT JOIN).
SELECT p.ProductID, p.Product
FROM Sales.Products p
LEFT JOIN Sales.Orders o ON p.ProductID = o.ProductID
WHERE o.OrderID IS NULL;
GO

-- Task 26: Find employees who have never made a sale (LEFT JOIN,
-- Employees acting as salespeople).
SELECT e.EmployeeID, e.FirstName, e.LastName
FROM Sales.Employees e
LEFT JOIN Sales.Orders o ON e.EmployeeID = o.SalesPersonID
WHERE o.OrderID IS NULL;
GO

-- Task 27: Full outer join of Customers and Orders to see unmatched rows
-- on both sides.
SELECT c.CustomerID AS Cust_CustomerID, o.CustomerID AS Order_CustomerID,
       o.OrderID
FROM Sales.Customers c
FULL OUTER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID IS NULL OR o.CustomerID IS NULL;
GO

-- Task 28: Self-join Employees to list each employee with their manager's name.
SELECT e.EmployeeID, e.FirstName + ' ' + e.LastName AS Employee,
       m.FirstName + ' ' + m.LastName AS Manager
FROM Sales.Employees e
LEFT JOIN Sales.Employees m ON e.ManagerID = m.EmployeeID
ORDER BY e.EmployeeID;
GO

-- Task 29: Full order details in one row: customer, product, and salesperson.
SELECT o.OrderID,
       c.FirstName + ' ' + c.LastName AS Customer,
       p.Product,
       e.FirstName + ' ' + e.LastName AS SalesPerson,
       o.OrderDate, o.Sales
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
INNER JOIN Sales.Products p ON o.ProductID = p.ProductID
INNER JOIN Sales.Employees e ON o.SalesPersonID = e.EmployeeID;
GO

-- Task 30: Cross join Employees in 'Sales' with Products in 'Electronics'
-- to list every possible pairing (demonstrates CROSS JOIN).
SELECT e.FirstName + ' ' + e.LastName AS SalesPerson, p.Product
FROM Sales.Employees e
CROSS JOIN Sales.Products p
WHERE e.Department = 'Sales' AND p.Category = 'Electronics';
GO

-- Task 31: List orders together with matching rows from OrdersArchive
-- for the same OrderID (to spot duplicated/archived orders).
SELECT o.OrderID, o.OrderStatus AS CurrentStatus, a.OrderStatus AS ArchivedStatus
FROM Sales.Orders o
INNER JOIN Sales.OrdersArchive a ON o.OrderID = a.OrderID;
GO

-- Task 32: Find orders that exist in Orders but NOT in OrdersArchive.
SELECT o.OrderID
FROM Sales.Orders o
LEFT JOIN Sales.OrdersArchive a ON o.OrderID = a.OrderID
WHERE a.OrderID IS NULL;
GO

-- Task 33: For each country, list the customer with the highest Score
-- (join Customers to itself is unnecessary - use a derived table).
SELECT c.Country, c.CustomerID, c.FirstName, c.LastName, c.Score
FROM Sales.Customers c
INNER JOIN (
    SELECT Country, MAX(Score) AS MaxScore
    FROM Sales.Customers
    GROUP BY Country
) top_c ON c.Country = top_c.Country AND c.Score = top_c.MaxScore;
GO

-- Task 34: List each employee together with the number of employees
-- they directly manage (self-join + aggregation).
SELECT m.EmployeeID, m.FirstName + ' ' + m.LastName AS Manager,
       COUNT(e.EmployeeID) AS DirectReports
FROM Sales.Employees m
LEFT JOIN Sales.Employees e ON e.ManagerID = m.EmployeeID
GROUP BY m.EmployeeID, m.FirstName, m.LastName
ORDER BY DirectReports DESC;
GO

-- Task 35: List orders shipped to a different address than billed
-- (join not required, but phrased as a join-style comparison task).
SELECT o.OrderID, o.ShipAddress, o.BillAddress
FROM Sales.Orders o
WHERE o.ShipAddress <> o.BillAddress
   OR o.ShipAddress IS NULL
   OR o.BillAddress IS NULL;
GO


/*
=============================================================
SECTION 4: SUBQUERIES  (Tasks 36-45)
=============================================================
*/

-- Task 36: Find customers whose Score is above the overall average Score
-- (scalar subquery).
SELECT CustomerID, FirstName, LastName, Score
FROM Sales.Customers
WHERE Score > (SELECT AVG(Score) FROM Sales.Customers);
GO

-- Task 37: Find the product(s) with the highest price (subquery in WHERE).
SELECT ProductID, Product, Price
FROM Sales.Products
WHERE Price = (SELECT MAX(Price) FROM Sales.Products);
GO

-- Task 38: Find customers who have placed at least one order (IN subquery).
SELECT CustomerID, FirstName, LastName
FROM Sales.Customers
WHERE CustomerID IN (SELECT DISTINCT CustomerID FROM Sales.Orders);
GO

-- Task 39: Find customers who have never placed an order (NOT IN subquery).
SELECT CustomerID, FirstName, LastName
FROM Sales.Customers
WHERE CustomerID NOT IN (
    SELECT CustomerID FROM Sales.Orders WHERE CustomerID IS NOT NULL
);
GO

-- Task 40: Correlated subquery - find orders whose Sales value is above
-- the average Sales for that same customer.
SELECT o1.OrderID, o1.CustomerID, o1.Sales
FROM Sales.Orders o1
WHERE o1.Sales > (
    SELECT AVG(o2.Sales)
    FROM Sales.Orders o2
    WHERE o2.CustomerID = o1.CustomerID
);
GO

-- Task 41: EXISTS - find customers who have at least one 'Cancelled' order.
SELECT c.CustomerID, c.FirstName, c.LastName
FROM Sales.Customers c
WHERE EXISTS (
    SELECT 1 FROM Sales.Orders o
    WHERE o.CustomerID = c.CustomerID AND o.OrderStatus = 'Cancelled'
);
GO

-- Task 42: NOT EXISTS - find products that were never included in any order.
SELECT p.ProductID, p.Product
FROM Sales.Products p
WHERE NOT EXISTS (
    SELECT 1 FROM Sales.Orders o WHERE o.ProductID = p.ProductID
);
GO

-- Task 43: ANY - find employees whose salary is greater than ANY salary
-- in the 'HR' department (i.e., greater than the minimum HR salary).
SELECT EmployeeID, FirstName, LastName, Department, Salary
FROM Sales.Employees
WHERE Salary > ANY (SELECT Salary FROM Sales.Employees WHERE Department = 'HR')
  AND Department <> 'HR';
GO

-- Task 44: ALL - find employees whose salary is greater than ALL salaries
-- in the 'Marketing' department (i.e., greater than the max Marketing salary).
SELECT EmployeeID, FirstName, LastName, Department, Salary
FROM Sales.Employees
WHERE Salary > ALL (SELECT Salary FROM Sales.Employees WHERE Department = 'Marketing')
  AND Department <> 'Marketing';
GO

-- Task 45: Use a subquery in SELECT to show each order's Sales value
-- alongside the customer's average order value.
SELECT o.OrderID, o.CustomerID, o.Sales,
       (SELECT AVG(o2.Sales) FROM Sales.Orders o2
        WHERE o2.CustomerID = o.CustomerID) AS CustomerAvgSales
FROM Sales.Orders o
ORDER BY o.CustomerID;
GO


/*
=============================================================
SECTION 5: WINDOW FUNCTIONS  (Tasks 46-60)
=============================================================
*/

-- Task 46: Rank employees within each department by Salary (highest first).
SELECT EmployeeID, FirstName, LastName, Department, Salary,
       RANK() OVER (PARTITION BY Department ORDER BY Salary DESC) AS SalaryRank
FROM Sales.Employees;
GO

-- Task 47: Use DENSE_RANK to rank customers by Score overall.
SELECT CustomerID, FirstName, LastName, Score,
       DENSE_RANK() OVER (ORDER BY Score DESC) AS ScoreRank
FROM Sales.Customers;
GO

-- Task 48: Use ROW_NUMBER to number each customer's orders chronologically.
SELECT OrderID, CustomerID, OrderDate,
       ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS OrderSeq
FROM Sales.Orders;
GO

-- Task 49: Find each customer's FIRST order using ROW_NUMBER in a CTE.
WITH RankedOrders AS (
    SELECT OrderID, CustomerID, OrderDate, Sales,
           ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS rn
    FROM Sales.Orders
)
SELECT OrderID, CustomerID, OrderDate, Sales
FROM RankedOrders
WHERE rn = 1;
GO

-- Task 50: Find each customer's MOST RECENT order.
WITH RankedOrders AS (
    SELECT OrderID, CustomerID, OrderDate, Sales,
           ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC) AS rn
    FROM Sales.Orders
)
SELECT OrderID, CustomerID, OrderDate, Sales
FROM RankedOrders
WHERE rn = 1;
GO

-- Task 51: Calculate a running total of Sales ordered by OrderDate.
SELECT OrderID, OrderDate, Sales,
       SUM(Sales) OVER (ORDER BY OrderDate, OrderID
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal
FROM Sales.Orders;
GO

-- Task 52: Calculate a running total of Sales per customer, ordered by OrderDate.
SELECT OrderID, CustomerID, OrderDate, Sales,
       SUM(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate, OrderID
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CustomerRunningTotal
FROM Sales.Orders;
GO

-- Task 53: Use LAG to compare each order's Sales to the customer's previous order.
SELECT OrderID, CustomerID, OrderDate, Sales,
       LAG(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS PrevOrderSales,
       Sales - LAG(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS Change
FROM Sales.Orders;
GO

-- Task 54: Use LEAD to show each order's Sales next to the customer's NEXT order.
SELECT OrderID, CustomerID, OrderDate, Sales,
       LEAD(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS NextOrderSales
FROM Sales.Orders;
GO

-- Task 55: Compute a 3-order moving average of Sales per customer.
SELECT OrderID, CustomerID, OrderDate, Sales,
       AVG(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate
                         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MovingAvg3
FROM Sales.Orders;
GO

-- Task 56: Use NTILE to split employees into 4 salary buckets (quartiles).
SELECT EmployeeID, FirstName, LastName, Salary,
       NTILE(4) OVER (ORDER BY Salary DESC) AS SalaryQuartile
FROM Sales.Employees;
GO

-- Task 57: Show each order's Sales as a percentage of that customer's total sales.
SELECT OrderID, CustomerID, Sales,
       SUM(Sales) OVER (PARTITION BY CustomerID) AS CustomerTotal,
       CAST(Sales AS FLOAT) / SUM(Sales) OVER (PARTITION BY CustomerID) * 100 AS PctOfCustomerTotal
FROM Sales.Orders;
GO

-- Task 58: Find the top 3 highest-Sales orders per SalesPersonID.
WITH RankedBySalesperson AS (
    SELECT OrderID, SalesPersonID, Sales,
           RANK() OVER (PARTITION BY SalesPersonID ORDER BY Sales DESC) AS rnk
    FROM Sales.Orders
)
SELECT OrderID, SalesPersonID, Sales, rnk
FROM RankedBySalesperson
WHERE rnk <= 3
ORDER BY SalesPersonID, rnk;
GO

-- Task 59: Use FIRST_VALUE to show each employee's salary next to the
-- highest-paid salary in their department.
SELECT EmployeeID, FirstName, LastName, Department, Salary,
       FIRST_VALUE(Salary) OVER (PARTITION BY Department ORDER BY Salary DESC
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS TopDeptSalary
FROM Sales.Employees;
GO

-- Task 60: Calculate the difference between each product's price and the
-- average price within its category using a window function.
SELECT ProductID, Product, Category, Price,
       Price - AVG(Price) OVER (PARTITION BY Category) AS DiffFromCategoryAvg
FROM Sales.Products;
GO


/*
=============================================================
SECTION 6: CTEs & RECURSIVE CTEs  (Tasks 61-70)
=============================================================
*/

-- Task 61: Use a CTE to list customers with above-average Score.
WITH AvgScoreCTE AS (
    SELECT AVG(Score) AS AvgScore FROM Sales.Customers
)
SELECT c.CustomerID, c.FirstName, c.LastName, c.Score
FROM Sales.Customers c
CROSS JOIN AvgScoreCTE a
WHERE c.Score > a.AvgScore;
GO

-- Task 62: Use a CTE to summarize total Sales per Category, then filter
-- to categories above 50,000 total sales.
WITH CategorySales AS (
    SELECT p.Category, SUM(o.Sales) AS TotalSales
    FROM Sales.Orders o
    INNER JOIN Sales.Products p ON o.ProductID = p.ProductID
    GROUP BY p.Category
)
SELECT Category, TotalSales
FROM CategorySales
WHERE TotalSales > 50000
ORDER BY TotalSales DESC;
GO

-- Task 63: Use multiple CTEs to compare each salesperson's total sales
-- against the company average.
WITH SalespersonSales AS (
    SELECT SalesPersonID, SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY SalesPersonID
),
CompanyAvg AS (
    SELECT AVG(TotalSales) AS AvgSales FROM SalespersonSales
)
SELECT s.SalesPersonID, s.TotalSales, c.AvgSales,
       s.TotalSales - c.AvgSales AS DiffFromAvg
FROM SalespersonSales s
CROSS JOIN CompanyAvg c
ORDER BY DiffFromAvg DESC;
GO

-- Task 64: Recursive CTE - build the full management chain (org chart)
-- starting from top-level managers (ManagerID IS NULL).
WITH OrgChart AS (
    SELECT EmployeeID, FirstName, LastName, ManagerID, 1 AS Level
    FROM Sales.Employees
    WHERE ManagerID IS NULL
    UNION ALL
    SELECT e.EmployeeID, e.FirstName, e.LastName, e.ManagerID, oc.Level + 1
    FROM Sales.Employees e
    INNER JOIN OrgChart oc ON e.ManagerID = oc.EmployeeID
)
SELECT EmployeeID, FirstName, LastName, ManagerID, Level
FROM OrgChart
ORDER BY Level, EmployeeID;
GO

-- Task 65: Recursive CTE - count total reports (direct + indirect)
-- under each top-level manager.
WITH OrgChart AS (
    SELECT EmployeeID, ManagerID, EmployeeID AS TopManagerID
    FROM Sales.Employees
    WHERE ManagerID IS NULL
    UNION ALL
    SELECT e.EmployeeID, e.ManagerID, oc.TopManagerID
    FROM Sales.Employees e
    INNER JOIN OrgChart oc ON e.ManagerID = oc.EmployeeID
)
SELECT m.EmployeeID, m.FirstName, m.LastName,
       COUNT(oc.EmployeeID) - 1 AS TotalReports
FROM OrgChart oc
INNER JOIN Sales.Employees m ON oc.TopManagerID = m.EmployeeID
GROUP BY m.EmployeeID, m.FirstName, m.LastName
ORDER BY TotalReports DESC;
GO

-- Task 66: Use a CTE + window function to find the second highest paid
-- employee in each department.
WITH RankedSalary AS (
    SELECT EmployeeID, FirstName, LastName, Department, Salary,
           DENSE_RANK() OVER (PARTITION BY Department ORDER BY Salary DESC) AS rnk
    FROM Sales.Employees
)
SELECT EmployeeID, FirstName, LastName, Department, Salary
FROM RankedSalary
WHERE rnk = 2;
GO

-- Task 67: Use a CTE to identify duplicate OrderIDs between Orders and
-- OrdersArchive with differing OrderStatus (data-quality check).
WITH StatusCompare AS (
    SELECT o.OrderID, o.OrderStatus AS CurrentStatus, a.OrderStatus AS ArchivedStatus
    FROM Sales.Orders o
    INNER JOIN Sales.OrdersArchive a ON o.OrderID = a.OrderID
)
SELECT *
FROM StatusCompare
WHERE CurrentStatus <> ArchivedStatus;
GO

-- Task 68: CTE to calculate each customer's order count and rank customers
-- by how frequently they order.
WITH CustomerOrderCounts AS (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM Sales.Orders
    GROUP BY CustomerID
)
SELECT CustomerID, OrderCount,
       RANK() OVER (ORDER BY OrderCount DESC) AS FrequencyRank
FROM CustomerOrderCounts;
GO

-- Task 69: CTE to find months where total sales dropped compared to the
-- previous month.
WITH MonthlySales AS (
    SELECT FORMAT(OrderDate, 'yyyy-MM') AS OrderMonth, SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY FORMAT(OrderDate, 'yyyy-MM')
),
MonthlyChange AS (
    SELECT OrderMonth, TotalSales,
           LAG(TotalSales) OVER (ORDER BY OrderMonth) AS PrevMonthSales
    FROM MonthlySales
)
SELECT OrderMonth, TotalSales, PrevMonthSales,
       TotalSales - PrevMonthSales AS Change
FROM MonthlyChange
WHERE TotalSales < PrevMonthSales;
GO

-- Task 70: Recursive CTE - generate a calendar (date spine) of all dates
-- between the earliest and latest OrderDate in Orders.
WITH DateRange AS (
    SELECT MIN(OrderDate) AS OrderDate FROM Sales.Orders
    UNION ALL
    SELECT DATEADD(DAY, 1, OrderDate)
    FROM DateRange
    WHERE OrderDate < (SELECT MAX(OrderDate) FROM Sales.Orders)
)
SELECT OrderDate
FROM DateRange
OPTION (MAXRECURSION 1000);
GO


/*
=============================================================
SECTION 7: STRING FUNCTIONS  (Tasks 71-78)
=============================================================
*/

-- Task 71: Concatenate FirstName and LastName into a FullName column.
SELECT CustomerID, CONCAT(FirstName, ' ', LastName) AS FullName
FROM Sales.Customers;
GO

-- Task 72: Show customer names in UPPER and lower case.
SELECT CustomerID, UPPER(FirstName) AS FirstUpper, LOWER(LastName) AS LastLower
FROM Sales.Customers;
GO

-- Task 73: Extract the numeric suffix from each Product name
-- (e.g., 'Bottle 1' -> '1') using SUBSTRING/CHARINDEX.
SELECT ProductID, Product,
       SUBSTRING(Product, CHARINDEX(' ', Product) + 1, LEN(Product)) AS ProductNumber
FROM Sales.Products;
GO

-- Task 74: Find the length of each customer's full name.
SELECT CustomerID, FirstName, LastName,
       LEN(FirstName + ' ' + LastName) AS FullNameLength
FROM Sales.Customers;
GO

-- Task 75: Mask ShipAddress by only showing the street number and 'XXX'.
SELECT OrderID, ShipAddress,
       LEFT(ShipAddress, CHARINDEX(' ', ShipAddress)) + 'XXX' AS MaskedAddress
FROM Sales.Orders
WHERE ShipAddress IS NOT NULL;
GO

-- Task 76: Trim and standardize Department names to a consistent format
-- (demonstrates TRIM/UPPER usage).
SELECT DISTINCT UPPER(TRIM(Department)) AS DepartmentStandardized
FROM Sales.Employees;
GO

-- Task 77: Replace 'St' with 'Street' in ShipAddress values.
SELECT OrderID, ShipAddress,
       REPLACE(ShipAddress, ' St', ' Street') AS FullShipAddress
FROM Sales.Orders
WHERE ShipAddress IS NOT NULL;
GO

-- Task 78: Build an email-style username from FirstName and LastName
-- (lowercase, dot-separated) for each employee.
SELECT EmployeeID,
       LOWER(FirstName) + '.' + LOWER(LastName) + '@company.com' AS CompanyEmail
FROM Sales.Employees;
GO


/*
=============================================================
SECTION 8: DATE FUNCTIONS  (Tasks 79-86)
=============================================================
*/

-- Task 79: Calculate the age of each employee in years.
SELECT EmployeeID, FirstName, LastName, BirthDate,
       DATEDIFF(YEAR, BirthDate, GETDATE())
       - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, BirthDate, GETDATE()), BirthDate) > GETDATE()
              THEN 1 ELSE 0 END AS Age
FROM Sales.Employees;
GO

-- Task 80: Calculate the number of days between OrderDate and ShipDate
-- for each order (fulfillment time).
SELECT OrderID, OrderDate, ShipDate,
       DATEDIFF(DAY, OrderDate, ShipDate) AS FulfillmentDays
FROM Sales.Orders;
GO

-- Task 81: Find orders placed on a weekend (Saturday/Sunday).
SELECT OrderID, OrderDate, DATENAME(WEEKDAY, OrderDate) AS DayOfWeek
FROM Sales.Orders
WHERE DATEPART(WEEKDAY, OrderDate) IN (1, 7);
GO

-- Task 82: Extract Year and Month from OrderDate and count orders per month.
SELECT YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth,
       COUNT(*) AS OrderCount
FROM Sales.Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;
GO

-- Task 83: Find employees hired (BirthDate used as a stand-in "reference
-- date") more than 50 years ago from today.
SELECT EmployeeID, FirstName, LastName, BirthDate
FROM Sales.Employees
WHERE DATEDIFF(YEAR, BirthDate, GETDATE()) > 50;
GO

-- Task 84: Find the earliest and latest OrderDate in the Orders table.
SELECT MIN(OrderDate) AS EarliestOrder, MAX(OrderDate) AS LatestOrder
FROM Sales.Orders;
GO

-- Task 85: Add 30 days to each OrderDate to compute a "review date".
SELECT OrderID, OrderDate, DATEADD(DAY, 30, OrderDate) AS ReviewDate
FROM Sales.Orders;
GO

-- Task 86: Find orders where ShipDate is more than 7 days after OrderDate
-- (flag as delayed shipments).
SELECT OrderID, OrderDate, ShipDate,
       DATEDIFF(DAY, OrderDate, ShipDate) AS DaysToShip
FROM Sales.Orders
WHERE DATEDIFF(DAY, OrderDate, ShipDate) > 7;
GO


/*
=============================================================
SECTION 9: CASE EXPRESSIONS  (Tasks 87-93)
=============================================================
*/

-- Task 87: Categorize customers into Score tiers (Low/Medium/High).
SELECT CustomerID, FirstName, LastName, Score,
       CASE
           WHEN Score < 400 THEN 'Low'
           WHEN Score BETWEEN 400 AND 700 THEN 'Medium'
           ELSE 'High'
       END AS ScoreTier
FROM Sales.Customers;
GO

-- Task 88: Label each order as 'Small', 'Medium', or 'Large' based on Sales.
SELECT OrderID, Sales,
       CASE
           WHEN Sales < 300 THEN 'Small'
           WHEN Sales BETWEEN 300 AND 900 THEN 'Medium'
           ELSE 'Large'
       END AS OrderSize
FROM Sales.Orders;
GO

-- Task 89: Flag employees as 'Manager' if they appear as a ManagerID for
-- someone else, otherwise 'Individual Contributor'.
SELECT e.EmployeeID, e.FirstName, e.LastName,
       CASE
           WHEN e.EmployeeID IN (SELECT DISTINCT ManagerID FROM Sales.Employees WHERE ManagerID IS NOT NULL)
           THEN 'Manager'
           ELSE 'Individual Contributor'
       END AS Role
FROM Sales.Employees e;
GO

-- Task 90: Pivot-style summary using CASE: total sales by OrderStatus
-- as separate columns.
SELECT
    SUM(CASE WHEN OrderStatus = 'Delivered' THEN Sales ELSE 0 END) AS DeliveredSales,
    SUM(CASE WHEN OrderStatus = 'Shipped' THEN Sales ELSE 0 END) AS ShippedSales,
    SUM(CASE WHEN OrderStatus = 'Processing' THEN Sales ELSE 0 END) AS ProcessingSales,
    SUM(CASE WHEN OrderStatus = 'Cancelled' THEN Sales ELSE 0 END) AS CancelledSales
FROM Sales.Orders;
GO

-- Task 91: Classify products as 'Budget', 'Mid-range', or 'Premium'
-- based on Price.
SELECT ProductID, Product, Price,
       CASE
           WHEN Price < 100 THEN 'Budget'
           WHEN Price BETWEEN 100 AND 250 THEN 'Mid-range'
           ELSE 'Premium'
       END AS PriceTier
FROM Sales.Products;
GO

-- Task 92: Show whether ShipAddress and BillAddress match, using CASE.
SELECT OrderID, ShipAddress, BillAddress,
       CASE
           WHEN ShipAddress IS NULL OR BillAddress IS NULL THEN 'Unknown'
           WHEN ShipAddress = BillAddress THEN 'Same'
           ELSE 'Different'
       END AS AddressMatch
FROM Sales.Orders;
GO

-- Task 93: Assign a generation label to employees based on BirthDate.
SELECT EmployeeID, FirstName, LastName, BirthDate,
       CASE
           WHEN YEAR(BirthDate) BETWEEN 1965 AND 1980 THEN 'Gen X'
           WHEN YEAR(BirthDate) BETWEEN 1981 AND 1996 THEN 'Millennial'
           ELSE 'Other'
       END AS Generation
FROM Sales.Employees;
GO


/*
=============================================================
SECTION 10: SET OPERATIONS  (Tasks 94-98)
=============================================================
*/

-- Task 94: Combine a list of Customer names and Employee names into a
-- single unified list using UNION.
SELECT FirstName, LastName, 'Customer' AS SourceType FROM Sales.Customers
UNION
SELECT FirstName, LastName, 'Employee' AS SourceType FROM Sales.Employees;
GO

-- Task 95: Use UNION ALL to combine Orders and OrdersArchive into a
-- single result set (keeping duplicates).
SELECT OrderID, OrderStatus, Sales, 'Orders' AS SourceTable FROM Sales.Orders
UNION ALL
SELECT OrderID, OrderStatus, Sales, 'OrdersArchive' AS SourceTable FROM Sales.OrdersArchive;
GO

-- Task 96: Find OrderIDs that exist in BOTH Orders and OrdersArchive
-- using INTERSECT.
SELECT OrderID FROM Sales.Orders
INTERSECT
SELECT OrderID FROM Sales.OrdersArchive;
GO

-- Task 97: Find OrderIDs that exist in Orders but NOT in OrdersArchive
-- using EXCEPT.
SELECT OrderID FROM Sales.Orders
EXCEPT
SELECT OrderID FROM Sales.OrdersArchive;
GO

-- Task 98: Find OrderIDs that exist in OrdersArchive but NOT in Orders
-- using EXCEPT (reverse direction).
SELECT OrderID FROM Sales.OrdersArchive
EXCEPT
SELECT OrderID FROM Sales.Orders;
GO


/*
=============================================================
SECTION 11: NULL HANDLING, DATA MODIFICATION, MISC  (Tasks 99-105)
=============================================================
*/

-- Task 99: Replace NULL ShipAddress values with 'Address Not Provided'
-- using ISNULL.
SELECT OrderID, ISNULL(ShipAddress, 'Address Not Provided') AS ShipAddressClean
FROM Sales.Orders;
GO

-- Task 100: Use COALESCE to return the first non-null address available
-- (ShipAddress, then BillAddress, then a default string).
SELECT OrderID,
       COALESCE(ShipAddress, BillAddress, 'No Address on File') AS BestAddress
FROM Sales.Orders;
GO

-- Task 101: Count how many orders have a NULL ShipAddress vs. a
-- non-NULL ShipAddress.
SELECT
    SUM(CASE WHEN ShipAddress IS NULL THEN 1 ELSE 0 END) AS MissingShipAddress,
    SUM(CASE WHEN ShipAddress IS NOT NULL THEN 1 ELSE 0 END) AS HasShipAddress
FROM Sales.Orders;
GO

-- Task 102: Give all employees in the 'IT' department a 5% raise
-- (data modification with UPDATE).
UPDATE Sales.Employees
SET Salary = Salary * 1.05
WHERE Department = 'IT';
GO

-- Task 103: Insert a new customer record, then verify it was added.
INSERT INTO Sales.Customers (CustomerID, FirstName, LastName, Country, Score)
VALUES (151, 'Layla', 'Hassan', 'Egypt', 500);
GO

SELECT * FROM Sales.Customers WHERE CustomerID = 151;
GO

-- Task 104: Delete cancelled orders with zero Quantity from OrdersArchive
-- (safe cleanup example - review before running on production data).
DELETE FROM Sales.OrdersArchive
WHERE OrderStatus = 'Cancelled' AND Quantity = 0;
GO

-- Task 105: Create a view that exposes a simplified order summary
-- (OrderID, Customer, Product, SalesPerson, Sales) for reporting.
CREATE OR ALTER VIEW Sales.vw_OrderSummary AS
SELECT
    o.OrderID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    p.Product,
    e.FirstName + ' ' + e.LastName AS SalesPersonName,
    o.OrderDate,
    o.OrderStatus,
    o.Sales
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
INNER JOIN Sales.Products p ON o.ProductID = p.ProductID
INNER JOIN Sales.Employees e ON o.SalesPersonID = e.EmployeeID;
GO

SELECT * FROM Sales.vw_OrderSummary ORDER BY OrderDate;
GO

/*
=============================================================
END OF SCRIPT - 105 Intermediate Tasks & Solutions
=============================================================
*/