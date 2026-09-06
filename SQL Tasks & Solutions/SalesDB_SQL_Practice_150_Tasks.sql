/*
=====================================================================
 SalesDB - 150 SQL Practice Tasks & Solutions
 Aggregation | Subqueries | CTEs | Views | Indexes
 (Beginner -> Intermediate)
 T-SQL (Microsoft SQL Server) syntax
=====================================================================
*/


-- =====================================================================
-- PART 1 - AGGREGATION FUNCTIONS (Tasks 1-30)
-- =====================================================================

-- Task 1: Count the total number of customers.
SELECT COUNT(*) AS TotalCustomers
FROM Sales.Customers;

-- Task 2: Count the total number of orders.
SELECT COUNT(*) AS TotalOrders
FROM Sales.Orders;

-- Task 3: Find the total sales amount across all orders.
SELECT SUM(Sales) AS TotalSales
FROM Sales.Orders;

-- Task 4: Find the average price of all products.
SELECT AVG(Price) AS AvgPrice
FROM Sales.Products;

-- Task 5: Find the highest and lowest salary among employees.
SELECT MAX(Salary) AS MaxSalary, MIN(Salary) AS MinSalary
FROM Sales.Employees;

-- Task 6: Find the total quantity of products sold.
SELECT SUM(Quantity) AS TotalQuantity
FROM Sales.Orders;

-- Task 7: Count how many distinct countries customers come from.
SELECT COUNT(DISTINCT Country) AS DistinctCountries
FROM Sales.Customers;

-- Task 8: Find the average customer score, ignoring NULLs.
SELECT AVG(Score) AS AvgScore
FROM Sales.Customers
WHERE Score IS NOT NULL;

-- Task 9: Count how many products exist in each category.
SELECT Category, COUNT(*) AS ProductCount
FROM Sales.Products
GROUP BY Category;

-- Task 10: Find total sales amount per customer.
SELECT CustomerID, SUM(Sales) AS TotalSales
FROM Sales.Orders
GROUP BY CustomerID;

-- Task 11: Find the average order value per salesperson.
SELECT SalesPersonID, AVG(Sales) AS AvgSales
FROM Sales.Orders
GROUP BY SalesPersonID;

-- Task 12: Find the number of orders placed by each customer.
SELECT CustomerID, COUNT(*) AS OrderCount
FROM Sales.Orders
GROUP BY CustomerID;

-- Task 13: Find total salary paid per department.
SELECT Department, SUM(Salary) AS TotalSalary
FROM Sales.Employees
GROUP BY Department;

-- Task 14: Find the highest priced product in each category.
SELECT Category, MAX(Price) AS MaxPrice
FROM Sales.Products
GROUP BY Category;

-- Task 15: Find departments with more than 3 employees.
SELECT Department, COUNT(*) AS EmpCount
FROM Sales.Employees
GROUP BY Department
HAVING COUNT(*) > 3;

-- Task 16: Find customers who placed more than 2 orders.
SELECT CustomerID, COUNT(*) AS OrderCount
FROM Sales.Orders
GROUP BY CustomerID
HAVING COUNT(*) > 2;

-- Task 17: Find products whose average sale quantity per order exceeds 5.
SELECT ProductID, AVG(Quantity) AS AvgQty
FROM Sales.Orders
GROUP BY ProductID
HAVING AVG(Quantity) > 5;

-- Task 18: Find total sales by order status.
SELECT OrderStatus, SUM(Sales) AS TotalSales
FROM Sales.Orders
GROUP BY OrderStatus;

-- Task 19: Find total sales per year.
SELECT YEAR(OrderDate) AS OrderYear, SUM(Sales) AS TotalSales
FROM Sales.Orders
GROUP BY YEAR(OrderDate);

-- Task 20: Find total sales per year and month.
SELECT YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth, SUM(Sales) AS TotalSales
FROM Sales.Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;

-- Task 21: Find the total revenue generated per product (join Orders and Products).
SELECT p.Product, SUM(o.Sales) AS TotalRevenue
FROM Sales.Orders o
JOIN Sales.Products p ON o.ProductID = p.ProductID
GROUP BY p.Product;

-- Task 22: Find the total sales handled by each salesperson (join with Employees).
SELECT e.FirstName, e.LastName, SUM(o.Sales) AS TotalSales
FROM Sales.Orders o
JOIN Sales.Employees e ON o.SalesPersonID = e.EmployeeID
GROUP BY e.FirstName, e.LastName;

-- Task 23: Find the number of orders and total spend per country.
SELECT c.Country, COUNT(o.OrderID) AS OrderCount, SUM(o.Sales) AS TotalSpend
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
GROUP BY c.Country;

-- Task 24: Find the average salary per department, excluding NULL managers.
SELECT Department, AVG(Salary) AS AvgSalary
FROM Sales.Employees
WHERE ManagerID IS NOT NULL
GROUP BY Department;

-- Task 25: Find the total, minimum, maximum and average sales in a single query.
SELECT
    SUM(Sales) AS TotalSales,
    MIN(Sales) AS MinSale,
    MAX(Sales) AS MaxSale,
    AVG(Sales) AS AvgSale
FROM Sales.Orders;

-- Task 26: Find the percentage contribution of each category to total product price sum.
SELECT
    Category,
    SUM(Price) AS CategoryTotal,
    SUM(Price) * 100.0 / SUM(SUM(Price)) OVER () AS PctOfTotal
FROM Sales.Products
GROUP BY Category;

-- Task 27: Find the top 3 customers by total sales using aggregation and TOP.
SELECT TOP 3 CustomerID, SUM(Sales) AS TotalSales
FROM Sales.Orders
GROUP BY CustomerID
ORDER BY TotalSales DESC;

-- Task 28: Find categories where total product price exceeds 1000.
SELECT Category, SUM(Price) AS TotalPrice
FROM Sales.Products
GROUP BY Category
HAVING SUM(Price) > 1000;

