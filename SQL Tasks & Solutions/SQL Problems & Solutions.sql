USE SalesDB;
GO

/*
	QUESTION:
		The sales team needs a report showing the most recent order
		placed by each customer.

		If a customer has multiple orders, only return their latest order.
		Use the ROW_NUMBER() window function to rank each customer's orders
		from the newest order to the oldest, then return only the order
		with rank 1 for each customer.
*/

WITH RankOrders AS (
	SELECT
		OrderID,
		CustomerID,
		OrderDate,
		Sales,
		ROW_NUMBER() OVER(
			PARTITION BY CustomerID 
			ORDER BY OrderDate DESC, OrderID DESC
		) AS rn 
	FROM Sales.Orders
)
SELECT *
FROM RankOrders
WHERE rn = 1;
GO


/*
	QUESTION:
		The sales management team wants to rank customers based on
		their total sales.

		Calculate the total sales amount for each customer, then rank
		all customers from the highest total sales to the lowest.

		Customers with the same total sales should receive the same rank.

		Finally, display the customers in order of their sales rank.
*/
WITH RankSales AS (
	SELECT 
		CustomerID,
		SUM(Sales) AS TotalSales
	FROM Sales.Orders
	GROUP BY CustomerID
)
SELECT 
	CustomerID,
	TotalSales,
	RANK() OVER(ORDER BY TotalSales DESC) AS SalesRank 
FROM RankSales
ORDER BY SalesRank;
GO



 /*
    QUESTION:
        The HR team wants to analyze employee salaries within
        each department.

        Rank employees within their own department based on salary,
        from the highest salary to the lowest salary.

        Employees with the same salary should receive the same rank.

        Finally, display the results grouped by department and
        ordered by salary rank.
*/
SELECT 
	EmployeeID,
	FirstName,
	LastName,
	Department,
	Salary,
	RANk() OVER(PARTITION BY Department ORDER BY Salary DESC) AS SalaryRank
FROM Sales.Employees
ORDER BY Department, SalaryRank;
GO


 /*
    QUESTION:
        Management wants to identify the three highest-paid
        employees in each department.

        For every employee, calculate their salary ranking
        within their department, starting from the highest salary.

        Return only the top 3 employees from each department.

        Finally, display the employees grouped by department and
        ordered from the highest salary to the lowest salary
        within each department.

        Use the ROW_NUMBER() window function to solve the problem.
*/
WITH RankEmployees AS (
	SELECT 
		EmployeeID,
		FirstName,
		LastName,
		Department,
		Salary,
		ROW_NUMBER() OVER(
			PARTITION BY Department
			ORDER BY Salary DESC
		) AS rn
	FROM Sales.Employees
)
SELECT *
FROM RankEmployees
WHERE rn <= 3
ORDER BY Department, Salary DESC;
GO


 /*
    QUESTION:
        The sales team wants to analyze the ordering behavior
        of each customer.

        For each customer, find the date of their previous order
        using the LAG() window function.

        Orders should be evaluated chronologically for each customer.

        If an order is the customer's first order, PreviousOrderDate
        should be NULL.

        Finally, display the results showing each order alongside
        the date of the customer's previous order.
*/
SELECT 
	OrderID,
	CustomerID,
	OrderDate,
	Sales,
	LAG(OrderDate) OVER(
		PARTITION BY CustomerID
		ORDER BY OrderDate, OrderID
	) AS PreviousOrderDate 
FROM Sales.Orders;
GO


 /*
    QUESTION:
        The sales team wants to understand how frequently
        customers place orders.

        For each order, find the date of the customer's
        previous order using the LAG() window function.

        Then calculate the number of days between the current
        order and the customer's previous order.

        If the order is the customer's first order,
        PreviousOrderDate and DaysSincePreviousOrder should be NULL.

        Use DATEDIFF() to calculate the number of days between
        the previous order date and the current order date.
*/
WITH OrdersWithPrevious AS (
	SELECT 
		OrderID,
		CustomerID,
		OrderDate,
		LAG(OrderDate) OVER(
			PARTITION BY CustomerID
			ORDER BY OrderDate 
		) AS PreviousOrderDate
	FROM Sales.Orders
)
SELECT
	*,
	DATEDIFF(
		DAY,
		PreviousOrderDate,
		OrderDate
	) AS DaysSincePreviousOrder
FROM OrdersWithPrevious;
GO

/*
    Question
        A sales manager wants to track how much each customer
        has spent over time.

        Calculate the running total of the order Amount for each customer.
*/
SELECT
    OrderID,
    CustomerID,
    OrderDate,
    Sales,
    SUM(Sales) OVER(
        PARTITION BY CustomerID
        ORDER BY OrderDate, OrderID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS TotalSales
FROM Sales.Orders
ORDER BY 
    CustomerID,
    OrderDate,
    OrderID;
GO


-- The analytics team wants to display every order along with the customer's average order value.
SELECT
	OrderID,
	CustomerID,
	OrderDate,
	Sales,
	AVG(Sales) OVER(
		PARTITION BY CustomerID
	) AS AverageSales
FROM Sales.Orders;
GO



-- The data engineering team suspects that duplicate records exist. 
-- Find orders with the same CustomerID and OrderDate.
WITH DuplicateCheck AS (
	SELECT 
		OrderID,
		CustomerID,
		OrderDate,
		Sales,
		COUNT(*) OVER(
			PARTITION BY CustomerID, OrderDate
		) AS DuplicateCount
	FROM Sales.Orders
)
SELECT *
FROM DuplicateCheck
WHERE DuplicateCount > 1;
GO



-- Your source system contains duplicate records. 
-- For each combination of CustomerID and OrderDate, keep only the latest OrderID
WITH DuplicateOrders AS (
	SELECT 
		OrderID,
		CustomerID,
		OrderDate,
		Sales,
		ROW_NUMBER() OVER(
			PARTITION BY CustomerID, OrderDate
			ORDER BY OrderID DESC
		) AS RankOrders
	FROM Sales.Orders
)
SELECT *
FROM DuplicateOrders
WHERE RankOrders = 1;

