/*
=============================================================================
SalesDB — 50 Subquery Practice Tasks & Solutions (T-SQL / SQL Server)
=============================================================================
Purpose:
    50 hands-on tasks covering every major subquery type against the
    SalesDB schema (Sales.Customers, Sales.Employees, Sales.Products,
    Sales.Orders, Sales.OrdersArchive), each with its solution query.

Sections:
    A. Scalar Subqueries                       (Tasks 1-10)
    B. Multi-Row Subqueries: IN / NOT IN        (Tasks 11-18)
    C. Correlated Subqueries                    (Tasks 19-26)
    D. EXISTS / NOT EXISTS                       (Tasks 27-34)
    E. Subqueries in FROM (Derived Tables)       (Tasks 35-40)
    F. Subqueries in SELECT                      (Tasks 41-46)
    G. ANY / ALL / SOME                          (Tasks 47-50)

Run against the database created by init-sqlserver-salesdb.sql.
=============================================================================
*/

USE SalesDB;
GO


/* =============================================================================
   SECTION A — SCALAR SUBQUERIES
   A scalar subquery returns exactly one value (one row, one column) and can
   be used anywhere a single value is expected: SELECT list, WHERE, HAVING.
============================================================================= */

-- Task 1: Find all orders whose Sales amount is greater than the average
--         Sales amount across all orders.
SELECT OrderID, ProductID, CustomerID, Sales
FROM Sales.Orders
WHERE Sales > (SELECT AVG(Sales) FROM Sales.Orders);
GO

-- Task 2: Find the customer(s) with the highest Score.
SELECT CustomerID, FirstName, LastName, Score
FROM Sales.Customers
WHERE Score = (SELECT MAX(Score) FROM Sales.Customers);
GO

-- Task 3: Find the employee(s) with the lowest Salary.
SELECT EmployeeID, FirstName, LastName, Salary
FROM Sales.Employees
WHERE Salary = (SELECT MIN(Salary) FROM Sales.Employees);
GO

-- Task 4: Find products priced above the average product price.
SELECT ProductID, Product, Price
FROM Sales.Products
WHERE Price > (SELECT AVG(Price) FROM Sales.Products);
GO

-- Task 5: Show each order along with how far its Sales value is from the
--         overall average Sales (a scalar subquery in the SELECT list).
SELECT
    OrderID,
    Sales,
    (SELECT AVG(Sales) FROM Sales.Orders)              AS AvgSales,
    Sales - (SELECT AVG(Sales) FROM Sales.Orders)      AS DiffFromAvg
FROM Sales.Orders;
GO

-- Task 6: Find the order with the earliest OrderDate.
SELECT OrderID, CustomerID, OrderDate
FROM Sales.Orders
WHERE OrderDate = (SELECT MIN(OrderDate) FROM Sales.Orders);
GO

-- Task 7: Find the order with the latest ShipDate.
SELECT OrderID, CustomerID, ShipDate
FROM Sales.Orders
WHERE ShipDate = (SELECT MAX(ShipDate) FROM Sales.Orders);
GO

-- Task 8: Find the youngest employee (latest BirthDate).
SELECT EmployeeID, FirstName, LastName, BirthDate
FROM Sales.Employees
WHERE BirthDate = (SELECT MAX(BirthDate) FROM Sales.Employees);
GO

-- Task 9: Find the number of orders that were placed above the median-ish
--         midpoint: orders whose Sales exceed half of the total Sales sum
--         divided by the order count (i.e., above-average, computed
--         explicitly via nested scalar subqueries).
SELECT COUNT(*) AS OrdersAboveAverage
FROM Sales.Orders
WHERE Sales > (
    SELECT SUM(Sales) * 1.0 / COUNT(*)
    FROM Sales.Orders
);
GO

-- Task 10: Find the most expensive product and show how much cheaper every
--          other product is compared to it.
SELECT
    ProductID,
    Product,
    Price,
    (SELECT MAX(Price) FROM Sales.Products) - Price AS PriceGapFromTop
FROM Sales.Products;
GO


/* =============================================================================
   SECTION B — MULTI-ROW SUBQUERIES (IN / NOT IN)
   These subqueries return a list of values compared against with IN/NOT IN.
============================================================================= */

