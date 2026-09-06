/*
=============================================================================
SalesDB — 50 NULL Handling Practice Tasks & Solutions (T-SQL / SQL Server)
=============================================================================
Purpose:
    50 hands-on tasks covering NULL detection and NULL handling in every
    major flavor, against the SalesDB schema (Sales.Customers,
    Sales.Employees, Sales.Products, Sales.Orders, Sales.OrdersArchive).
    Known NULL-bearing columns in this schema: Customers.LastName,
    Customers.Score, Employees.LastName, Employees.ManagerID,
    Orders.ShipAddress, Orders.BillAddress (also has empty strings '' —
    NOT the same as NULL), Orders.CreationTime is NOT NULL.

Sections:
    A. Basic NULL Detection (IS NULL / IS NOT NULL)   (Tasks 1-8)
    B. ISNULL vs. COALESCE                             (Tasks 9-16)
    C. NULLIF                                          (Tasks 17-20)
    D. NULLs and Aggregate Functions                   (Tasks 21-26)
    E. NULLs in Arithmetic & String Concatenation       (Tasks 27-30)
    F. NULL Comparison Pitfalls (=, <>, IN / NOT IN)    (Tasks 31-36)
    G. NULLs in ORDER BY / GROUP BY                     (Tasks 37-40)
    H. NULL Handling with CASE / IIF                    (Tasks 41-44)
    I. NULLs in JOINs                                   (Tasks 45-48)
    J. Cleaning Data: Updating / Replacing NULLs        (Tasks 49-50)

Run against the database created by init-sqlserver-salesdb.sql.
=============================================================================
*/

USE SalesDB;
GO


/* =============================================================================
   SECTION A — BASIC NULL DETECTION (IS NULL / IS NOT NULL)
   NULL means "unknown/absent" — it can only be tested with IS NULL /
   IS NOT NULL, never with = or <>.
============================================================================= */

-- Task 1: Find all customers with a missing (NULL) LastName.
SELECT CustomerID, FirstName, LastName
FROM Sales.Customers
WHERE LastName IS NULL;
GO

-- Task 2: Find all customers with a non-NULL Score.
SELECT CustomerID, FirstName, Score
FROM Sales.Customers
WHERE Score IS NOT NULL;
GO

-- Task 3: Find all orders with a missing ShipAddress.
SELECT OrderID, CustomerID, ShipAddress
FROM Sales.Orders
WHERE ShipAddress IS NULL;
GO

-- Task 4: Find all orders with a missing BillAddress — note this is
--         different from an EMPTY STRING BillAddress ('').
SELECT OrderID, CustomerID, BillAddress
FROM Sales.Orders
WHERE BillAddress IS NULL;
GO

-- Task 5: Find all orders where BillAddress is an empty string (present
--         but blank) — contrast with Task 4's true NULLs.
SELECT OrderID, CustomerID, BillAddress
FROM Sales.Orders
WHERE BillAddress = '';
GO

-- Task 6: Find all employees who have no manager (top of the org chart).
SELECT EmployeeID, FirstName, LastName, ManagerID
FROM Sales.Employees
WHERE ManagerID IS NULL;
GO

-- Task 7: Count how many customers have a NULL Score versus a non-NULL
--         Score, side by side.
SELECT
    SUM(CASE WHEN Score IS NULL THEN 1 ELSE 0 END)     AS NullScoreCount,
    SUM(CASE WHEN Score IS NOT NULL THEN 1 ELSE 0 END) AS NonNullScoreCount
FROM Sales.Customers;
GO

-- Task 8: Find all orders where EITHER ShipAddress OR BillAddress is
--         NULL (at least one address missing).
SELECT OrderID, ShipAddress, BillAddress
FROM Sales.Orders
WHERE ShipAddress IS NULL OR BillAddress IS NULL;
GO


/* =============================================================================
   SECTION B — ISNULL vs. COALESCE
   ISNULL(a, b) is SQL-Server-specific, takes exactly 2 arguments, and
   returns a's data type. COALESCE(a, b, c, ...) is ANSI-standard, accepts
   any number of arguments, and returns the highest-precedence data type
   among them — generally the safer default choice.
============================================================================= */