-- Task 29: Compare current Orders table totals with OrdersArchive totals.
SELECT 'Orders' AS SourceTable, SUM(Sales) AS TotalSales FROM Sales.Orders
UNION ALL
SELECT 'OrdersArchive', SUM(Sales) FROM Sales.OrdersArchive;

-- Task 30: Find the running total of sales ordered by OrderDate (window aggregation).
SELECT
    OrderID,
    OrderDate,
    Sales,
    SUM(Sales) OVER (ORDER BY OrderDate ROWS UNBOUNDED PRECEDING) AS RunningTotal
FROM Sales.Orders;

-- =====================================================================
-- PART 2 - SUBQUERIES (Tasks 31-60)
-- =====================================================================

-- Task 31: Find products priced above the average product price.
SELECT *
FROM Sales.Products
WHERE Price > (SELECT AVG(Price) FROM Sales.Products);

-- Task 32: Find the customer(s) with the highest score.
SELECT *
FROM Sales.Customers
WHERE Score = (SELECT MAX(Score) FROM Sales.Customers);

-- Task 33: Find employees who earn more than the average salary.
SELECT *
FROM Sales.Employees
WHERE Salary > (SELECT AVG(Salary) FROM Sales.Employees);

-- Task 34: Find orders placed by customers from 'Germany' using a subquery.
SELECT *
FROM Sales.Orders
WHERE CustomerID IN (
    SELECT CustomerID FROM Sales.Customers WHERE Country = 'Germany'
);

-- Task 35: Find products that have never been ordered.
SELECT *
FROM Sales.Products
WHERE ProductID NOT IN (
    SELECT ProductID FROM Sales.Orders WHERE ProductID IS NOT NULL
);

-- Task 36: Find customers who have placed at least one order (using EXISTS).
SELECT *
FROM Sales.Customers c
WHERE EXISTS (
    SELECT 1 FROM Sales.Orders o WHERE o.CustomerID = c.CustomerID
);

-- Task 37: Find customers who have never placed an order (using NOT EXISTS).
SELECT *
FROM Sales.Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Sales.Orders o WHERE o.CustomerID = c.CustomerID
);

-- Task 38: Find the employee(s) with the second highest salary.
SELECT *
FROM Sales.Employees
WHERE Salary = (
    SELECT MAX(Salary)
    FROM Sales.Employees
    WHERE Salary < (SELECT MAX(Salary) FROM Sales.Employees)
);

-- Task 39: Find orders whose sales amount exceeds the average sales amount of the same customer (correlated subquery).
SELECT o.*
FROM Sales.Orders o
WHERE o.Sales > (
    SELECT AVG(o2.Sales)
    FROM Sales.Orders o2
    WHERE o2.CustomerID = o.CustomerID
);

-- Task 40: Find each customer's most recent order using a correlated subquery.
SELECT o.*
FROM Sales.Orders o
WHERE o.OrderDate = (
    SELECT MAX(o2.OrderDate)
    FROM Sales.Orders o2
    WHERE o2.CustomerID = o.CustomerID
);

-- Task 41: Find products priced higher than the cheapest product in the 'Bikes' category.
SELECT *
FROM Sales.Products
WHERE Price > (
    SELECT MIN(Price) FROM Sales.Products WHERE Category = 'Bikes'
);

-- Task 42: List employees who manage at least one other employee (subquery on self-join concept).
SELECT *
FROM Sales.Employees e
WHERE e.EmployeeID IN (
    SELECT DISTINCT ManagerID FROM Sales.Employees WHERE ManagerID IS NOT NULL
);

-- Task 43: Find the total sales for each order compared to the overall average, flagged as Above/Below.
SELECT
    OrderID,
    Sales,
    CASE WHEN Sales > (SELECT AVG(Sales) FROM Sales.Orders)
         THEN 'Above Average' ELSE 'Below Average' END AS SalesFlag
FROM Sales.Orders;

-- Task 44: Find customers whose total order sales exceed 1000 (subquery in FROM / derived table).
SELECT CustomerID, TotalSales
FROM (
    SELECT CustomerID, SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
) AS CustomerTotals
WHERE TotalSales > 1000;

-- Task 45: Find each product's price rank within its category using a subquery.
SELECT
    p.ProductID,
    p.Product,
    p.Category,
    p.Price,
    (SELECT COUNT(*) FROM Sales.Products p2
     WHERE p2.Category = p.Category AND p2.Price > p.Price) + 1 AS PriceRank
FROM Sales.Products p
ORDER BY p.Category, PriceRank;

-- Task 46: Find the salesperson with the highest total sales (nested subquery).
SELECT SalesPersonID
FROM Sales.Orders
GROUP BY SalesPersonID
HAVING SUM(Sales) = (
    SELECT MAX(TotalSales)
    FROM (
        SELECT SUM(Sales) AS TotalSales
        FROM Sales.Orders
        GROUP BY SalesPersonID
    ) AS T
);

-- Task 47: Find orders where the quantity is greater than the average quantity for that product.
SELECT o.*
FROM Sales.Orders o
WHERE o.Quantity > (
    SELECT AVG(o2.Quantity)
    FROM Sales.Orders o2
    WHERE o2.ProductID = o.ProductID
);

-- Task 48: Find customers who scored above the average score of customers in their own country.
SELECT *
FROM Sales.Customers c
WHERE c.Score > (
    SELECT AVG(c2.Score)
    FROM Sales.Customers c2
    WHERE c2.Country = c.Country
);

-- Task 49: Find employees who earn more than their manager (self-referencing subquery).
SELECT e.*
FROM Sales.Employees e
WHERE e.Salary > (
    SELECT m.Salary FROM Sales.Employees m WHERE m.EmployeeID = e.ManagerID
);

