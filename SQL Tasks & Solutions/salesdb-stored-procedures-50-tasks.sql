/*
=============================================================================
SalesDB — 50 Stored Procedure Practice Tasks & Solutions (T-SQL / SQL Server)
=============================================================================
Purpose:
    50 hands-on tasks covering stored procedures in every major flavor,
    against the SalesDB schema (Sales.Customers, Sales.Employees,
    Sales.Products, Sales.Orders, Sales.OrdersArchive). Each task creates a
    procedure and includes a sample EXEC call demonstrating it.

Sections:
    A. Basic Stored Procedures                    (Tasks 1-5)
    B. Input Parameters                            (Tasks 6-11)
    C. Default Parameter Values                    (Tasks 12-15)
    D. OUTPUT Parameters                            (Tasks 16-21)
    E. CRUD Procedures (Insert/Update/Delete)       (Tasks 22-29)
    F. Control Flow: IF / CASE / WHILE              (Tasks 30-35)
    G. Error Handling: TRY/CATCH, THROW             (Tasks 36-41)
    H. Transactions                                 (Tasks 42-45)
    I. Dynamic SQL                                  (Tasks 46-48)
    J. Cursors                                      (Task 49)
    K. Table-Valued Parameters & RETURN Status      (Task 50)

Run against the database created by init-sqlserver-salesdb.sql.
Each task: DROP PROCEDURE IF EXISTS ... ; GO ; CREATE PROCEDURE ... ; GO ;
demo EXEC call.
=============================================================================
*/

USE SalesDB;
GO


/* =============================================================================
   SECTION A — BASIC STORED PROCEDURES
   No parameters: encapsulate a fixed, reusable query.
============================================================================= */

-- Task 1: Create a procedure that returns all customers.
DROP PROCEDURE IF EXISTS Sales.usp_GetAllCustomers;
GO
CREATE PROCEDURE Sales.usp_GetAllCustomers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CustomerID, FirstName, LastName, Country, Score
    FROM Sales.Customers;
END;
GO
EXEC Sales.usp_GetAllCustomers;
GO

-- Task 2: Create a procedure that returns total Sales across all orders.
DROP PROCEDURE IF EXISTS Sales.usp_GetTotalSales;
GO
CREATE PROCEDURE Sales.usp_GetTotalSales
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SUM(Sales) AS TotalSales FROM Sales.Orders;
END;
GO
EXEC Sales.usp_GetTotalSales;
GO

-- Task 3: Create a procedure that returns all 'Delivered' orders.
DROP PROCEDURE IF EXISTS Sales.usp_GetDeliveredOrders;
GO
CREATE PROCEDURE Sales.usp_GetDeliveredOrders
AS
BEGIN
    SET NOCOUNT ON;
    SELECT OrderID, CustomerID, OrderDate, Sales
    FROM Sales.Orders
    WHERE OrderStatus = 'Delivered';
END;
GO
EXEC Sales.usp_GetDeliveredOrders;
GO

-- Task 4: Create a procedure that returns the employee count per
--         department.
DROP PROCEDURE IF EXISTS Sales.usp_GetEmployeeCountByDept;
GO
CREATE PROCEDURE Sales.usp_GetEmployeeCountByDept
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Department, COUNT(*) AS EmployeeCount
    FROM Sales.Employees
    GROUP BY Department;
END;
GO
EXEC Sales.usp_GetEmployeeCountByDept;
GO

-- Task 5: Create a procedure that returns all products ordered by Price
--         descending.
DROP PROCEDURE IF EXISTS Sales.usp_GetProductsByPrice;
GO
CREATE PROCEDURE Sales.usp_GetProductsByPrice
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductID, Product, Category, Price
    FROM Sales.Products
    ORDER BY Price DESC;
END;
GO
EXEC Sales.usp_GetProductsByPrice;
GO


/* =============================================================================
   SECTION B — INPUT PARAMETERS
   Procedures accepting one or more required arguments.
============================================================================= */

-- Task 6: Create a procedure that returns a single customer by CustomerID.
DROP PROCEDURE IF EXISTS Sales.usp_GetCustomerByID;
GO
CREATE PROCEDURE Sales.usp_GetCustomerByID
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CustomerID, FirstName, LastName, Country, Score
    FROM Sales.Customers
    WHERE CustomerID = @CustomerID;
END;
GO
EXEC Sales.usp_GetCustomerByID @CustomerID = 2;
GO

-- Task 7: Create a procedure that returns all orders placed by a given
--         customer.
DROP PROCEDURE IF EXISTS Sales.usp_GetOrdersByCustomer;
GO
CREATE PROCEDURE Sales.usp_GetOrdersByCustomer
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT OrderID, ProductID, OrderDate, Sales
    FROM Sales.Orders
    WHERE CustomerID = @CustomerID;
END;
GO
EXEC Sales.usp_GetOrdersByCustomer @CustomerID = 3;
GO