-- Task 11: Find all customers who have placed at least one order.
SELECT CustomerID, FirstName, LastName
FROM Sales.Customers
WHERE CustomerID IN (SELECT CustomerID FROM Sales.Orders);
GO

-- Task 12: Find all customers who have NEVER placed an order.
SELECT CustomerID, FirstName, LastName
FROM Sales.Customers
WHERE CustomerID NOT IN (
    SELECT CustomerID FROM Sales.Orders WHERE CustomerID IS NOT NULL
);
GO

-- Task 13: Find all products that have never been ordered.
SELECT ProductID, Product
FROM Sales.Products
WHERE ProductID NOT IN (
    SELECT ProductID FROM Sales.Orders WHERE ProductID IS NOT NULL
);
GO

-- Task 14: Find all employees who have acted as a salesperson on at least
--          one order.
SELECT EmployeeID, FirstName, LastName
FROM Sales.Employees
WHERE EmployeeID IN (SELECT SalesPersonID FROM Sales.Orders);
GO

-- Task 15: Find all orders placed for products in the 'Clothing' category.
SELECT OrderID, ProductID, Sales
FROM Sales.Orders
WHERE ProductID IN (
    SELECT ProductID FROM Sales.Products WHERE Category = 'Clothing'
);
GO

-- Task 16: Find all customers from countries that also have at least one
--          employee (comparing Customers.Country against a distinct list
--          derived from another source — here simulated via Orders'
--          ShipAddress containing a US state code is impractical, so we
--          instead find customers whose Country matches a country that
--          appears more than once in Customers, via a subquery list).
SELECT CustomerID, FirstName, LastName, Country
FROM Sales.Customers
WHERE Country IN (
    SELECT Country
    FROM Sales.Customers
    GROUP BY Country
    HAVING COUNT(*) > 1
);
GO

-- Task 17: Find all orders whose OrderStatus is one of the top 2 most
--          frequent statuses in the table.
SELECT OrderID, OrderStatus
FROM Sales.Orders
WHERE OrderStatus IN (
    SELECT TOP 2 OrderStatus
    FROM Sales.Orders
    GROUP BY OrderStatus
    ORDER BY COUNT(*) DESC
);
GO