-- Task 50: Find the products that make up the top 20% by price (subquery with COUNT).
SELECT *
FROM Sales.Products
WHERE Price >= (
    SELECT MAX(Price) FROM (
        SELECT TOP 20 PERCENT Price
        FROM Sales.Products
        ORDER BY Price ASC
    ) AS Bottom80
);

-- Task 51: List orders shipped later than the average ship delay (ShipDate - OrderDate).
SELECT *
FROM Sales.Orders o
WHERE DATEDIFF(DAY, o.OrderDate, o.ShipDate) > (
    SELECT AVG(DATEDIFF(DAY, OrderDate, ShipDate)) FROM Sales.Orders
);

-- Task 52: Find customers who have placed more orders than the average number of orders per customer.
SELECT CustomerID, COUNT(*) AS OrderCount
FROM Sales.Orders
GROUP BY CustomerID
HAVING COUNT(*) > (
    SELECT AVG(OrderCount) FROM (
        SELECT COUNT(*) AS OrderCount FROM Sales.Orders GROUP BY CustomerID
    ) AS T
);

-- Task 53: Find the product(s) that generated the maximum total revenue (subquery + aggregation).
SELECT ProductID, SUM(Sales) AS TotalRevenue
FROM Sales.Orders
GROUP BY ProductID
HAVING SUM(Sales) = (
    SELECT MAX(Rev) FROM (
        SELECT SUM(Sales) AS Rev FROM Sales.Orders GROUP BY ProductID
    ) AS T
);

-- Task 54: Find orders placed on the same date as the very first order ever placed.
SELECT *
FROM Sales.Orders
WHERE OrderDate = (SELECT MIN(OrderDate) FROM Sales.Orders);

-- Task 55: Find customers who exist in both Orders and Customers but whose country info is missing (subquery with LEFT JOIN alternative).
SELECT DISTINCT o.CustomerID
FROM Sales.Orders o
WHERE o.CustomerID IN (
    SELECT CustomerID FROM Sales.Customers WHERE Country IS NULL
);

-- Task 56: Find employees whose department has the highest average salary (nested subquery).
SELECT *
FROM Sales.Employees
WHERE Department = (
    SELECT TOP 1 Department
    FROM Sales.Employees
    GROUP BY Department
    ORDER BY AVG(Salary) DESC
);