-- Task 8: Create a procedure that returns all orders within a given date
--         range.
DROP PROCEDURE IF EXISTS Sales.usp_GetOrdersByDateRange;
GO
CREATE PROCEDURE Sales.usp_GetOrdersByDateRange
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT OrderID, CustomerID, OrderDate, Sales
    FROM Sales.Orders
    WHERE OrderDate BETWEEN @StartDate AND @EndDate;
END;
GO
EXEC Sales.usp_GetOrdersByDateRange @StartDate = '2025-01-01', @EndDate = '2025-01-31';
GO

-- Task 9: Create a procedure that returns all products in a given
--         Category.
DROP PROCEDURE IF EXISTS Sales.usp_GetProductsByCategory;
GO
CREATE PROCEDURE Sales.usp_GetProductsByCategory
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductID, Product, Category, Price
    FROM Sales.Products
    WHERE Category = @Category;
END;
GO
EXEC Sales.usp_GetProductsByCategory @Category = 'Clothing';
GO

-- Task 10: Create a procedure that returns all employees earning more than
--          a given salary threshold.
DROP PROCEDURE IF EXISTS Sales.usp_GetEmployeesAboveSalary;
GO
CREATE PROCEDURE Sales.usp_GetEmployeesAboveSalary
    @MinSalary INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT EmployeeID, FirstName, LastName, Department, Salary
    FROM Sales.Employees
    WHERE Salary > @MinSalary;
END;
GO
EXEC Sales.usp_GetEmployeesAboveSalary @MinSalary = 60000;
GO

-- Task 11: Create a procedure that returns all orders for a given
--          CustomerID AND OrderStatus (two required parameters).
DROP PROCEDURE IF EXISTS Sales.usp_GetOrdersByCustomerAndStatus;
GO
CREATE PROCEDURE Sales.usp_GetOrdersByCustomerAndStatus
    @CustomerID INT,
    @OrderStatus VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT OrderID, OrderDate, OrderStatus, Sales
    FROM Sales.Orders
    WHERE CustomerID = @CustomerID
      AND OrderStatus = @OrderStatus;
END;
GO
EXEC Sales.usp_GetOrdersByCustomerAndStatus @CustomerID = 1, @OrderStatus = 'Delivered';
GO


/* =============================================================================
   SECTION C — DEFAULT PARAMETER VALUES
   Parameters with defaults can be omitted at call time.
============================================================================= */

-- Task 12: Create a procedure that returns products above a minimum price,
--          defaulting to 0 (i.e., all products) if not supplied.
DROP PROCEDURE IF EXISTS Sales.usp_GetProductsAbovePrice;
GO
CREATE PROCEDURE Sales.usp_GetProductsAbovePrice
    @MinPrice INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ProductID, Product, Price
    FROM Sales.Products
    WHERE Price > @MinPrice;
END;
GO
EXEC Sales.usp_GetProductsAbovePrice;                 -- uses default (0)
EXEC Sales.usp_GetProductsAbovePrice @MinPrice = 15;   -- explicit override
GO

-- Task 13: Create a procedure that returns orders by status, defaulting to
--          'Shipped' when no status is provided.
DROP PROCEDURE IF EXISTS Sales.usp_GetOrdersByStatusDefault;
GO
CREATE PROCEDURE Sales.usp_GetOrdersByStatusDefault
    @OrderStatus VARCHAR(50) = 'Shipped'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT OrderID, CustomerID, OrderStatus, Sales
    FROM Sales.Orders
    WHERE OrderStatus = @OrderStatus;
END;
GO
EXEC Sales.usp_GetOrdersByStatusDefault;
GO

-- Task 14: Create a procedure that returns top N customers by Score,
--          defaulting N to 3.
DROP PROCEDURE IF EXISTS Sales.usp_GetTopCustomersByScore;
GO
CREATE PROCEDURE Sales.usp_GetTopCustomersByScore
    @TopN INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@TopN) CustomerID, FirstName, LastName, Score
    FROM Sales.Customers
    ORDER BY Score DESC;
END;
GO
EXEC Sales.usp_GetTopCustomersByScore;
GO

-- Task 15: Create a procedure with two parameters — a required Country and
--          an optional MinScore (defaulting to NULL, meaning "no filter").
DROP PROCEDURE IF EXISTS Sales.usp_GetCustomersByCountry;
GO
CREATE PROCEDURE Sales.usp_GetCustomersByCountry
    @Country VARCHAR(50),
    @MinScore INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CustomerID, FirstName, LastName, Country, Score
    FROM Sales.Customers
    WHERE Country = @Country
      AND (@MinScore IS NULL OR Score >= @MinScore);
END;
GO
EXEC Sales.usp_GetCustomersByCountry @Country = 'USA';
EXEC Sales.usp_GetCustomersByCountry @Country = 'USA', @MinScore = 800;
GO


/* =============================================================================
   SECTION D — OUTPUT PARAMETERS
   Procedures that hand a computed scalar value back to the caller.
============================================================================= */

-- Task 16: Create a procedure that outputs the total number of customers.
DROP PROCEDURE IF EXISTS Sales.usp_GetCustomerCount;
GO
CREATE PROCEDURE Sales.usp_GetCustomerCount
    @CustomerCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @CustomerCount = COUNT(*) FROM Sales.Customers;