-- Task 18: Find all employees who are NOT managers (i.e., their EmployeeID
--          never appears as someone else's ManagerID).
SELECT EmployeeID, FirstName, LastName
FROM Sales.Employees
WHERE EmployeeID NOT IN (
    SELECT ManagerID FROM Sales.Employees WHERE ManagerID IS NOT NULL
);
GO


/* =============================================================================
   SECTION C — CORRELATED SUBQUERIES
   The inner query references a column from the outer query and is
   re-evaluated for every outer row.
============================================================================= */

-- Task 19: Find every order whose Sales value is above the average Sales
--          for that specific customer (customer-level average, not global).
SELECT o.OrderID, o.CustomerID, o.Sales
FROM Sales.Orders o
WHERE o.Sales > (
    SELECT AVG(o2.Sales)
    FROM Sales.Orders o2
    WHERE o2.CustomerID = o.CustomerID
);
GO

-- Task 20: Find each customer's most recent order (correlated MAX date).
SELECT o.OrderID, o.CustomerID, o.OrderDate
FROM Sales.Orders o
WHERE o.OrderDate = (
    SELECT MAX(o2.OrderDate)
    FROM Sales.Orders o2
    WHERE o2.CustomerID = o.CustomerID
);
GO

-- Task 21: Find employees who earn more than the average salary within
--          their own department.
SELECT e.EmployeeID, e.FirstName, e.Department, e.Salary
FROM Sales.Employees e
WHERE e.Salary > (
    SELECT AVG(e2.Salary)
    FROM Sales.Employees e2
    WHERE e2.Department = e.Department
);
GO

-- Task 22: Find the highest-priced product within each category.
SELECT p.ProductID, p.Product, p.Category, p.Price
FROM Sales.Products p
WHERE p.Price = (
    SELECT MAX(p2.Price)
    FROM Sales.Products p2
    WHERE p2.Category = p.Category
);
GO

-- Task 23: For every order, count how many other orders the same customer
--          placed before it (a correlated COUNT subquery).
SELECT
    o.OrderID,
    o.CustomerID,
    o.OrderDate,
    (
        SELECT COUNT(*)
        FROM Sales.Orders o2
        WHERE o2.CustomerID = o.CustomerID
          AND o2.OrderDate < o.OrderDate
    ) AS PriorOrdersByCustomer
FROM Sales.Orders o;
GO

-- Task 24: Find employees whose salary is the highest among the employees
--          reporting to the same manager.
SELECT e.EmployeeID, e.FirstName, e.ManagerID, e.Salary
FROM Sales.Employees e
WHERE e.Salary = (
    SELECT MAX(e2.Salary)
    FROM Sales.Employees e2
    WHERE e2.ManagerID = e.ManagerID
       OR (e2.ManagerID IS NULL AND e.ManagerID IS NULL)
);
GO

-- Task 25: Find customers whose Score is higher than the average Score of
--          customers from the same Country.
SELECT c.CustomerID, c.FirstName, c.Country, c.Score
FROM Sales.Customers c
WHERE c.Score > (
    SELECT AVG(c2.Score)
    FROM Sales.Customers c2
    WHERE c2.Country = c.Country
);
GO

-- Task 26: For each order in Sales.Orders, check whether the same
--          CustomerID+ProductID combination also exists in
--          Sales.OrdersArchive (a correlated existence-style scalar check
--          using a subquery in the SELECT list).
SELECT
    o.OrderID,
    o.CustomerID,
    o.ProductID,
    (
        SELECT COUNT(*)
        FROM Sales.OrdersArchive oa
        WHERE oa.CustomerID = o.CustomerID
          AND oa.ProductID = o.ProductID
    ) AS TimesSeenInArchive
FROM Sales.Orders o;
GO


/* =============================================================================
   SECTION D — EXISTS / NOT EXISTS
   Test for the mere presence/absence of matching rows; usually faster than
   IN/NOT IN for large or NULL-containing sets.
============================================================================= */

-- Task 27: Find all customers who have placed at least one order (EXISTS
--          version of Task 11).
SELECT c.CustomerID, c.FirstName, c.LastName
FROM Sales.Customers c
WHERE EXISTS (
    SELECT 1 FROM Sales.Orders o WHERE o.CustomerID = c.CustomerID
);
GO

-- Task 28: Find all customers who have never placed an order (NOT EXISTS
--          version of Task 12; safer than NOT IN when NULLs are present).
SELECT c.CustomerID, c.FirstName, c.LastName
FROM Sales.Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Sales.Orders o WHERE o.CustomerID = c.CustomerID
);
GO

-- Task 29: Find all products that have at least one order with Quantity
--          greater than 2.
SELECT p.ProductID, p.Product
FROM Sales.Products p
WHERE EXISTS (
    SELECT 1
    FROM Sales.Orders o
    WHERE o.ProductID = p.ProductID
      AND o.Quantity > 2
);
GO

-- Task 30: Find employees who have never been a SalesPersonID on any order.
SELECT e.EmployeeID, e.FirstName, e.LastName
FROM Sales.Employees e
WHERE NOT EXISTS (
    SELECT 1 FROM Sales.Orders o WHERE o.SalesPersonID = e.EmployeeID
);
GO

-- Task 31: Find customers who have an order with a NULL ShipAddress.
SELECT DISTINCT c.CustomerID, c.FirstName, c.LastName
FROM Sales.Customers c
WHERE EXISTS (
    SELECT 1
    FROM Sales.Orders o
    WHERE o.CustomerID = c.CustomerID
      AND o.ShipAddress IS NULL
);
GO

-- Task 32: Find orders whose OrderID also appears more than once in
--          Sales.OrdersArchive (duplicated archive records).
SELECT o.OrderID, o.CustomerID, o.Sales
FROM Sales.Orders o
WHERE EXISTS (
    SELECT 1
    FROM Sales.OrdersArchive oa
    WHERE oa.OrderID = o.OrderID
    GROUP BY oa.OrderID
    HAVING COUNT(*) > 1
);
GO