-- Task 57: Find orders whose Sales value is an outlier (more than double the product's average sales).
SELECT o.*
FROM Sales.Orders o
WHERE o.Sales > 2 * (
    SELECT AVG(o2.Sales) FROM Sales.Orders o2 WHERE o2.ProductID = o.ProductID
);

-- Task 58: Use a scalar subquery in SELECT to show each order's percentage of total sales.
SELECT
    OrderID,
    Sales,
    CAST(Sales * 100.0 / (SELECT SUM(Sales) FROM Sales.Orders) AS DECIMAL(5,2)) AS PctOfTotalSales
FROM Sales.Orders;

-- Task 59: Find customers whose CustomerID also appears as a SalesPersonID (subquery with INTERSECT logic).
SELECT *
FROM Sales.Customers
WHERE CustomerID IN (
    SELECT SalesPersonID FROM Sales.Orders WHERE SalesPersonID IS NOT NULL
);

-- Task 60: Find archived orders that no longer exist in the live Orders table (subquery with NOT IN).
SELECT *
FROM Sales.OrdersArchive a
WHERE a.OrderID NOT IN (
    SELECT OrderID FROM Sales.Orders WHERE OrderID IS NOT NULL
);

-- =====================================================================
-- PART 3 - CTEs (COMMON TABLE EXPRESSIONS) (Tasks 61-90)
-- =====================================================================

-- Task 61: Use a CTE to list all orders with sales above 500.
WITH HighValueOrders AS (
    SELECT * FROM Sales.Orders WHERE Sales > 500
)
SELECT * FROM HighValueOrders;

-- Task 62: Use a CTE to calculate total sales per customer.
WITH CustomerSales AS (
    SELECT CustomerID, SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
)
SELECT * FROM CustomerSales
ORDER BY TotalSales DESC;

-- Task 63: Use a CTE to find customers with above-average total sales.
WITH CustomerSales AS (
    SELECT CustomerID, SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
)
SELECT *
FROM CustomerSales
WHERE TotalSales > (SELECT AVG(TotalSales) FROM CustomerSales);

-- Task 64: Use a CTE to rank products by price within each category.
WITH RankedProducts AS (
    SELECT
        ProductID, Product, Category, Price,
        RANK() OVER (PARTITION BY Category ORDER BY Price DESC) AS PriceRank
    FROM Sales.Products
)
SELECT * FROM RankedProducts WHERE PriceRank = 1;

-- Task 65: Use a CTE to combine Orders and OrdersArchive into one dataset.
WITH AllOrders AS (
    SELECT *, 'Current' AS Source FROM Sales.Orders
    UNION ALL
    SELECT *, 'Archive' AS Source FROM Sales.OrdersArchive
)
SELECT * FROM AllOrders;

-- Task 66: Use a CTE to find the top 5 customers by number of orders.
WITH CustomerOrderCounts AS (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM Sales.Orders
    GROUP BY CustomerID
)
SELECT TOP 5 * FROM CustomerOrderCounts
ORDER BY OrderCount DESC;

-- Task 67: Use a CTE to calculate each employee's salary as a percentage of department total.
WITH DeptTotals AS (
    SELECT Department, SUM(Salary) AS DeptSalary
    FROM Sales.Employees
    GROUP BY Department
)
SELECT
    e.EmployeeID, e.FirstName, e.LastName, e.Department, e.Salary,
    CAST(e.Salary * 100.0 / d.DeptSalary AS DECIMAL(5,2)) AS PctOfDept
FROM Sales.Employees e
JOIN DeptTotals d ON e.Department = d.Department;

-- Task 68: Use multiple CTEs to compare product revenue vs. average category revenue.
WITH ProductRevenue AS (
    SELECT p.ProductID, p.Category, SUM(o.Sales) AS Revenue
    FROM Sales.Products p
    JOIN Sales.Orders o ON p.ProductID = o.ProductID
    GROUP BY p.ProductID, p.Category
),
CategoryAvg AS (
    SELECT Category, AVG(Revenue) AS AvgCategoryRevenue
    FROM ProductRevenue
    GROUP BY Category
)
SELECT pr.ProductID, pr.Category, pr.Revenue, ca.AvgCategoryRevenue
FROM ProductRevenue pr
JOIN CategoryAvg ca ON pr.Category = ca.Category
WHERE pr.Revenue > ca.AvgCategoryRevenue;

-- Task 69: Use a recursive CTE to build the employee-manager hierarchy.
WITH EmpHierarchy AS (
    SELECT EmployeeID, FirstName, LastName, ManagerID, 0 AS HierarchyLevel
    FROM Sales.Employees
    WHERE ManagerID IS NULL

    UNION ALL

    SELECT e.EmployeeID, e.FirstName, e.LastName, e.ManagerID, h.HierarchyLevel + 1
    FROM Sales.Employees e
    JOIN EmpHierarchy h ON e.ManagerID = h.EmployeeID
)
SELECT * FROM EmpHierarchy
ORDER BY HierarchyLevel, EmployeeID;

-- Task 70: Use a recursive CTE to find all direct and indirect reports of a specific manager (e.g. EmployeeID = 1).
WITH Reports AS (
    SELECT EmployeeID, FirstName, LastName, ManagerID
    FROM Sales.Employees
    WHERE ManagerID = 1

    UNION ALL

    SELECT e.EmployeeID, e.FirstName, e.LastName, e.ManagerID
    FROM Sales.Employees e
    JOIN Reports r ON e.ManagerID = r.EmployeeID
)
SELECT * FROM Reports;

-- Task 71: Use a recursive CTE to generate a calendar/date series covering all order dates.
WITH DateRange AS (
    SELECT MIN(OrderDate) AS OrderDate FROM Sales.Orders
    UNION ALL
    SELECT DATEADD(DAY, 1, OrderDate)
    FROM DateRange
    WHERE OrderDate < (SELECT MAX(OrderDate) FROM Sales.Orders)
)
SELECT * FROM DateRange
OPTION (MAXRECURSION 0);

-- Task 72: Use a CTE to find the running total of sales per customer ordered by date.
WITH CustomerRunning AS (
    SELECT
        CustomerID, OrderID, OrderDate, Sales,
        SUM(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate
                          ROWS UNBOUNDED PRECEDING) AS RunningTotal
    FROM Sales.Orders
)
SELECT * FROM CustomerRunning
ORDER BY CustomerID, OrderDate;

-- Task 73: Use a CTE to identify duplicate orders (same customer, product, date).
WITH DupCheck AS (
    SELECT
        OrderID, CustomerID, ProductID, OrderDate,
        ROW_NUMBER() OVER (PARTITION BY CustomerID, ProductID, OrderDate
                            ORDER BY OrderID) AS RowNum
    FROM Sales.Orders
)
SELECT * FROM DupCheck WHERE RowNum > 1;

-- Task 74: Use a CTE to calculate month-over-month sales growth.
WITH MonthlySales AS (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT
    OrderYear, OrderMonth, TotalSales,
    TotalSales - LAG(TotalSales) OVER (ORDER BY OrderYear, OrderMonth) AS MoMChange
FROM MonthlySales;

-- Task 75: Use a CTE to find each customer's first and last order date.
WITH CustomerDates AS (
    SELECT CustomerID, MIN(OrderDate) AS FirstOrder, MAX(OrderDate) AS LastOrder
    FROM Sales.Orders
    GROUP BY CustomerID
)
SELECT * FROM CustomerDates;

-- Task 76: Use a CTE to classify customers into Gold/Silver/Bronze tiers by total sales.
WITH CustomerSales AS (
    SELECT CustomerID, SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
)
SELECT
    CustomerID, TotalSales,
    CASE
        WHEN TotalSales >= 5000 THEN 'Gold'
        WHEN TotalSales >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS Tier
FROM CustomerSales;

-- Task 77: Use a CTE to find products never purchased by combining Products with Orders.
WITH OrderedProducts AS (
    SELECT DISTINCT ProductID FROM Sales.Orders WHERE ProductID IS NOT NULL
)
SELECT p.*
FROM Sales.Products p
LEFT JOIN OrderedProducts op ON p.ProductID = op.ProductID
WHERE op.ProductID IS NULL;

-- Task 78: Use a CTE with window functions to find each product's rank by total quantity sold.
WITH ProductQty AS (
    SELECT ProductID, SUM(Quantity) AS TotalQty
    FROM Sales.Orders
    GROUP BY ProductID
)
SELECT
    ProductID, TotalQty,
    DENSE_RANK() OVER (ORDER BY TotalQty DESC) AS QtyRank
FROM ProductQty;

-- Task 79: Use a CTE to find the average shipping delay per order status.
WITH ShipDelays AS (
    SELECT OrderID, OrderStatus, DATEDIFF(DAY, OrderDate, ShipDate) AS DelayDays
    FROM Sales.Orders
    WHERE ShipDate IS NOT NULL
)
SELECT OrderStatus, AVG(DelayDays) AS AvgDelay
FROM ShipDelays
GROUP BY OrderStatus;

-- Task 80: Use a CTE to calculate each employee's tenure in years from BirthDate (age) and flag senior employees.
WITH EmployeeAge AS (
    SELECT
        EmployeeID, FirstName, LastName,
        DATEDIFF(YEAR, BirthDate, GETDATE()) AS Age
    FROM Sales.Employees
)
SELECT *, CASE WHEN Age >= 50 THEN 'Senior' ELSE 'Regular' END AS AgeGroup
FROM EmployeeAge;

-- Task 81: Use a CTE to deduplicate the OrdersArchive table keeping only the latest CreationTime per OrderID.
WITH RankedArchive AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY CreationTime DESC) AS rn
    FROM Sales.OrdersArchive
)
SELECT * FROM RankedArchive WHERE rn = 1;