END;
GO
DECLARE @Cnt INT;
EXEC Sales.usp_GetCustomerCount @CustomerCount = @Cnt OUTPUT;
SELECT @Cnt AS TotalCustomers;
GO

-- Task 17: Create a procedure that outputs a given customer's total Sales.
DROP PROCEDURE IF EXISTS Sales.usp_GetCustomerTotalSales;
GO
CREATE PROCEDURE Sales.usp_GetCustomerTotalSales
    @CustomerID INT,
    @TotalSales INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @TotalSales = SUM(Sales)
    FROM Sales.Orders
    WHERE CustomerID = @CustomerID;
END;
GO
DECLARE @Total INT;
EXEC Sales.usp_GetCustomerTotalSales @CustomerID = 2, @TotalSales = @Total OUTPUT;
SELECT @Total AS CustomerTotalSales;
GO

-- Task 18: Create a procedure that outputs both the MIN and MAX Price of
--          products in a given category.
DROP PROCEDURE IF EXISTS Sales.usp_GetCategoryPriceRange;
GO
CREATE PROCEDURE Sales.usp_GetCategoryPriceRange
    @Category VARCHAR(50),
    @MinPrice INT OUTPUT,
    @MaxPrice INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        @MinPrice = MIN(Price),
        @MaxPrice = MAX(Price)
    FROM Sales.Products
    WHERE Category = @Category;
END;
GO
DECLARE @MinP INT, @MaxP INT;
EXEC Sales.usp_GetCategoryPriceRange @Category = 'Clothing', @MinPrice = @MinP OUTPUT, @MaxPrice = @MaxP OUTPUT;
SELECT @MinP AS MinPrice, @MaxP AS MaxPrice;
GO

-- Task 19: Create a procedure that checks whether a customer exists and
--          outputs a BIT flag.
DROP PROCEDURE IF EXISTS Sales.usp_CustomerExists;
GO
CREATE PROCEDURE Sales.usp_CustomerExists
    @CustomerID INT,
    @Exists BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Sales.Customers WHERE CustomerID = @CustomerID)
        SET @Exists = 1;
    ELSE
        SET @Exists = 0;
END;
GO
DECLARE @Found BIT;
EXEC Sales.usp_CustomerExists @CustomerID = 99, @Exists = @Found OUTPUT;
SELECT @Found AS CustomerFound;
GO

-- Task 20: Create a procedure that outputs the name of the top-selling
--          product (by total Sales revenue).
DROP PROCEDURE IF EXISTS Sales.usp_GetTopSellingProduct;
GO
CREATE PROCEDURE Sales.usp_GetTopSellingProduct
    @ProductName VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 @ProductName = p.Product
    FROM Sales.Products p
    JOIN Sales.Orders o ON o.ProductID = p.ProductID
    GROUP BY p.Product
    ORDER BY SUM(o.Sales) DESC;
END;
GO
DECLARE @TopProduct VARCHAR(50);
EXEC Sales.usp_GetTopSellingProduct @ProductName = @TopProduct OUTPUT;
SELECT @TopProduct AS TopSellingProduct;
GO

-- Task 21: Create a procedure that outputs an employee's manager's full
--          name (or NULL if they have no manager).
DROP PROCEDURE IF EXISTS Sales.usp_GetManagerName;
GO
CREATE PROCEDURE Sales.usp_GetManagerName
    @EmployeeID INT,
    @ManagerName VARCHAR(101) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @ManagerName = m.FirstName + ' ' + ISNULL(m.LastName, '')
    FROM Sales.Employees e
    LEFT JOIN Sales.Employees m ON m.EmployeeID = e.ManagerID
    WHERE e.EmployeeID = @EmployeeID;
END;
GO
DECLARE @Mgr VARCHAR(101);
EXEC Sales.usp_GetManagerName @EmployeeID = 4, @ManagerName = @Mgr OUTPUT;
SELECT @Mgr AS ManagerName;
GO


/* =============================================================================
   SECTION E — CRUD PROCEDURES (INSERT / UPDATE / DELETE)
   Procedures that modify data instead of only reading it.
============================================================================= */

-- Task 22: Create a procedure that inserts a new customer.
DROP PROCEDURE IF EXISTS Sales.usp_InsertCustomer;
GO
CREATE PROCEDURE Sales.usp_InsertCustomer
    @CustomerID INT,
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @Country VARCHAR(50),
    @Score INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Sales.Customers (CustomerID, FirstName, LastName, Country, Score)
    VALUES (@CustomerID, @FirstName, @LastName, @Country, @Score);
END;
GO
EXEC Sales.usp_InsertCustomer @CustomerID = 6, @FirstName = 'Laila', @LastName = 'Hassan', @Country = 'Egypt', @Score = 620;
GO