-- Task 9: Replace NULL LastName values with 'N/A' using ISNULL.
SELECT CustomerID, FirstName, ISNULL(LastName, 'N/A') AS LastName
FROM Sales.Customers;
GO

-- Task 10: Replace NULL LastName values with 'N/A' using COALESCE
--          (equivalent result to Task 9, ANSI-standard form).
SELECT CustomerID, FirstName, COALESCE(LastName, 'N/A') AS LastName
FROM Sales.Customers;
GO

-- Task 11: Replace NULL Score values with 0 so aggregate math treats
--          missing scores as zero rather than excluding them.
SELECT CustomerID, ISNULL(Score, 0) AS ScoreOrZero
FROM Sales.Customers;
GO

-- Task 12: Use COALESCE to pick the first available address for an order:
--          ShipAddress if present, otherwise BillAddress, otherwise
--          'No Address on File'.
SELECT
    OrderID,
    COALESCE(NULLIF(ShipAddress, ''), NULLIF(BillAddress, ''), 'No Address on File') AS BestAvailableAddress
FROM Sales.Orders;
GO

-- Task 13: Build a full customer name that gracefully handles a NULL
--          LastName (COALESCE inside string concatenation).
SELECT
    CustomerID,
    FirstName + ' ' + COALESCE(LastName, '') AS FullName
FROM Sales.Customers;
GO

-- Task 14: Show each employee's ManagerID, substituting 'No Manager (Top Level)'
--          for NULL using ISNULL with an explicit CAST to match types.
SELECT
    EmployeeID,
    FirstName,
    ISNULL(CAST(ManagerID AS VARCHAR(20)), 'No Manager (Top Level)') AS ManagerDisplay
FROM Sales.Employees;
GO