-- Task 82: Use a CTE to find customers whose orders span more than 2 different countries via ShipAddress vs BillAddress mismatch.
WITH MismatchOrders AS (
    SELECT CustomerID, OrderID, ShipAddress, BillAddress
    FROM Sales.Orders
    WHERE ShipAddress <> BillAddress
)
SELECT CustomerID, COUNT(*) AS MismatchCount
FROM MismatchOrders
GROUP BY CustomerID;

-- Task 83: Use a CTE to compute cumulative distribution of employees by salary.
WITH SalaryDist AS (
    SELECT
        EmployeeID, Salary,
        CUME_DIST() OVER (ORDER BY Salary) AS CumDist
    FROM Sales.Employees
)
SELECT * FROM SalaryDist ORDER BY Salary;

-- Task 84: Use a CTE to compare each order's sales to the previous order for the same customer.
WITH CustomerOrders AS (
    SELECT
        CustomerID, OrderID, OrderDate, Sales,
        LAG(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS PrevSales
    FROM Sales.Orders
)
SELECT *, Sales - PrevSales AS SalesDiff
FROM CustomerOrders;

-- Task 85: Use a CTE to find the median product price per category (approx, using PERCENTILE_CONT).
WITH PriceMedian AS (
    SELECT DISTINCT
        Category,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Price) OVER (PARTITION BY Category) AS MedianPrice
    FROM Sales.Products
)
SELECT * FROM PriceMedian;

-- Task 86: Use a CTE to build a hierarchy path string for each employee (recursive with concatenation).
WITH EmpPath AS (
    SELECT EmployeeID, FirstName, ManagerID,
           CAST(FirstName AS VARCHAR(400)) AS PathName
    FROM Sales.Employees
    WHERE ManagerID IS NULL

    UNION ALL

    SELECT e.EmployeeID, e.FirstName, e.ManagerID,
           CAST(p.PathName + ' > ' + e.FirstName AS VARCHAR(400))
    FROM Sales.Employees e
    JOIN EmpPath p ON e.ManagerID = p.EmployeeID
)
SELECT * FROM EmpPath;

-- Task 87: Use a CTE to find the top-selling product per year.
WITH YearlyProductSales AS (
    SELECT
        YEAR(OrderDate) AS OrderYear, ProductID, SUM(Sales) AS TotalSales,
        RANK() OVER (PARTITION BY YEAR(OrderDate) ORDER BY SUM(Sales) DESC) AS SalesRank
    FROM Sales.Orders
    GROUP BY YEAR(OrderDate), ProductID
)
SELECT * FROM YearlyProductSales WHERE SalesRank = 1;