-- Task 23: Create a procedure that updates a customer's Score.
DROP PROCEDURE IF EXISTS Sales.usp_UpdateCustomerScore;
GO
CREATE PROCEDURE Sales.usp_UpdateCustomerScore
    @CustomerID INT,
    @NewScore INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Sales.Customers
    SET Score = @NewScore
    WHERE CustomerID = @CustomerID;
END;
GO
EXEC Sales.usp_UpdateCustomerScore @CustomerID = 6, @NewScore = 700;
GO

-- Task 24: Create a procedure that deletes a customer by ID (only if they
--          have no orders on record, to preserve referential sanity).
DROP PROCEDURE IF EXISTS Sales.usp_DeleteCustomer;
GO
CREATE PROCEDURE Sales.usp_DeleteCustomer
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Sales.Orders WHERE CustomerID = @CustomerID)
    BEGIN
        DELETE FROM Sales.Customers WHERE CustomerID = @CustomerID;
    END
    ELSE
    BEGIN
        PRINT 'Cannot delete: customer has existing orders.';
    END
END;
GO
EXEC Sales.usp_DeleteCustomer @CustomerID = 6;
GO

-- Task 25: Create a procedure that inserts a new product.
DROP PROCEDURE IF EXISTS Sales.usp_InsertProduct;
GO
CREATE PROCEDURE Sales.usp_InsertProduct
    @ProductID INT,
    @Product VARCHAR(50),
    @Category VARCHAR(50),
    @Price INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Sales.Products (ProductID, Product, Category, Price)
    VALUES (@ProductID, @Product, @Category, @Price);
END;
GO
EXEC Sales.usp_InsertProduct @ProductID = 106, @Product = 'Beanie', @Category = 'Clothing', @Price = 18;
GO

-- Task 26: Create a procedure that updates a product's Price.
DROP PROCEDURE IF EXISTS Sales.usp_UpdateProductPrice;
GO
CREATE PROCEDURE Sales.usp_UpdateProductPrice
    @ProductID INT,
    @NewPrice INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Sales.Products
    SET Price = @NewPrice
    WHERE ProductID = @ProductID;
END;
GO
EXEC Sales.usp_UpdateProductPrice @ProductID = 106, @NewPrice = 20;
GO

-- Task 27: Create a procedure that places a new order (insert into
--          Sales.Orders).
DROP PROCEDURE IF EXISTS Sales.usp_PlaceOrder;
GO
CREATE PROCEDURE Sales.usp_PlaceOrder
    @OrderID INT,
    @ProductID INT,
    @CustomerID INT,
    @SalesPersonID INT,
    @OrderDate DATE,
    @Quantity INT,
    @Sales INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Sales.Orders
        (OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, OrderStatus, Quantity, Sales, CreationTime)
    VALUES
        (@OrderID, @ProductID, @CustomerID, @SalesPersonID, @OrderDate, 'Pending', @Quantity, @Sales, SYSDATETIME());
END;
GO
EXEC Sales.usp_PlaceOrder @OrderID = 11, @ProductID = 103, @CustomerID = 4, @SalesPersonID = 1, @OrderDate = '2025-04-01', @Quantity = 2, @Sales = 40;
GO

-- Task 28: Create a procedure that updates an order's OrderStatus (e.g.
--          marking it 'Shipped').
DROP PROCEDURE IF EXISTS Sales.usp_UpdateOrderStatus;
GO
CREATE PROCEDURE Sales.usp_UpdateOrderStatus
    @OrderID INT,
    @NewStatus VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Sales.Orders
    SET OrderStatus = @NewStatus
    WHERE OrderID = @OrderID;
END;
GO
EXEC Sales.usp_UpdateOrderStatus @OrderID = 11, @NewStatus = 'Shipped';
GO

-- Task 29: Create a procedure that archives and removes an order: copies
--          it into Sales.OrdersArchive, then deletes it from Sales.Orders.
DROP PROCEDURE IF EXISTS Sales.usp_ArchiveOrder;
GO
CREATE PROCEDURE Sales.usp_ArchiveOrder
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Sales.OrdersArchive
        (OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, OrderStatus, ShipAddress, BillAddress, Quantity, Sales, CreationTime)
    SELECT
        OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, OrderStatus, ShipAddress, BillAddress, Quantity, Sales, CreationTime
    FROM Sales.Orders
    WHERE OrderID = @OrderID;

    DELETE FROM Sales.Orders WHERE OrderID = @OrderID;
END;
GO
EXEC Sales.usp_ArchiveOrder @OrderID = 11;
GO


/* =============================================================================
   SECTION F — CONTROL FLOW: IF / CASE / WHILE
   Procedures with branching logic and loops.
============================================================================= */

-- Task 30: Create a procedure that classifies a customer's Score into a
--          tier ('Bronze'/'Silver'/'Gold') and returns it (IF/ELSE).
DROP PROCEDURE IF EXISTS Sales.usp_GetCustomerTier;
GO
CREATE PROCEDURE Sales.usp_GetCustomerTier
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Score INT;
    SELECT @Score = Score FROM Sales.Customers WHERE CustomerID = @CustomerID;

    IF @Score IS NULL
        SELECT 'Unknown' AS Tier;
    ELSE IF @Score >= 800
        SELECT 'Gold' AS Tier;
    ELSE IF @Score >= 500
        SELECT 'Silver' AS Tier;
    ELSE
        SELECT 'Bronze' AS Tier;