-- Task 15: Use COALESCE across three candidate columns to build a display
--          label for orders missing a status (defensive default even
--          though OrderStatus itself isn't NULL in this schema).
SELECT
    OrderID,
    COALESCE(OrderStatus, 'Unknown Status') AS OrderStatusDisplay
FROM Sales.Orders;
GO

-- Task 16: Compare ISNULL and COALESCE side by side on the same column to
--          show they produce identical results here.
SELECT
    CustomerID,
    Score,
    ISNULL(Score, -1)   AS ViaISNULL,
    COALESCE(Score, -1) AS ViaCOALESCE
FROM Sales.Customers;
GO


/* =============================================================================
   SECTION C — NULLIF
   NULLIF(a, b) returns NULL if a = b, otherwise returns a. Useful for
   turning a "sentinel" value into a true NULL, or for guarding against
   divide-by-zero.
============================================================================= */

-- Task 17: Safely compute Sales-per-unit for every order, using NULLIF to
--          avoid a divide-by-zero error when Quantity is 0.
SELECT
    OrderID, Quantity, Sales,
    Sales * 1.0 / NULLIF(Quantity, 0) AS UnitPrice
FROM Sales.Orders;
GO

-- Task 18: Treat an empty-string BillAddress as if it were NULL using
--          NULLIF, then report how many orders are missing a bill address
--          under that broader definition.
SELECT COUNT(*) AS OrdersMissingBillAddress
FROM Sales.Orders
WHERE NULLIF(BillAddress, '') IS NULL;
GO

-- Task 19: Use NULLIF to flag customers whose Score is exactly 0 as
--          "no score recorded" (turning a sentinel 0 into a true NULL for
--          downstream ISNULL/COALESCE handling).
SELECT
    CustomerID,
    NULLIF(Score, 0) AS ScoreOrNull
FROM Sales.Customers;
GO

-- Task 20: Combine NULLIF and COALESCE to normalize both NULL and
--          empty-string ShipAddress values into a single 'Not Provided'
--          label.
SELECT
    OrderID,
    COALESCE(NULLIF(ShipAddress, ''), 'Not Provided') AS ShipAddressClean
FROM Sales.Orders;
GO


/* =============================================================================
   SECTION D — NULLs AND AGGREGATE FUNCTIONS
   SUM, AVG, MIN, MAX, and COUNT(column) all silently IGNORE NULLs.
   COUNT(*) is the exception — it counts every row regardless of NULLs.
============================================================================= */

-- Task 21: Show the difference between COUNT(*) and COUNT(Score) on
--          Sales.Customers — the gap reveals how many Scores are NULL.
SELECT
    COUNT(*)     AS TotalCustomers,
    COUNT(Score) AS CustomersWithScore
FROM Sales.Customers;
GO

-- Task 22: Compute AVG(Score) and note that it averages only the non-NULL
--          rows (NULLs are excluded from both the sum and the divisor).
SELECT AVG(Score) AS AvgScoreExcludingNulls
FROM Sales.Customers;
GO

-- Task 23: Compare AVG(Score) as-is against AVG(ISNULL(Score, 0)) — the
--          second version treats missing scores as 0, pulling the average
--          down.
SELECT
    AVG(Score)            AS AvgIgnoringNulls,
    AVG(ISNULL(Score, 0)) AS AvgTreatingNullAsZero
FROM Sales.Customers;
GO

-- Task 24: Show MIN and MAX Score, confirming NULLs never "win" either
--          comparison.
SELECT MIN(Score) AS MinScore, MAX(Score) AS MaxScore
FROM Sales.Customers;
GO

-- Task 25: Show SUM(Score) across all customers, confirming NULL rows
--          contribute nothing to the total (not treated as 0, simply
--          skipped).
SELECT SUM(Score) AS TotalScore
FROM Sales.Customers;
GO

-- Task 26: For each Country, show the customer count vs. the count of
--          customers with a non-NULL Score, to spot data-quality gaps by
--          region.
SELECT
    Country,
    COUNT(*)     AS TotalCustomers,
    COUNT(Score) AS CustomersWithScore
FROM Sales.Customers
GROUP BY Country;
GO


/* =============================================================================
   SECTION E — NULLs IN ARITHMETIC & STRING CONCATENATION
   Any arithmetic expression or (by default) string concatenation
   involving a NULL operand produces NULL — the NULL "poisons" the whole
   expression unless handled explicitly.
============================================================================= */

-- Task 27: Show how concatenating FirstName + LastName produces a NULL
--          FullName whenever LastName is NULL (the unguarded version).
SELECT
    CustomerID,
    FirstName + ' ' + LastName AS FullNameUnguarded
FROM Sales.Customers;
GO

-- Task 28: Show how CONCAT() avoids that pitfall — CONCAT treats NULL
--          arguments as empty strings instead of nulling the whole
--          result.
SELECT
    CustomerID,
    CONCAT(FirstName, ' ', LastName) AS FullNameViaConcat
FROM Sales.Customers;
GO

-- Task 29: Show how arithmetic (Score + 100) becomes NULL whenever Score
--          itself is NULL, then show the guarded version using ISNULL.
SELECT
    CustomerID,
    Score,
    Score + 100              AS BonusUnguarded,
    ISNULL(Score, 0) + 100   AS BonusGuarded
FROM Sales.Customers;
GO

-- Task 30: Show how a NULL Quantity or NULL Sales would silently break a
--          revenue-per-unit calculation, guarding both sides with ISNULL
--          / NULLIF.
SELECT
    OrderID,
    ISNULL(Sales, 0) * 1.0 / NULLIF(ISNULL(Quantity, 0), 0) AS SafeUnitPrice
FROM Sales.Orders;
GO


/* =============================================================================
   SECTION F — NULL COMPARISON PITFALLS (=, <>, IN / NOT IN)
   NULL = NULL evaluates to UNKNOWN (not TRUE), so it's silently excluded
   by WHERE. NOT IN is especially dangerous: if the subquery/list contains
   even one NULL, the entire NOT IN comparison returns no rows.
============================================================================= */

-- Task 31: Demonstrate that Score = NULL returns ZERO rows, even for
--          customers whose Score genuinely is NULL (the wrong way to
--          test for NULL).
SELECT CustomerID, Score
FROM Sales.Customers
WHERE Score = NULL;   -- always returns 0 rows — this is a common bug
GO

-- Task 32: Show the correct way to get the same intended result as
--          Task 31, using IS NULL.
SELECT CustomerID, Score
FROM Sales.Customers
WHERE Score IS NULL;
GO

-- Task 33: Demonstrate the NOT IN + NULL pitfall: find customers NOT
--          already in a list of CustomerIDs, where the list itself
--          contains a NULL — this silently returns zero rows.
SELECT CustomerID, FirstName
FROM Sales.Customers
WHERE CustomerID NOT IN (
    SELECT CustomerID FROM Sales.Orders WHERE OrderID = 999  -- no match; SalesPersonID-style list could contain NULLs
);
-- To see the real pitfall, compare against a list that DOES contain a NULL:
SELECT CustomerID, FirstName
FROM Sales.Customers
WHERE CustomerID NOT IN (1, 2, NULL);   -- returns ZERO rows for every customer
GO

-- Task 34: Show the safe fix for Task 33's pitfall using NOT EXISTS
--          instead of NOT IN (NOT EXISTS is unaffected by NULLs in the
--          compared set).
SELECT c.CustomerID, c.FirstName
FROM Sales.Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Sales.Orders o WHERE o.CustomerID = c.CustomerID
);
GO