-- Task 33: Find products that were never sold at their full listed Price
--          (i.e., no order's Sales/Quantity equals the current Price).
SELECT p.ProductID, p.Product, p.Price
FROM Sales.Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM Sales.Orders o
    WHERE o.ProductID = p.ProductID
      AND o.Quantity > 0
      AND (o.Sales * 1.0 / o.Quantity) = p.Price
);
GO

-- Task 34: Find managers (employees who have at least one direct report).
SELECT e.EmployeeID, e.FirstName, e.LastName
FROM Sales.Employees e
WHERE EXISTS (
    SELECT 1 FROM Sales.Employees sub WHERE sub.ManagerID = e.EmployeeID
);
GO


/* =============================================================================
   SECTION E — SUBQUERIES IN FROM (DERIVED TABLES)
   A subquery used as a virtual table, joined or filtered like any other.
============================================================================= */

-- Task 35: Show each customer alongside their total Sales, using a derived
--          table that pre-aggregates orders per customer.
SELECT c.CustomerID, c.FirstName, c.LastName, o_summary.TotalSales
FROM Sales.Customers c
JOIN (
    SELECT CustomerID, SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY CustomerID
) AS o_summary
    ON o_summary.CustomerID = c.CustomerID;
GO

-- Task 36: List each SalesPersonID's total number of orders and total
--          Sales, filtered to only those employees with more than 2 orders.
SELECT emp.EmployeeID, emp.FirstName, sales_agg.OrderCount, sales_agg.TotalSales
FROM (
    SELECT SalesPersonID, COUNT(*) AS OrderCount, SUM(Sales) AS TotalSales
    FROM Sales.Orders
    GROUP BY SalesPersonID
) AS sales_agg
JOIN Sales.Employees emp
    ON emp.EmployeeID = sales_agg.SalesPersonID
WHERE sales_agg.OrderCount > 2;
GO

-- Task 37: Rank products by total revenue using a derived table plus
--          window function.
SELECT *
FROM (
    SELECT
        p.ProductID,
        p.Product,
        SUM(o.Sales) AS Revenue,
        RANK() OVER (ORDER BY SUM(o.Sales) DESC) AS RevenueRank
    FROM Sales.Products p
    JOIN Sales.Orders o ON o.ProductID = p.ProductID
    GROUP BY p.ProductID, p.Product
) AS ranked
WHERE RevenueRank <= 3;
GO

-- Task 38: Find the average order value per country by first joining
--          Orders to Customers in a derived table, then aggregating.
SELECT Country, AVG(Sales) AS AvgOrderValue
FROM (
    SELECT c.Country, o.Sales
    FROM Sales.Orders o
    JOIN Sales.Customers c ON c.CustomerID = o.CustomerID
) AS country_orders
GROUP BY Country;
GO

-- Task 39: Compare Orders vs. OrdersArchive: combine both into a derived
--          table (UNION ALL) and show the yearly order count.
SELECT YEAR(OrderDate) AS OrderYear, COUNT(*) AS OrderCount
FROM (
    SELECT OrderID, OrderDate FROM Sales.Orders
    UNION ALL
    SELECT OrderID, OrderDate FROM Sales.OrdersArchive
) AS all_orders
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;
GO

-- Task 40: Find the top spending customer per country using a derived
--          table with ROW_NUMBER().
SELECT CustomerID, FirstName, Country, TotalSales
FROM (
    SELECT
        c.CustomerID,
        c.FirstName,
        c.Country,
        SUM(o.Sales) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY c.Country ORDER BY SUM(o.Sales) DESC) AS rn
    FROM Sales.Customers c
    JOIN Sales.Orders o ON o.CustomerID = c.CustomerID
    GROUP BY c.CustomerID, c.FirstName, c.Country
) AS ranked_by_country
WHERE rn = 1;
GO


/* =============================================================================
   SECTION F — SUBQUERIES IN SELECT (INLINE / SCALAR PROJECTIONS)
   Subqueries used to project a computed column per row.
============================================================================= */