END;
GO
EXEC Sales.usp_GetCustomerTier @CustomerID = 2;
GO

-- Task 31: Create a procedure that labels each order's Sales size using
--          CASE inside the query.
DROP PROCEDURE IF EXISTS Sales.usp_GetOrderSizeLabels;
GO
CREATE PROCEDURE Sales.usp_GetOrderSizeLabels
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        OrderID,
        Sales,
        CASE
            WHEN Sales >= 60 THEN 'Large'
            WHEN Sales >= 25 THEN 'Medium'
            ELSE 'Small'
        END AS OrderSizeLabel
    FROM Sales.Orders;
END;
GO
EXEC Sales.usp_GetOrderSizeLabels;
GO

-- Task 32: Create a procedure that applies a percentage discount to a
--          product's Price only IF the product's current Price exceeds a
--          given threshold.
DROP PROCEDURE IF EXISTS Sales.usp_ApplyConditionalDiscount;
GO
CREATE PROCEDURE Sales.usp_ApplyConditionalDiscount
    @ProductID INT,
    @PriceThreshold INT,
    @DiscountPct DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentPrice INT;
    SELECT @CurrentPrice = Price FROM Sales.Products WHERE ProductID = @ProductID;

    IF @CurrentPrice > @PriceThreshold
    BEGIN
        UPDATE Sales.Products
        SET Price = Price - (Price * @DiscountPct / 100)
        WHERE ProductID = @ProductID;
        PRINT 'Discount applied.';
    END
    ELSE
    BEGIN
        PRINT 'No discount: price below threshold.';
    END
END;
GO
EXEC Sales.usp_ApplyConditionalDiscount @ProductID = 105, @PriceThreshold = 20, @DiscountPct = 10;
GO

-- Task 33: Create a procedure that uses WHILE to print a countdown of the
--          top N highest-priced products, one at a time.
DROP PROCEDURE IF EXISTS Sales.usp_PrintTopProductsLoop;
GO
CREATE PROCEDURE Sales.usp_PrintTopProductsLoop
    @TopN INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Counter INT = 1;
    DECLARE @ProductName VARCHAR(50);

    WHILE @Counter <= @TopN
    BEGIN
        SELECT @ProductName = Product
        FROM (
            SELECT Product, ROW_NUMBER() OVER (ORDER BY Price DESC) AS rn
            FROM Sales.Products
        ) AS ranked
        WHERE rn = @Counter;

        PRINT CAST(@Counter AS VARCHAR) + ': ' + ISNULL(@ProductName, 'N/A');
        SET @Counter = @Counter + 1;
    END
END;
GO
EXEC Sales.usp_PrintTopProductsLoop @TopN = 3;
GO

-- Task 34: Create a procedure that increments every employee's Salary by a
--          percentage, but only WHILE the department average stays under a
--          cap (illustrative WHILE + safety check pattern).
DROP PROCEDURE IF EXISTS Sales.usp_RaiseDeptSalariesCapped;
GO
CREATE PROCEDURE Sales.usp_RaiseDeptSalariesCapped
    @Department VARCHAR(50),
    @RaisePct DECIMAL(5,2),
    @MaxAvgSalary INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentAvg INT;
    SELECT @CurrentAvg = AVG(Salary) FROM Sales.Employees WHERE Department = @Department;

    WHILE @CurrentAvg < @MaxAvgSalary
    BEGIN
        UPDATE Sales.Employees
        SET Salary = Salary + (Salary * @RaisePct / 100)
        WHERE Department = @Department;

        SELECT @CurrentAvg = AVG(Salary) FROM Sales.Employees WHERE Department = @Department;
    END
END;
GO
EXEC Sales.usp_RaiseDeptSalariesCapped @Department = 'Marketing', @RaisePct = 5, @MaxAvgSalary = 65000;
GO

-- Task 35: Create a procedure that returns a text summary using nested
--          IF statements based on how many orders a customer has placed.
DROP PROCEDURE IF EXISTS Sales.usp_GetCustomerActivitySummary;
GO
CREATE PROCEDURE Sales.usp_GetCustomerActivitySummary
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OrderCount INT;
    SELECT @OrderCount = COUNT(*) FROM Sales.Orders WHERE CustomerID = @CustomerID;

    IF @OrderCount = 0
        SELECT 'Inactive customer (no orders)' AS Summary;
    ELSE IF @OrderCount BETWEEN 1 AND 2
        SELECT 'Occasional customer' AS Summary;
    ELSE
        SELECT 'Frequent customer' AS Summary;
END;
GO
EXEC Sales.usp_GetCustomerActivitySummary @CustomerID = 3;
GO


/* =============================================================================
   SECTION G — ERROR HANDLING: TRY/CATCH, THROW
   Robust procedures that anticipate and report failures gracefully.
============================================================================= */