-- Task 35: Show the safe fix for Task 33 using NOT IN plus an explicit
--          filter to strip NULLs out of the subquery list first.
SELECT c.CustomerID, c.FirstName
FROM Sales.Customers c
WHERE c.CustomerID NOT IN (
    SELECT CustomerID FROM Sales.Orders WHERE CustomerID IS NOT NULL
);
GO

-- Task 36: Demonstrate NULL-safe equality using IS DISTINCT FROM-style
--          logic (SQL Server lacks IS DISTINCT FROM directly, so emulate
--          it with EXCEPT/INTERSECT-safe comparison) — find orders where
--          ShipAddress and BillAddress differ, treating two NULLs as
--          "the same" rather than "different".
SELECT OrderID, ShipAddress, BillAddress
FROM Sales.Orders
WHERE NOT (
    (ShipAddress = BillAddress)
    OR (ShipAddress IS NULL AND BillAddress IS NULL)
)
OR (ShipAddress IS NULL AND BillAddress IS NOT NULL)
OR (ShipAddress IS NOT NULL AND BillAddress IS NULL);
GO


/* =============================================================================
   SECTION G — NULLs IN ORDER BY / GROUP BY
   SQL Server sorts NULLs FIRST in ascending order by default. GROUP BY
   treats all NULLs as a single group (they're considered "equal" to each
   other for grouping purposes, even though NULL = NULL is UNKNOWN).
============================================================================= */