-- Task 41: For each customer, show their total number of orders (subquery
--          in SELECT, not a JOIN/GROUP BY).
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    (SELECT COUNT(*) FROM Sales.Orders o WHERE o.CustomerID = c.CustomerID) AS OrderCount
FROM Sales.Customers c;
GO

-- Task 42: For each product, show its total quantity sold and rank it
--          against the best-selling product using nested scalar subqueries.
SELECT
    p.ProductID,
    p.Product,
    (SELECT SUM(o.Quantity) FROM Sales.Orders o WHERE o.ProductID = p.ProductID) AS TotalQtySold,
    (SELECT MAX(qty_totals.TotalQty)
        FROM (
            SELECT SUM(Quantity) AS TotalQty
            FROM Sales.Orders
            GROUP BY ProductID
        ) AS qty_totals
    ) AS BestSellerQty
FROM Sales.Products p;
GO

-- Task 43: For each employee, show their manager's name via a self-referencing
--          scalar subquery.
SELECT
    e.EmployeeID,
    e.FirstName,
    e.ManagerID,
    (SELECT m.FirstName FROM Sales.Employees m WHERE m.EmployeeID = e.ManagerID) AS ManagerFirstName
FROM Sales.Employees e;
GO

-- Task 44: For each order, show what percentage of that customer's total
--          Sales this single order represents.
SELECT
    o.OrderID,
    o.CustomerID,
    o.Sales,
    ROUND(
        o.Sales * 100.0 / (SELECT SUM(o2.Sales) FROM Sales.Orders o2 WHERE o2.CustomerID = o.CustomerID),
        2
    ) AS PctOfCustomerTotal
FROM Sales.Orders o;
GO

-- Task 45: For each category, show the category's product count and its
--          most expensive product's name via subqueries in SELECT.
SELECT DISTINCT
    p.Category,
    (SELECT COUNT(*) FROM Sales.Products p2 WHERE p2.Category = p.Category) AS ProductCount,
    (SELECT TOP 1 p3.Product
        FROM Sales.Products p3
        WHERE p3.Category = p.Category
        ORDER BY p3.Price DESC
    ) AS MostExpensiveProduct
FROM Sales.Products p;
GO

-- Task 46: For each order, flag whether the same order (by OrderID) exists
--          in the archive table, using a scalar CASE + subquery.
SELECT
    o.OrderID,
    o.OrderStatus,
    CASE
        WHEN (SELECT COUNT(*) FROM Sales.OrdersArchive oa WHERE oa.OrderID = o.OrderID) > 0
        THEN 'Also In Archive'
        ELSE 'Only In Orders'
    END AS ArchiveFlag
FROM Sales.Orders o;
GO


/* =============================================================================
   SECTION G — ANY / ALL / SOME
   Compare a value against a set: ANY (true if it matches at least one row),
   ALL (true only if it matches every row).
============================================================================= */

-- Task 47: Find products priced higher than ALL 'Accessories' products.
SELECT ProductID, Product, Category, Price
FROM Sales.Products
WHERE Price > ALL (
    SELECT Price FROM Sales.Products WHERE Category = 'Accessories'
);
GO

-- Task 48: Find products priced higher than ANY 'Accessories' product
--          (i.e., higher than at least the cheapest one).
SELECT ProductID, Product, Category, Price
FROM Sales.Products
WHERE Price > ANY (
    SELECT Price FROM Sales.Products WHERE Category = 'Accessories'
);
GO

-- Task 49: Find employees whose Salary is greater than ALL salaries in the
--          'Marketing' department.
SELECT EmployeeID, FirstName, Department, Salary
FROM Sales.Employees
WHERE Salary > ALL (
    SELECT Salary FROM Sales.Employees WHERE Department = 'Marketing'
);
GO

-- Task 50: Find orders whose Sales value equals ANY order's Sales value
--          placed by CustomerID = 3 (a match against a set, not a single
--          value).
SELECT OrderID, CustomerID, Sales
FROM Sales.Orders
WHERE Sales = ANY (
    SELECT Sales FROM Sales.Orders WHERE CustomerID = 3
)
AND CustomerID <> 3;
GO

/* =============================================================================
   END OF SCRIPT — 50 tasks complete.
============================================================================= */