-- Task 36: Create a procedure that inserts a customer inside TRY/CATCH,
--          reporting any error message instead of letting it propagate
--          raw.
DROP PROCEDURE IF EXISTS Sales.usp_SafeInsertCustomer;
GO
CREATE PROCEDURE Sales.usp_SafeInsertCustomer
    @CustomerID INT,
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @Country VARCHAR(50),
    @Score INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO Sales.Customers (CustomerID, FirstName, LastName, Country, Score)
        VALUES (@CustomerID, @FirstName, @LastName, @Country, @Score);
        PRINT 'Customer inserted successfully.';
    END TRY
    BEGIN CATCH
        PRINT 'Error inserting customer: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
EXEC Sales.usp_SafeInsertCustomer @CustomerID = 2, @FirstName = 'Dup', @LastName = 'Test', @Country = 'USA'; -- duplicate PK -> caught
GO

-- Task 37: Create a procedure that divides a customer's total Sales by a
--          given divisor, using TRY/CATCH to guard against divide-by-zero.
DROP PROCEDURE IF EXISTS Sales.usp_SafeDivideCustomerSales;
GO
CREATE PROCEDURE Sales.usp_SafeDivideCustomerSales
    @CustomerID INT,
    @Divisor INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT SUM(Sales) / @Divisor AS Result
        FROM Sales.Orders
        WHERE CustomerID = @CustomerID;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
EXEC Sales.usp_SafeDivideCustomerSales @CustomerID = 2, @Divisor = 0;
GO

-- Task 38: Create a procedure that validates a Price parameter and uses
--          THROW to raise a custom error if it's negative.
DROP PROCEDURE IF EXISTS Sales.usp_ValidateAndInsertProduct;
GO
CREATE PROCEDURE Sales.usp_ValidateAndInsertProduct
    @ProductID INT,
    @Product VARCHAR(50),
    @Category VARCHAR(50),
    @Price INT
AS
BEGIN
    SET NOCOUNT ON;
    IF @Price < 0
    BEGIN
        THROW 50001, 'Price cannot be negative.', 1;
    END

    INSERT INTO Sales.Products (ProductID, Product, Category, Price)
    VALUES (@ProductID, @Product, @Category, @Price);
END;
GO
BEGIN TRY
    EXEC Sales.usp_ValidateAndInsertProduct @ProductID = 107, @Product = 'Broken', @Category = 'Accessories', @Price = -5;
END TRY
BEGIN CATCH
    PRINT 'Caught: ' + ERROR_MESSAGE();
END CATCH
GO

-- Task 39: Create a procedure that deletes an order inside TRY/CATCH and
--          reports the affected row count via RAISERROR if nothing was
--          deleted.
DROP PROCEDURE IF EXISTS Sales.usp_SafeDeleteOrder;
GO
CREATE PROCEDURE Sales.usp_SafeDeleteOrder
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM Sales.Orders WHERE OrderID = @OrderID;
        IF @@ROWCOUNT = 0
            RAISERROR('No order found with the given OrderID.', 16, 1);
        ELSE
            PRINT 'Order deleted.';
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
EXEC Sales.usp_SafeDeleteOrder @OrderID = 9999;
GO

-- Task 40: Create a procedure that logs error details (number, message,
--          line) into a #temp result set when an update fails, using
--          ERROR_NUMBER/ERROR_LINE/ERROR_PROCEDURE.
DROP PROCEDURE IF EXISTS Sales.usp_UpdateProductPriceLogged;
GO
CREATE PROCEDURE Sales.usp_UpdateProductPriceLogged
    @ProductID INT,
    @NewPrice VARCHAR(20)  -- intentionally VARCHAR to allow bad input for the demo
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE Sales.Products
        SET Price = CAST(@NewPrice AS INT)
        WHERE ProductID = @ProductID;
    END TRY
    BEGIN CATCH
        SELECT
            ERROR_NUMBER()    AS ErrorNumber,
            ERROR_MESSAGE()   AS ErrorMessage,
            ERROR_LINE()      AS ErrorLine,
            ERROR_PROCEDURE() AS ErrorProcedure;
    END CATCH
END;
GO
EXEC Sales.usp_UpdateProductPriceLogged @ProductID = 101, @NewPrice = 'not-a-number';
GO

-- Task 41: Create a procedure that wraps an INSERT + UPDATE pair in
--          TRY/CATCH, rolling back any open transaction on error
--          (introductory pairing with Section H).
DROP PROCEDURE IF EXISTS Sales.usp_SafeInsertThenAdjustScore;
GO
CREATE PROCEDURE Sales.usp_SafeInsertThenAdjustScore
    @CustomerID INT,
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @Country VARCHAR(50),
    @InitialScore INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Sales.Customers (CustomerID, FirstName, LastName, Country, Score)
        VALUES (@CustomerID, @FirstName, @LastName, @Country, @InitialScore);

        UPDATE Sales.Customers
        SET Score = Score + 10
        WHERE CustomerID = @CustomerID;

        COMMIT TRANSACTION;
        PRINT 'Customer created and bonus score applied.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Transaction rolled back: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