-- Task 37: Sort customers by Score ascending — note NULL Scores appear
--          FIRST (SQL Server's default NULL ordering).
SELECT CustomerID, FirstName, Score
FROM Sales.Customers
ORDER BY Score ASC;
GO

-- Task 38: Sort customers by Score, but force NULLs to sort LAST
--          regardless of ASC/DESC, using a CASE-based sort key.
SELECT CustomerID, FirstName, Score
FROM Sales.Customers
ORDER BY CASE WHEN Score IS NULL THEN 1 ELSE 0 END, Score DESC;
GO

-- Task 39: Group orders by BillAddress and show that NULL BillAddress
--          rows are collapsed into a single NULL group (distinct from the
--          empty-string '' group).
SELECT BillAddress, COUNT(*) AS OrderCount
FROM Sales.Orders
GROUP BY BillAddress;
GO

-- Task 40: Group employees by ManagerID (including the NULL group for
--          top-level employees) and count direct reports per manager.
SELECT ManagerID, COUNT(*) AS DirectReportCount
FROM Sales.Employees
GROUP BY ManagerID;
GO


/* =============================================================================
   SECTION H — NULL HANDLING WITH CASE / IIF
   CASE (and the shorthand IIF) let you branch explicitly on NULL-ness,
   giving full control beyond what ISNULL/COALESCE alone can express.
============================================================================= */

-- Task 41: Use CASE to label each customer's Score status as 'Missing',
--          'Low', or 'Good'.
SELECT
    CustomerID,
    Score,
    CASE
        WHEN Score IS NULL THEN 'Missing'
        WHEN Score < 500 THEN 'Low'
        ELSE 'Good'
    END AS ScoreStatus
FROM Sales.Customers;
GO

-- Task 42: Use IIF to produce a simple Yes/No flag for whether an order
--          has a recorded ShipAddress.
SELECT
    OrderID,
    IIF(ShipAddress IS NULL, 'No', 'Yes') AS HasShipAddress
FROM Sales.Orders;
GO

-- Task 43: Use CASE to build a data-quality flag across multiple nullable
--          columns on Sales.Customers at once.
SELECT
    CustomerID,
    CASE
        WHEN LastName IS NULL AND Score IS NULL THEN 'Missing LastName & Score'
        WHEN LastName IS NULL THEN 'Missing LastName'
        WHEN Score IS NULL THEN 'Missing Score'
        ELSE 'Complete'
    END AS DataQualityFlag
FROM Sales.Customers;
GO

-- Task 44: Use CASE to give employees with no ManagerID a synthetic title
--          of 'Executive', and everyone else 'Staff'.
SELECT
    EmployeeID, FirstName,
    CASE WHEN ManagerID IS NULL THEN 'Executive' ELSE 'Staff' END AS OrgTitle
FROM Sales.Employees;
GO


/* =============================================================================
   SECTION I — NULLs IN JOINs
   A LEFT/RIGHT/FULL OUTER JOIN introduces NULLs for the unmatched side —
   understanding this is essential for correctly finding "unmatched" rows.
============================================================================= */

-- Task 45: LEFT JOIN Customers to Orders and use "the join produced a
--          NULL OrderID" to find customers with no orders at all.
SELECT c.CustomerID, c.FirstName, o.OrderID
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON o.CustomerID = c.CustomerID
WHERE o.OrderID IS NULL;
GO

-- Task 46: LEFT JOIN Products to Orders to find products that have never
--          been ordered (NULL on the Orders side after the join).
SELECT p.ProductID, p.Product, o.OrderID
FROM Sales.Products p
LEFT JOIN Sales.Orders o ON o.ProductID = p.ProductID
WHERE o.OrderID IS NULL;
GO

-- Task 47: RIGHT JOIN Employees to Orders (as SalesPersonID) to confirm
--          every order has a matching salesperson — any NULL on the
--          Employees side would flag an orphaned SalesPersonID.
SELECT e.EmployeeID, o.OrderID, o.SalesPersonID
FROM Sales.Employees e
RIGHT JOIN Sales.Orders o ON o.SalesPersonID = e.EmployeeID
WHERE e.EmployeeID IS NULL;
GO

-- Task 48: Use a FULL OUTER JOIN between Orders and OrdersArchive (on
--          OrderID) to find OrderIDs that exist in only one of the two
--          tables, using NULL checks on both sides.
SELECT
    COALESCE(o.OrderID, oa.OrderID) AS OrderID,
    CASE
        WHEN o.OrderID IS NULL THEN 'Archive Only'
        WHEN oa.OrderID IS NULL THEN 'Current Only'
        ELSE 'In Both'
    END AS Location
FROM Sales.Orders o
FULL OUTER JOIN Sales.OrdersArchive oa ON oa.OrderID = o.OrderID
WHERE o.OrderID IS NULL OR oa.OrderID IS NULL;
GO


/* =============================================================================
   SECTION J — CLEANING DATA: UPDATING / REPLACING NULLs
   Once NULLs are identified, a common next step is to standardize or
   backfill them directly in the base table.
============================================================================= */

-- Task 49: Update Sales.Customers so any NULL LastName becomes the
--          literal string 'Unknown' (permanent data cleanup, not just a
--          display-time ISNULL).
UPDATE Sales.Customers
SET LastName = 'Unknown'
WHERE LastName IS NULL;
GO
SELECT CustomerID, FirstName, LastName FROM Sales.Customers;
GO

-- Task 50: Update Sales.Orders so any NULL ShipAddress or BillAddress is
--          replaced with 'Not Provided', and any lingering empty-string
--          BillAddress is standardized to the same label.
UPDATE Sales.Orders
SET
    ShipAddress = ISNULL(ShipAddress, 'Not Provided'),
    BillAddress = CASE
        WHEN BillAddress IS NULL OR BillAddress = '' THEN 'Not Provided'
        ELSE BillAddress
    END
WHERE ShipAddress IS NULL
   OR BillAddress IS NULL
   OR BillAddress = '';
GO
SELECT OrderID, ShipAddress, BillAddress FROM Sales.Orders;
GO

/* =============================================================================
   END OF SCRIPT — 50 NULL-handling tasks complete.
============================================================================= */