-- Task 88: Use a CTE to identify customers with declining sales trend (last order less than first order).
WITH FirstLast AS (
    SELECT
        CustomerID,
        FIRST_VALUE(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS FirstSale,
        LAST_VALUE(Sales) OVER (PARTITION BY CustomerID ORDER BY OrderDate
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastSale
    FROM Sales.Orders
)
SELECT DISTINCT CustomerID, FirstSale, LastSale
FROM FirstLast
WHERE LastSale < FirstSale;

-- Task 89: Use a CTE to summarize orders by quarter.
WITH QuarterlySales AS (
    SELECT
        YEAR(OrderDate) AS OrderYear,
        DATEPART(QUARTER, OrderDate) AS OrderQuarter,
        SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY YEAR(OrderDate), DATEPART(QUARTER, OrderDate)
)
SELECT * FROM QuarterlySales
ORDER BY OrderYear, OrderQuarter;

-- Task 90: Use a CTE combined with EXISTS to find employees who are also acting as salespeople with orders.
WITH ActingSales AS (
    SELECT DISTINCT SalesPersonID FROM Sales.Orders WHERE SalesPersonID IS NOT NULL
)
SELECT e.*
FROM Sales.Employees e
WHERE EXISTS (SELECT 1 FROM ActingSales a WHERE a.SalesPersonID = e.EmployeeID);

-- =====================================================================
-- PART 4 - VIEWS (Tasks 91-120)
-- =====================================================================

-- Task 91: Create a view listing all customers from Germany.
CREATE VIEW Sales.vw_GermanCustomers AS
SELECT * FROM Sales.Customers WHERE Country = 'Germany';
GO
SELECT * FROM Sales.vw_GermanCustomers;

-- Task 92: Create a view showing total sales per customer.
CREATE VIEW Sales.vw_CustomerTotalSales AS
SELECT CustomerID, SUM(Sales) AS TotalSales
FROM Sales.Orders
GROUP BY CustomerID;
GO
SELECT * FROM Sales.vw_CustomerTotalSales;

-- Task 93: Create a view showing order details joined with customer and product names.
CREATE VIEW Sales.vw_OrderDetails AS
SELECT
    o.OrderID, c.FirstName + ' ' + c.LastName AS CustomerName,
    p.Product, o.Quantity, o.Sales, o.OrderDate
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
JOIN Sales.Products p ON o.ProductID = p.ProductID;
GO
SELECT * FROM Sales.vw_OrderDetails;

-- Task 94: Create a view showing employee details with department salary averages.
CREATE VIEW Sales.vw_EmployeeDeptAvg AS
SELECT
    e.EmployeeID, e.FirstName, e.LastName, e.Department, e.Salary,
    AVG(e.Salary) OVER (PARTITION BY e.Department) AS DeptAvgSalary
FROM Sales.Employees e;
GO
SELECT * FROM Sales.vw_EmployeeDeptAvg;

-- Task 95: Create a view showing products priced above the overall average price.
CREATE VIEW Sales.vw_AboveAvgProducts AS
SELECT *
FROM Sales.Products
WHERE Price > (SELECT AVG(Price) FROM Sales.Products);
GO
SELECT * FROM Sales.vw_AboveAvgProducts;

-- Task 96: Create a view combining Orders and OrdersArchive.
CREATE VIEW Sales.vw_AllOrders AS
SELECT *, 'Current' AS SourceTable FROM Sales.Orders
UNION ALL
SELECT *, 'Archive' AS SourceTable FROM Sales.OrdersArchive;
GO
SELECT * FROM Sales.vw_AllOrders;

-- Task 97: Create a view for monthly sales summary.
CREATE VIEW Sales.vw_MonthlySales AS
SELECT
    YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth,
    SUM(Sales) AS TotalSales, COUNT(*) AS OrderCount
FROM Sales.Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate);
GO
SELECT * FROM Sales.vw_MonthlySales;

-- Task 98: Create a view showing customers who have never placed an order.
CREATE VIEW Sales.vw_InactiveCustomers AS
SELECT c.*
FROM Sales.Customers c
WHERE NOT EXISTS (SELECT 1 FROM Sales.Orders o WHERE o.CustomerID = c.CustomerID);
GO
SELECT * FROM Sales.vw_InactiveCustomers;

-- Task 99: Create a view for the employee management hierarchy.
CREATE VIEW Sales.vw_EmployeeHierarchy AS
WITH EmpHierarchy AS (
    SELECT EmployeeID, FirstName, LastName, ManagerID, 0 AS HierarchyLevel
    FROM Sales.Employees WHERE ManagerID IS NULL
    UNION ALL
    SELECT e.EmployeeID, e.FirstName, e.LastName, e.ManagerID, h.HierarchyLevel + 1
    FROM Sales.Employees e
    JOIN EmpHierarchy h ON e.ManagerID = h.EmployeeID
)
SELECT * FROM EmpHierarchy;
GO
SELECT * FROM Sales.vw_EmployeeHierarchy;

-- Task 100: Create a view showing top 10 orders by sales value.
CREATE VIEW Sales.vw_Top10Orders AS
SELECT TOP 10 * FROM Sales.Orders ORDER BY Sales DESC;
GO
SELECT * FROM Sales.vw_Top10Orders;

-- Task 101: Create a view showing product category revenue contribution percentages.
CREATE VIEW Sales.vw_CategoryRevenueShare AS
SELECT
    p.Category, SUM(o.Sales) AS CategoryRevenue,
    SUM(o.Sales) * 100.0 / SUM(SUM(o.Sales)) OVER () AS RevenueSharePct
FROM Sales.Orders o
JOIN Sales.Products p ON o.ProductID = p.ProductID
GROUP BY p.Category;
GO
SELECT * FROM Sales.vw_CategoryRevenueShare;

-- Task 102: Create a view showing each customer's order frequency and average order size.
CREATE VIEW Sales.vw_CustomerBehavior AS
SELECT
    CustomerID, COUNT(*) AS OrderCount,
    AVG(Sales) AS AvgOrderValue, SUM(Sales) AS TotalSpend
FROM Sales.Orders
GROUP BY CustomerID;
GO
SELECT * FROM Sales.vw_CustomerBehavior;

-- Task 103: Create a view showing late shipments (ShipDate more than 5 days after OrderDate).
CREATE VIEW Sales.vw_LateShipments AS
SELECT *, DATEDIFF(DAY, OrderDate, ShipDate) AS DelayDays
FROM Sales.Orders
WHERE DATEDIFF(DAY, OrderDate, ShipDate) > 5;
GO
SELECT * FROM Sales.vw_LateShipments;

-- Task 104: Create a view showing salesperson performance rankings.
CREATE VIEW Sales.vw_SalesPersonRanking AS
SELECT
    SalesPersonID, SUM(Sales) AS TotalSales,
    RANK() OVER (ORDER BY SUM(Sales) DESC) AS SalesRank
FROM Sales.Orders
WHERE SalesPersonID IS NOT NULL
GROUP BY SalesPersonID;
GO
SELECT * FROM Sales.vw_SalesPersonRanking;

-- Task 105: Alter an existing view to add a new column (email placeholder for future use).
ALTER VIEW Sales.vw_GermanCustomers AS
SELECT CustomerID, FirstName, LastName, Country, Score,
       LOWER(FirstName + '.' + LastName + '@example.com') AS EmailGuess
FROM Sales.Customers
WHERE Country = 'Germany';
GO
SELECT * FROM Sales.vw_GermanCustomers;

-- Task 106: Create a view showing products never ordered (unsold inventory).
CREATE VIEW Sales.vw_UnsoldProducts AS
SELECT p.*
FROM Sales.Products p
LEFT JOIN Sales.Orders o ON p.ProductID = o.ProductID
WHERE o.OrderID IS NULL;
GO
SELECT * FROM Sales.vw_UnsoldProducts;

-- Task 107: Create a view showing employee age and years to retirement (assuming retirement at 65).
CREATE VIEW Sales.vw_EmployeeRetirement AS
SELECT
    EmployeeID, FirstName, LastName,
    DATEDIFF(YEAR, BirthDate, GETDATE()) AS Age,
    65 - DATEDIFF(YEAR, BirthDate, GETDATE()) AS YearsToRetirement
FROM Sales.Employees;
GO
SELECT * FROM Sales.vw_EmployeeRetirement;

-- Task 108: Create a view for order status distribution with percentages.
CREATE VIEW Sales.vw_OrderStatusDistribution AS
SELECT
    OrderStatus, COUNT(*) AS StatusCount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS StatusPct
FROM Sales.Orders
GROUP BY OrderStatus;
GO
SELECT * FROM Sales.vw_OrderStatusDistribution;

-- Task 109: Create a view showing high-value customers (score > 80) with their order totals.
CREATE VIEW Sales.vw_HighValueCustomers AS
SELECT c.CustomerID, c.FirstName, c.LastName, c.Score, SUM(o.Sales) AS TotalSales
FROM Sales.Customers c
JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
WHERE c.Score > 80
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Score;
GO
SELECT * FROM Sales.vw_HighValueCustomers;

-- Task 110: Query a view with an additional WHERE clause (view composability).
SELECT * FROM Sales.vw_CustomerTotalSales WHERE TotalSales > 2000;

-- Task 111: Create a view that flags duplicate orders in OrdersArchive.
CREATE VIEW Sales.vw_DuplicateArchiveOrders AS
SELECT OrderID, COUNT(*) AS DuplicateCount
FROM Sales.OrdersArchive
GROUP BY OrderID
HAVING COUNT(*) > 1;
GO
SELECT * FROM Sales.vw_DuplicateArchiveOrders;

-- Task 112: Create a view showing each product's rank by revenue within its category.
CREATE VIEW Sales.vw_ProductCategoryRank AS
SELECT
    p.ProductID, p.Product, p.Category, SUM(o.Sales) AS Revenue,
    RANK() OVER (PARTITION BY p.Category ORDER BY SUM(o.Sales) DESC) AS CategoryRank
FROM Sales.Products p
JOIN Sales.Orders o ON p.ProductID = o.ProductID
GROUP BY p.ProductID, p.Product, p.Category;
GO
SELECT * FROM Sales.vw_ProductCategoryRank;

-- Task 113: Create a view showing gender distribution and average salary per department.
CREATE VIEW Sales.vw_DeptGenderSalary AS
SELECT
    Department, Gender, COUNT(*) AS EmpCount, AVG(Salary) AS AvgSalary
FROM Sales.Employees
GROUP BY Department, Gender;
GO
SELECT * FROM Sales.vw_DeptGenderSalary;

-- Task 114: Drop a view that is no longer needed.
DROP VIEW IF EXISTS Sales.vw_DuplicateArchiveOrders;

-- Task 115: Create a view listing customers with mismatched shipping and billing addresses in their orders.
CREATE VIEW Sales.vw_AddressMismatch AS
SELECT DISTINCT o.CustomerID, o.OrderID, o.ShipAddress, o.BillAddress
FROM Sales.Orders o
WHERE o.ShipAddress <> o.BillAddress;
GO
SELECT * FROM Sales.vw_AddressMismatch;

-- Task 116: Create a view showing quarterly revenue trends.
CREATE VIEW Sales.vw_QuarterlyRevenue AS
SELECT
    YEAR(OrderDate) AS OrderYear, DATEPART(QUARTER, OrderDate) AS OrderQuarter,
    SUM(Sales) AS TotalRevenue
FROM Sales.Orders
GROUP BY YEAR(OrderDate), DATEPART(QUARTER, OrderDate);
GO
SELECT * FROM Sales.vw_QuarterlyRevenue;

-- Task 117: Create a view exposing only non-sensitive employee columns (excluding Salary).
CREATE VIEW Sales.vw_EmployeeDirectory AS
SELECT EmployeeID, FirstName, LastName, Department, Gender
FROM Sales.Employees;
GO
SELECT * FROM Sales.vw_EmployeeDirectory;

-- Task 118: Create a view showing the count of orders per salesperson per order status.
CREATE VIEW Sales.vw_SalesPersonStatusBreakdown AS
SELECT SalesPersonID, OrderStatus, COUNT(*) AS OrderCount
FROM Sales.Orders
GROUP BY SalesPersonID, OrderStatus;
GO
SELECT * FROM Sales.vw_SalesPersonStatusBreakdown;

-- Task 119: Create a view combining customer info with their tier classification.
CREATE VIEW Sales.vw_CustomerTiers AS
SELECT
    c.CustomerID, c.FirstName, c.LastName, ISNULL(SUM(o.Sales), 0) AS TotalSales,
    CASE
        WHEN ISNULL(SUM(o.Sales), 0) >= 5000 THEN 'Gold'
        WHEN ISNULL(SUM(o.Sales), 0) >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS Tier
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName;
GO
SELECT * FROM Sales.vw_CustomerTiers;

-- Task 120: Check metadata: list all views created in SalesDB.
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
ORDER BY TABLE_NAME;

-- =====================================================================
-- PART 5 - INDEXES (Tasks 121-150)
-- =====================================================================

-- Task 121: Create a non-clustered index on Orders.CustomerID to speed up customer lookups.
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID
ON Sales.Orders (CustomerID);

-- Task 122: Create a non-clustered index on Orders.ProductID.
CREATE NONCLUSTERED INDEX IX_Orders_ProductID
ON Sales.Orders (ProductID);

-- Task 123: Create a non-clustered index on Orders.OrderDate to speed up date-range filtering.
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate
ON Sales.Orders (OrderDate);

-- Task 124: Create a composite index on Orders (CustomerID, OrderDate) for common filter+sort queries.
CREATE NONCLUSTERED INDEX IX_Orders_Customer_OrderDate
ON Sales.Orders (CustomerID, OrderDate);

-- Task 125: Create a unique index on Customers to prevent duplicate (FirstName, LastName, Country) combinations.
CREATE UNIQUE NONCLUSTERED INDEX UX_Customers_Name_Country
ON Sales.Customers (FirstName, LastName, Country);

-- Task 126: Create an index on Products.Category to speed up category-based aggregation.
CREATE NONCLUSTERED INDEX IX_Products_Category
ON Sales.Products (Category);

-- Task 127: Create a covering index on Orders including Sales and Quantity for reporting queries.
CREATE NONCLUSTERED INDEX IX_Orders_Customer_Covering
ON Sales.Orders (CustomerID)
INCLUDE (Sales, Quantity, OrderDate);

-- Task 128: Create an index on Employees.Department for faster GROUP BY department queries.
CREATE NONCLUSTERED INDEX IX_Employees_Department
ON Sales.Employees (Department);

-- Task 129: Create a filtered index on Orders for only 'Shipped' orders.
CREATE NONCLUSTERED INDEX IX_Orders_Shipped
ON Sales.Orders (OrderDate)
WHERE OrderStatus = 'Shipped';

-- Task 130: Create a filtered index on Employees for active managers only (ManagerID IS NOT NULL).
CREATE NONCLUSTERED INDEX IX_Employees_HasManager
ON Sales.Employees (ManagerID)
WHERE ManagerID IS NOT NULL;

-- Task 131: Create an index on Orders.SalesPersonID for salesperson performance queries.
CREATE NONCLUSTERED INDEX IX_Orders_SalesPersonID
ON Sales.Orders (SalesPersonID);

-- Task 132: View all indexes currently defined on the Orders table.
SELECT
    i.name AS IndexName, i.type_desc AS IndexType, c.name AS ColumnName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('Sales.Orders')
ORDER BY i.name, ic.key_ordinal;

-- Task 133: Check index usage statistics for the Orders table.
SELECT
    OBJECT_NAME(s.object_id) AS TableName, i.name AS IndexName,
    s.user_seeks, s.user_scans, s.user_lookups, s.user_updates
FROM sys.dm_db_index_usage_stats s
JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.object_id = OBJECT_ID('Sales.Orders');

-- Task 134: Rebuild an index to reduce fragmentation.
ALTER INDEX IX_Orders_CustomerID ON Sales.Orders REBUILD;

-- Task 135: Reorganize an index (a lighter-weight alternative to rebuild).
ALTER INDEX IX_Orders_OrderDate ON Sales.Orders REORGANIZE;

-- Task 136: Check index fragmentation levels for the Orders table.
SELECT
    OBJECT_NAME(ips.object_id) AS TableName, i.name AS IndexName,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('Sales.Orders'), NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id;

-- Task 137: Drop an index that is no longer needed.
DROP INDEX IF EXISTS IX_Orders_Shipped ON Sales.Orders;

-- Task 138: Create an index to support a query filtering Customers by Score range.
CREATE NONCLUSTERED INDEX IX_Customers_Score
ON Sales.Customers (Score);

-- Task 139: Test the impact of an index: run a query with STATISTICS IO before and after creating an index.
SET STATISTICS IO ON;
SELECT * FROM Sales.Orders WHERE CustomerID = 5;
SET STATISTICS IO OFF;
-- Compare "logical reads" before/after CREATE INDEX IX_Orders_CustomerID

-- Task 140: Create a composite covering index for a report on sales by product and status.
CREATE NONCLUSTERED INDEX IX_Orders_Product_Status
ON Sales.Orders (ProductID, OrderStatus)
INCLUDE (Sales, Quantity);

-- Task 141: Create an index on Employees.BirthDate to speed up age-based queries.
CREATE NONCLUSTERED INDEX IX_Employees_BirthDate
ON Sales.Employees (BirthDate);

-- Task 142: Add a clustered index consideration: verify the Orders primary key is backed by a clustered index.
SELECT i.name, i.type_desc
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('Sales.Orders') AND i.is_primary_key = 1;
-- PK_Orders should show type_desc = 'CLUSTERED' by default

-- Task 143: Create a non-clustered index to support searching OrdersArchive by CustomerID (no PK exists there).
CREATE NONCLUSTERED INDEX IX_OrdersArchive_CustomerID
ON Sales.OrdersArchive (CustomerID);

-- Task 144: Create an index to enforce and speed up uniqueness checks on Products.Product name.
CREATE UNIQUE NONCLUSTERED INDEX UX_Products_Name
ON Sales.Products (Product);

-- Task 145: Use the execution plan to identify a missing index recommendation for a slow query.
-- Run this, then check SSMS "Missing Index" suggestion in the actual execution plan:
SELECT c.FirstName, c.LastName, SUM(o.Sales) AS TotalSales
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE o.OrderStatus = 'Delivered'
GROUP BY c.FirstName, c.LastName;

-- Task 146: Create an index on Orders.ShipDate for shipment-delay reporting.
CREATE NONCLUSTERED INDEX IX_Orders_ShipDate
ON Sales.Orders (ShipDate);

-- Task 147: Query system metadata to list all indexes across the entire SalesDB database.
SELECT
    t.name AS TableName, i.name AS IndexName, i.type_desc AS IndexType,
    i.is_unique, i.is_primary_key
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.name IS NOT NULL
ORDER BY t.name, i.name;

-- Task 148: Create an index designed to support a covering query for the customer sales summary view.
CREATE NONCLUSTERED INDEX IX_Orders_Customer_Sales_Covering
ON Sales.Orders (CustomerID)
INCLUDE (Sales);

-- Task 149: Estimate index storage size for the Orders table indexes.
SELECT
    i.name AS IndexName,
    SUM(ps.used_page_count) * 8 AS IndexSizeKB
FROM sys.dm_db_partition_stats ps
JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE ps.object_id = OBJECT_ID('Sales.Orders')
GROUP BY i.name;

-- Task 150: Disable an index temporarily (e.g., before a bulk load) and re-enable it afterward.
-- Disable
ALTER INDEX IX_Orders_CustomerID ON Sales.Orders DISABLE;

-- (bulk load happens here)

-- Re-enable (rebuild required after disable)
ALTER INDEX IX_Orders_CustomerID ON Sales.Orders REBUILD;