EXEC Sales.usp_SafeInsertThenAdjustScore @CustomerID = 7, @FirstName = 'Omar', @LastName = 'Nabil', @Country = 'Egypt', @InitialScore = 400;
GO


/* =============================================================================
   SECTION H — TRANSACTIONS
   Explicit BEGIN/COMMIT/ROLLBACK TRANSACTION for multi-statement atomicity.
============================================================================= */

-- Task 42: Create a procedure that transfers "loyalty points" (Score)
--          between two customers atomically — deduct from one, add to the
--          other, both or neither.
DROP PROCEDURE IF EXISTS Sales.usp_TransferScore;
GO
CREATE PROCEDURE Sales.usp_TransferScore
    @FromCustomerID INT,
    @ToCustomerID INT,
    @Amount INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Sales.Customers SET Score = Score - @Amount WHERE CustomerID = @FromCustomerID;
        UPDATE Sales.Customers SET Score = Score + @Amount WHERE CustomerID = @ToCustomerID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Score transfer failed: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
EXEC Sales.usp_TransferScore @FromCustomerID = 2, @ToCustomerID = 4, @Amount = 50;
GO

-- Task 43: Create a procedure that moves an order to the archive and
--          deletes it from Orders as a single atomic transaction (safer
--          version of Task 29).
DROP PROCEDURE IF EXISTS Sales.usp_ArchiveOrderTransactional;
GO
CREATE PROCEDURE Sales.usp_ArchiveOrderTransactional
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Sales.OrdersArchive
            (OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, OrderStatus, ShipAddress, BillAddress, Quantity, Sales, CreationTime)
        SELECT
            OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, OrderStatus, ShipAddress, BillAddress, Quantity, Sales, CreationTime
        FROM Sales.Orders
        WHERE OrderID = @OrderID;

        DELETE FROM Sales.Orders WHERE OrderID = @OrderID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Archive failed, rolled back: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
EXEC Sales.usp_ArchiveOrderTransactional @OrderID = 10;
GO

-- Task 44: Create a procedure that raises a product's price and inserts an
--          audit-style record in the same transaction (using a local
--          #PriceChangeLog temp table to represent the audit trail within
--          the demo).
DROP PROCEDURE IF EXISTS Sales.usp_ChangePriceWithAudit;
GO
CREATE PROCEDURE Sales.usp_ChangePriceWithAudit
    @ProductID INT,
    @NewPrice INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @OldPrice INT;
        SELECT @OldPrice = Price FROM Sales.Products WHERE ProductID = @ProductID;

        UPDATE Sales.Products SET Price = @NewPrice WHERE ProductID = @ProductID;

        SELECT @ProductID AS ProductID, @OldPrice AS OldPrice, @NewPrice AS NewPrice, SYSDATETIME() AS ChangedAt;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Price change failed: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
EXEC Sales.usp_ChangePriceWithAudit @ProductID = 102, @NewPrice = 17;
GO

-- Task 45: Create a procedure demonstrating a partial ROLLBACK using a
--          SAVE TRANSACTION point: apply a bulk salary raise, but roll
--          back only the raise if the department's new average would
--          exceed a cap, keeping any earlier work in the batch.
DROP PROCEDURE IF EXISTS Sales.usp_ConditionalRaiseWithSavepoint;
GO
CREATE PROCEDURE Sales.usp_ConditionalRaiseWithSavepoint
    @Department VARCHAR(50),
    @RaisePct DECIMAL(5,2),
    @MaxAvgSalary INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    SAVE TRANSACTION BeforeRaise;

    UPDATE Sales.Employees
    SET Salary = Salary + (Salary * @RaisePct / 100)
    WHERE Department = @Department;

    IF (SELECT AVG(Salary) FROM Sales.Employees WHERE Department = @Department) > @MaxAvgSalary
    BEGIN
        ROLLBACK TRANSACTION BeforeRaise;
        PRINT 'Raise rolled back: would exceed department average cap.';
    END
    ELSE
    BEGIN
        PRINT 'Raise applied.';
    END

    COMMIT TRANSACTION;
END;
GO
EXEC Sales.usp_ConditionalRaiseWithSavepoint @Department = 'Sales', @RaisePct = 50, @MaxAvgSalary = 80000;
GO


/* =============================================================================
   SECTION I — DYNAMIC SQL
   Procedures that build and execute SQL text at runtime (e.g., for
   flexible sort columns or table names). Always validate/whitelist inputs
   used inside dynamic SQL to avoid injection.
============================================================================= */

-- Task 46: Create a procedure that returns all orders sorted by a
--          caller-supplied column name, validated against a whitelist.
DROP PROCEDURE IF EXISTS Sales.usp_GetOrdersSortedBy;
GO
CREATE PROCEDURE Sales.usp_GetOrdersSortedBy
    @SortColumn SYSNAME
AS
BEGIN
    SET NOCOUNT ON;

    IF @SortColumn NOT IN ('OrderDate', 'Sales', 'Quantity', 'OrderID')
    BEGIN
        RAISERROR('Invalid sort column.', 16, 1);
        RETURN;
    END

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'SELECT OrderID, CustomerID, OrderDate, Sales, Quantity FROM Sales.Orders ORDER BY ' + QUOTENAME(@SortColumn);
    EXEC sp_executesql @sql;
END;
GO
EXEC Sales.usp_GetOrdersSortedBy @SortColumn = 'Sales';
GO

-- Task 47: Create a procedure that dynamically filters Sales.Products by a
--          caller-supplied column/value pair, using sp_executesql with
--          parameters (safe from injection on the value side).
DROP PROCEDURE IF EXISTS Sales.usp_GetProductsDynamicFilter;
GO
CREATE PROCEDURE Sales.usp_GetProductsDynamicFilter
    @FilterColumn SYSNAME,
    @FilterValue VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FilterColumn NOT IN ('Category', 'Product')
    BEGIN
        RAISERROR('Invalid filter column.', 16, 1);
        RETURN;
    END

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'SELECT ProductID, Product, Category, Price FROM Sales.Products WHERE ' 
             + QUOTENAME(@FilterColumn) + N' = @Val';
    EXEC sp_executesql @sql, N'@Val VARCHAR(50)', @Val = @FilterValue;
END;
GO
EXEC Sales.usp_GetProductsDynamicFilter @FilterColumn = 'Category', @FilterValue = 'Clothing';
GO

-- Task 48: Create a procedure that dynamically queries either Sales.Orders
--          or Sales.OrdersArchive based on a caller-supplied table
--          switch, showing total Sales.
DROP PROCEDURE IF EXISTS Sales.usp_GetTotalSalesFromTable;
GO
CREATE PROCEDURE Sales.usp_GetTotalSalesFromTable
    @UseArchive BIT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TableName SYSNAME;
    SET @TableName = CASE WHEN @UseArchive = 1 THEN 'Sales.OrdersArchive' ELSE 'Sales.Orders' END;

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'SELECT SUM(Sales) AS TotalSales FROM ' + @TableName;
    EXEC sp_executesql @sql;
END;
GO
EXEC Sales.usp_GetTotalSalesFromTable @UseArchive = 1;
GO


/* =============================================================================
   SECTION J — CURSORS
   Row-by-row processing when set-based logic isn't practical.
============================================================================= */

-- Task 49: Create a procedure that uses a cursor to walk through every
--          product and print a formatted price announcement line for each.
DROP PROCEDURE IF EXISTS Sales.usp_AnnounceAllProductPrices;
GO
CREATE PROCEDURE Sales.usp_AnnounceAllProductPrices
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductName VARCHAR(50), @Price INT;

    DECLARE product_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT Product, Price FROM Sales.Products ORDER BY ProductID;

    OPEN product_cursor;
    FETCH NEXT FROM product_cursor INTO @ProductName, @Price;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT @ProductName + ' is priced at $' + CAST(@Price AS VARCHAR);
        FETCH NEXT FROM product_cursor INTO @ProductName, @Price;
    END

    CLOSE product_cursor;
    DEALLOCATE product_cursor;
END;
GO
EXEC Sales.usp_AnnounceAllProductPrices;
GO


/* =============================================================================
   SECTION K — TABLE-VALUED PARAMETERS & RETURN STATUS
   Pass a whole set of rows into a procedure, and use RETURN for a status
   code the caller can branch on.
============================================================================= */

-- Task 50: Create a table type and a procedure that accepts a list of
--          CustomerIDs via a Table-Valued Parameter, bulk-applies a score
--          bonus, and RETURNs a status code (0 = success, 1 = no rows
--          passed in).
DROP PROCEDURE IF EXISTS Sales.usp_BulkApplyScoreBonus;
GO
IF TYPE_ID(N'Sales.CustomerIDListType') IS NOT NULL
    DROP TYPE Sales.CustomerIDListType;
GO
CREATE TYPE Sales.CustomerIDListType AS TABLE
(
    CustomerID INT PRIMARY KEY
);
GO
CREATE PROCEDURE Sales.usp_BulkApplyScoreBonus
    @CustomerIDs Sales.CustomerIDListType READONLY,
    @Bonus INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM @CustomerIDs)
    BEGIN
        RETURN 1; -- no rows supplied
    END

    UPDATE c
    SET c.Score = c.Score + @Bonus
    FROM Sales.Customers c
    JOIN @CustomerIDs ids ON ids.CustomerID = c.CustomerID;

    RETURN 0; -- success
END;
GO
DECLARE @IDs Sales.CustomerIDListType;
INSERT INTO @IDs (CustomerID) VALUES (1), (2), (3);

DECLARE @StatusCode INT;
EXEC @StatusCode = Sales.usp_BulkApplyScoreBonus @CustomerIDs = @IDs, @Bonus = 25;
SELECT @StatusCode AS ProcedureStatus;
GO

/* =============================================================================
   END OF SCRIPT — 50 stored procedure tasks complete.
============================================================================= */
