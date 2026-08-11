USE MyDatabase;

/*===================================================================
  SECTION 1 - BASIC FILTERING AND AGGREGATION
===================================================================*/


/*
=====================================================================
TASK 01
Find all customers from the USA.
=====================================================================
*/

SELECT
    id,
    first_name,
    country,
    score
FROM customers
WHERE country = 'USA';
GO


/*
=====================================================================
TASK 02
Find customers with a score greater than 700.
=====================================================================
*/

SELECT
    id,
    first_name,
    country,
    score
FROM customers
WHERE score > 700
ORDER BY score DESC;
GO


/*
=====================================================================
TASK 03
Find customers with a score between 500 and 800.
=====================================================================
*/

SELECT
    id,
    first_name,
    country,
    score
FROM customers
WHERE score BETWEEN 500 AND 800
ORDER BY score DESC;
GO


/*
=====================================================================
TASK 04
Find customers from Egypt, USA, or Germany.
=====================================================================
*/

SELECT
    id,
    first_name,
    country,
    score
FROM customers
WHERE country IN ('Egypt', 'USA', 'Germany')
ORDER BY country, score DESC;
GO


/*
=====================================================================
TASK 05
Find the top 10 customers by score.
=====================================================================
*/

SELECT TOP 10
    id,
    first_name,
    country,
    score
FROM customers
ORDER BY score DESC;
GO


/*
=====================================================================
TASK 06
Find the average customer score.
=====================================================================
*/

SELECT
    AVG(score) AS average_score
FROM customers;
GO


/*
=====================================================================
TASK 07
Find the highest, lowest, and total customer score.
=====================================================================
*/

SELECT
    MAX(score) AS highest_score,
    MIN(score) AS lowest_score,
    SUM(score) AS total_score
FROM customers;
GO


/*
=====================================================================
TASK 08
Count customers by country.
=====================================================================
*/

SELECT
    country,
    COUNT(*) AS customer_count
FROM customers
GROUP BY country
ORDER BY customer_count DESC;
GO


/*
=====================================================================
TASK 09
Find the average score by country.
=====================================================================
*/

SELECT
    country,
    AVG(score) AS average_score
FROM customers
GROUP BY country
ORDER BY average_score DESC;
GO


/*
=====================================================================
TASK 10
Find countries with more than 10 customers.
=====================================================================
*/

SELECT
    country,
    COUNT(*) AS customer_count
FROM customers
GROUP BY country
HAVING COUNT(*) > 10
ORDER BY customer_count DESC;
GO


/*===================================================================
  SECTION 2 - SUBQUERIES
===================================================================*/


/*
=====================================================================
TASK 11
Find customers whose score is greater than the overall average score.
=====================================================================
*/

SELECT
    id,
    first_name,
    country,
    score
FROM customers
WHERE score >
(
    SELECT AVG(score)
    FROM customers
)
ORDER BY score DESC;
GO


/*
=====================================================================
TASK 12
Find customers with the highest score.
=====================================================================
*/

SELECT
    id,
    first_name,
    country,
    score
FROM customers
WHERE score =
(
    SELECT MAX(score)
    FROM customers
);
GO


/*
=====================================================================
TASK 13
Find customers whose score is below the average score.
=====================================================================
*/

SELECT
    id,
    first_name,
    country,
    score
FROM customers
WHERE score <
(
    SELECT AVG(score)
    FROM customers
)
ORDER BY score;
GO


/*
=====================================================================
TASK 14
Find customers from countries whose average score is greater than 650.
=====================================================================
*/

SELECT
    id,
    first_name,
    country,
    score
FROM customers
WHERE country IN
(
    SELECT country
    FROM customers
    GROUP BY country
    HAVING AVG(score) > 650
);
GO


/*
=====================================================================
TASK 15
Find the second-highest customer score.
=====================================================================
*/

SELECT MAX(score) AS second_highest_score
FROM customers
WHERE score <
(
    SELECT MAX(score)
    FROM customers
);
GO


/*===================================================================
  SECTION 3 - ORDERS
===================================================================*/


/*
=====================================================================
TASK 16
Find orders with sales greater than 100.
=====================================================================
*/

SELECT
    order_id,
    customer_id,
    order_date,
    sales
FROM orders
WHERE sales > 100
ORDER BY sales DESC;
GO


/*
=====================================================================
TASK 17
Find the highest-value order.
=====================================================================
*/

SELECT TOP 1
    order_id,
    customer_id,
    order_date,
    sales
FROM orders
ORDER BY sales DESC;
GO


/*
=====================================================================
TASK 18
Calculate total sales.
=====================================================================
*/

SELECT
    SUM(sales) AS total_sales
FROM orders;
GO


/*
=====================================================================
TASK 19
Calculate average order value.
=====================================================================
*/

SELECT
    AVG(CAST(sales AS DECIMAL(10,2))) AS average_order_value
FROM orders;
GO


/*
=====================================================================
TASK 20
Calculate total sales and number of orders by year.
=====================================================================
*/

SELECT
    YEAR(order_date) AS order_year,
    COUNT(*) AS total_orders,
    SUM(sales) AS total_sales
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year;
GO


/*
=====================================================================
TASK 21
Calculate monthly sales.
=====================================================================
*/

SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    COUNT(*) AS total_orders,
    SUM(sales) AS total_sales
FROM orders
GROUP BY
    YEAR(order_date),
    MONTH(order_date)
ORDER BY
    order_year,
    order_month;
GO


/*
=====================================================================
TASK 22
Find the month with the highest sales.
=====================================================================
*/

SELECT TOP 1
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales) AS total_sales
FROM orders
GROUP BY
    YEAR(order_date),
    MONTH(order_date)
ORDER BY total_sales DESC;
GO


/*
=====================================================================
TASK 23
Find orders placed during 2022.
=====================================================================
*/

SELECT
    order_id,
    customer_id,
    order_date,
    sales
FROM orders
WHERE YEAR(order_date) = 2022
ORDER BY order_date;
GO


/*
=====================================================================
TASK 24
Find orders with sales between 50 and 100.
=====================================================================
*/

SELECT
    order_id,
    customer_id,
    order_date,
    sales
FROM orders
WHERE sales BETWEEN 50 AND 100
ORDER BY sales DESC;
GO


/*
=====================================================================
TASK 25
Find the average sales by year.
=====================================================================
*/

SELECT
    YEAR(order_date) AS order_year,
    AVG(CAST(sales AS DECIMAL(10,2))) AS average_sales
FROM orders
GROUP BY YEAR(order_date)
ORDER BY order_year;
GO


/*===================================================================
  SECTION 4 - JOINS
===================================================================*/


/*
=====================================================================
TASK 26
Show customer information with their orders.
=====================================================================
*/

SELECT
    c.id,
    c.first_name,
    c.country,
    o.order_id,
    o.order_date,
    o.sales
FROM customers c
INNER JOIN orders o
    ON c.id = o.customer_id
ORDER BY c.id;
GO


/*
=====================================================================
TASK 27
Show all customers and their orders, including customers
who have never ordered.
=====================================================================
*/

SELECT
    c.id,
    c.first_name,
    c.country,
    o.order_id,
    o.order_date,
    o.sales
FROM customers c
LEFT JOIN orders o
    ON c.id = o.customer_id
ORDER BY c.id;
GO


/*
=====================================================================
TASK 28
Find customers who have never placed an order.
=====================================================================
*/

SELECT
    c.id,
    c.first_name,
    c.country
FROM customers c
LEFT JOIN orders o
    ON c.id = o.customer_id
WHERE o.order_id IS NULL;
GO


/*
=====================================================================
TASK 29
Find customers who have placed at least one order.
=====================================================================
*/

SELECT DISTINCT
    c.id,
    c.first_name,
    c.country
FROM customers c
INNER JOIN orders o
    ON c.id = o.customer_id;
GO


/*
=====================================================================
TASK 30
Calculate total sales for every customer.
=====================================================================
*/

SELECT
    c.id,
    c.first_name,
    c.country,
    COALESCE(SUM(o.sales), 0) AS total_sales
FROM customers c
LEFT JOIN orders o
    ON c.id = o.customer_id
GROUP BY
    c.id,
    c.first_name,
    c.country
ORDER BY total_sales DESC;
GO


/*
=====================================================================
TASK 31
Find customers with total sales greater than 100.
=====================================================================
*/

SELECT
    c.id,
    c.first_name,
    c.country,
    SUM(o.sales) AS total_sales
FROM customers c
INNER JOIN orders o
    ON c.id = o.customer_id
GROUP BY
    c.id,
    c.first_name,
    c.country
HAVING SUM(o.sales) > 100
ORDER BY total_sales DESC;
GO


/*
=====================================================================
TASK 32
Find total sales by country.
=====================================================================
*/

SELECT
    c.country,
    SUM(o.sales) AS total_sales
FROM customers c
INNER JOIN orders o
    ON c.id = o.customer_id
GROUP BY c.country
ORDER BY total_sales DESC;
GO


/*
=====================================================================
TASK 33
Find average order value by country.
=====================================================================
*/

SELECT
    c.country,
    AVG(CAST(o.sales AS DECIMAL(10,2))) AS average_order_value
FROM customers c
INNER JOIN orders o
    ON c.id = o.customer_id
GROUP BY c.country
ORDER BY average_order_value DESC;
GO


/*
=====================================================================
TASK 34
Find the customer with the highest total sales.
=====================================================================
*/

SELECT TOP 1
    c.id,
    c.first_name,
    c.country,
    SUM(o.sales) AS total_sales
FROM customers c
INNER JOIN orders o
    ON c.id = o.customer_id
GROUP BY
    c.id,
    c.first_name,
    c.country
ORDER BY total_sales DESC;
GO


/*
=====================================================================
TASK 35
Find the top 10 customers by total sales.
=====================================================================
*/

SELECT TOP 10
    c.id,
    c.first_name,
    c.country,
    SUM(o.sales) AS total_sales
FROM customers c
INNER JOIN orders o
    ON c.id = o.customer_id
GROUP BY
    c.id,
    c.first_name,
    c.country
ORDER BY total_sales DESC;
GO


/*===================================================================
  SECTION 5 - CASE EXPRESSIONS
===================================================================*/


/*
=====================================================================
TASK 36
Classify customers based on score:

900+    -> Excellent
700-899 -> Good
500-699 -> Average
Below 500 -> Low
=====================================================================
*/

SELECT
    id,
    first_name,
    country,
    score,

    CASE
        WHEN score >= 900 THEN 'Excellent'
        WHEN score >= 700 THEN 'Good'
        WHEN score >= 500 THEN 'Average'
        ELSE 'Low'
    END AS score_category

FROM customers
ORDER BY score DESC;
GO


/*
=====================================================================
TASK 37
Classify orders based on sales.
=====================================================================
*/

SELECT
    order_id,
    customer_id,
    sales,

    CASE
        WHEN sales >= 100 THEN 'High'
        WHEN sales >= 50 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category

FROM orders
ORDER BY sales DESC;
GO


/*
=====================================================================
TASK 38
Count customers by score category.
=====================================================================
*/

SELECT
    CASE
        WHEN score >= 900 THEN 'Excellent'
        WHEN score >= 700 THEN 'Good'
        WHEN score >= 500 THEN 'Average'
        ELSE 'Low'
    END AS score_category,

    COUNT(*) AS customer_count

FROM customers

GROUP BY
    CASE
        WHEN score >= 900 THEN 'Excellent'
        WHEN score >= 700 THEN 'Good'
        WHEN score >= 500 THEN 'Average'
        ELSE 'Low'
    END

ORDER BY customer_count DESC;
GO


/*
=====================================================================
TASK 39
Calculate high-value and low-value sales.
=====================================================================
*/

SELECT
    SUM(
        CASE
            WHEN sales >= 100 THEN sales
            ELSE 0
        END
    ) AS high_value_sales,

    SUM(
        CASE
            WHEN sales < 100 THEN sales
            ELSE 0
        END
    ) AS low_value_sales

FROM orders;
GO


/*
=====================================================================
TASK 40
Count customers by country using conditional aggregation.
=====================================================================
*/

SELECT
    COUNT(CASE WHEN country = 'Egypt' THEN 1 END) AS egypt_customers,
    COUNT(CASE WHEN country = 'USA' THEN 1 END) AS usa_customers,
    COUNT(CASE WHEN country = 'Germany' THEN 1 END) AS germany_customers,
    COUNT(CASE WHEN country = 'UK' THEN 1 END) AS uk_customers,
    COUNT(CASE WHEN country = 'Canada' THEN 1 END) AS canada_customers
FROM customers;
GO


/*===================================================================
  SECTION 6 - EMPLOYEES
===================================================================*/


/*
=====================================================================
TASK 41
Count employees by department.
=====================================================================
*/

SELECT
    department,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department
ORDER BY employee_count DESC;
GO


/*
=====================================================================
TASK 42
Calculate average salary by department.
=====================================================================
*/

SELECT
    department,
    AVG(CAST(salary AS DECIMAL(10,2))) AS average_salary
FROM employees
GROUP BY department
ORDER BY average_salary DESC;
GO


/*
=====================================================================
TASK 43
Find departments with average salary greater than 12000.
=====================================================================
*/

SELECT
    department,
    AVG(CAST(salary AS DECIMAL(10,2))) AS average_salary
FROM employees
GROUP BY department
HAVING AVG(salary) > 12000
ORDER BY average_salary DESC;
GO


/*
=====================================================================
TASK 44
Find employees earning more than the overall average salary.
=====================================================================
*/

SELECT
    employee_id,
    first_name,
    last_name,
    department,
    job_title,
    salary
FROM employees
WHERE salary >
(
    SELECT AVG(salary)
    FROM employees
)
ORDER BY salary DESC;
GO


/*
=====================================================================
TASK 45
Find the highest-paid employee.
=====================================================================
*/

SELECT TOP 1
    employee_id,
    first_name,
    last_name,
    department,
    job_title,
    salary
FROM employees
ORDER BY salary DESC;
GO


/*
=====================================================================
TASK 46
Find the highest-paid employee in each department.
=====================================================================
*/

WITH RankedEmployees AS
(
    SELECT
        employee_id,
        first_name,
        last_name,
        department,
        job_title,
        salary,

        ROW_NUMBER() OVER
        (
            PARTITION BY department
            ORDER BY salary DESC
        ) AS rn

    FROM employees
)

SELECT
    employee_id,
    first_name,
    last_name,
    department,
    job_title,
    salary
FROM RankedEmployees
WHERE rn = 1
ORDER BY salary DESC;
GO


/*
=====================================================================
TASK 47
Find the top 3 highest-paid employees in each department.
=====================================================================
*/

WITH RankedEmployees AS
(
    SELECT
        employee_id,
        first_name,
        last_name,
        department,
        job_title,
        salary,

        ROW_NUMBER() OVER
        (
            PARTITION BY department
            ORDER BY salary DESC
        ) AS rn

    FROM employees
)

SELECT
    employee_id,
    first_name,
    last_name,
    department,
    job_title,
    salary
FROM RankedEmployees
WHERE rn <= 3
ORDER BY
    department,
    salary DESC;
GO


/*
=====================================================================
TASK 48
Rank all employees by salary.
=====================================================================
*/

SELECT
    employee_id,
    first_name,
    last_name,
    department,
    salary,

    RANK() OVER
    (
        ORDER BY salary DESC
    ) AS salary_rank

FROM employees
ORDER BY salary_rank;
GO


/*
=====================================================================
TASK 49
Rank employees within each department.
=====================================================================
*/

SELECT
    employee_id,
    first_name,
    last_name,
    department,
    salary,

    RANK() OVER
    (
        PARTITION BY department
        ORDER BY salary DESC
    ) AS department_rank

FROM employees
ORDER BY
    department,
    department_rank;
GO


/*
=====================================================================
TASK 50
Show each employee's salary and department average salary.
=====================================================================
*/

SELECT
    employee_id,
    first_name,
    last_name,
    department,
    salary,

    AVG(salary) OVER
    (
        PARTITION BY department
    ) AS department_average_salary

FROM employees
ORDER BY
    department,
    salary DESC;
GO


/*===================================================================
  SECTION 7 - ADVANCED INTERMEDIATE WINDOW FUNCTIONS
===================================================================*/


/*
=====================================================================
TASK 51
Calculate the difference between employee salary and department
average salary.
=====================================================================
*/

SELECT
    employee_id,
    first_name,
    last_name,
    department,
    salary,

    AVG(salary) OVER
    (
        PARTITION BY department
    ) AS department_average_salary,

    salary -
    AVG(salary) OVER
    (
        PARTITION BY department
    ) AS salary_difference

FROM employees
ORDER BY
    department,
    salary_difference DESC;
GO


/*
=====================================================================
TASK 52
Find the second-highest-paid employee in every department.
=====================================================================
*/

WITH RankedEmployees AS
(
    SELECT
        employee_id,
        first_name,
        last_name,
        department,
        job_title,
        salary,

        ROW_NUMBER() OVER
        (
            PARTITION BY department
            ORDER BY salary DESC
        ) AS rn

    FROM employees
)

SELECT
    employee_id,
    first_name,
    last_name,
    department,
    job_title,
    salary
FROM RankedEmployees
WHERE rn = 2
ORDER BY
    department,
    salary DESC;
GO


/*
=====================================================================
TASK 53
Calculate the running total of employee salaries ordered by employee ID.
=====================================================================
*/

SELECT
    employee_id,
    first_name,
    department,
    salary,

    SUM(salary) OVER
    (
        ORDER BY employee_id
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS running_salary_total

FROM employees
ORDER BY employee_id;
GO


/*
=====================================================================
TASK 54
Show each employee's salary and the previous employee's salary.
=====================================================================
*/

SELECT
    employee_id,
    first_name,
    department,
    salary,

    LAG(salary) OVER
    (
        ORDER BY employee_id
    ) AS previous_salary

FROM employees
ORDER BY employee_id;
GO


/*
=====================================================================
TASK 55
Show each employee's salary and the next employee's salary.
=====================================================================
*/

SELECT
    employee_id,
    first_name,
    department,
    salary,

    LEAD(salary) OVER
    (
        ORDER BY employee_id
    ) AS next_salary

FROM employees
ORDER BY employee_id;
GO


/*
=====================================================================
TASK 56
Rank customers based on total sales.
=====================================================================
*/

WITH CustomerSales AS
(
    SELECT
        c.id,
        c.first_name,
        c.country,
        SUM(o.sales) AS total_sales

    FROM customers c

    INNER JOIN orders o
        ON c.id = o.customer_id

    GROUP BY
        c.id,
        c.first_name,
        c.country
)

SELECT
    id,
    first_name,
    country,
    total_sales,

    RANK() OVER
    (
        ORDER BY total_sales DESC
    ) AS sales_rank

FROM CustomerSales
ORDER BY sales_rank;
GO


/*
=====================================================================
TASK 57
Find the top 3 customers from each country based on total sales.
=====================================================================
*/

WITH CustomerSales AS
(
    SELECT
        c.id,
        c.first_name,
        c.country,
        SUM(o.sales) AS total_sales

    FROM customers c

    INNER JOIN orders o
        ON c.id = o.customer_id

    GROUP BY
        c.id,
        c.first_name,
        c.country
),

RankedCustomers AS
(
    SELECT
        id,
        first_name,
        country,
        total_sales,

        ROW_NUMBER() OVER
        (
            PARTITION BY country
            ORDER BY total_sales DESC
        ) AS rn

    FROM CustomerSales
)

SELECT
    id,
    first_name,
    country,
    total_sales
FROM RankedCustomers
WHERE rn <= 3
ORDER BY
    country,
    total_sales DESC;
GO


/*
=====================================================================
TASK 58
Create a complete customer sales report.

Include:
    Customer ID
    Customer Name
    Country
    Number of Orders
    Total Sales
    Average Order Value
=====================================================================
*/

SELECT
    c.id AS customer_id,
    c.first_name,
    c.country,

    COUNT(o.order_id) AS order_count,

    COALESCE(
        SUM(o.sales),
        0
    ) AS total_sales,

    COALESCE(
        AVG(CAST(o.sales AS DECIMAL(10,2))),
        0
    ) AS average_order_value

FROM customers c

LEFT JOIN orders o
    ON c.id = o.customer_id

GROUP BY
    c.id,
    c.first_name,
    c.country

ORDER BY total_sales DESC;
GO


/*
=====================================================================
TASK 59
Find customers whose total sales are higher than the average
customer total sales.

This requires:
    1. Calculate sales per customer.
    2. Calculate average customer sales.
    3. Compare each customer against that average.
=====================================================================
*/

WITH CustomerSales AS
(
    SELECT
        c.id,
        c.first_name,
        c.country,
        COALESCE(SUM(o.sales), 0) AS total_sales

    FROM customers c

    LEFT JOIN orders o
        ON c.id = o.customer_id

    GROUP BY
        c.id,
        c.first_name,
        c.country
),

AverageSales AS
(
    SELECT
        AVG(CAST(total_sales AS DECIMAL(10,2)))
        AS average_customer_sales
    FROM CustomerSales
)

SELECT
    cs.id,
    cs.first_name,
    cs.country,
    cs.total_sales,
    a.average_customer_sales
FROM CustomerSales cs
CROSS JOIN AverageSales a
WHERE cs.total_sales > a.average_customer_sales
ORDER BY cs.total_sales DESC;
GO


/*
=====================================================================
TASK 60
Create a final business report containing:

    Customer ID
    Customer Name
    Country
    Customer Score
    Number of Orders
    Total Sales
    Average Order Value
    Sales Rank
    Customer Category

Customer Category:
    >= 150 sales -> VIP
    >= 100 sales -> High Value
    >= 50 sales  -> Medium Value
    < 50         -> Low Value
=====================================================================
*/

WITH CustomerReport AS
(
    SELECT
        c.id AS customer_id,
        c.first_name,
        c.country,
        c.score,

        COUNT(o.order_id) AS order_count,

        COALESCE(
            SUM(o.sales),
            0
        ) AS total_sales,

        COALESCE(
            AVG(CAST(o.sales AS DECIMAL(10,2))),
            0
        ) AS average_order_value

    FROM customers c

    LEFT JOIN orders o
        ON c.id = o.customer_id

    GROUP BY
        c.id,
        c.first_name,
        c.country,
        c.score
),

RankedCustomers AS
(
    SELECT
        *,
        RANK() OVER
        (
            ORDER BY total_sales DESC
        ) AS sales_rank
    FROM CustomerReport
)

SELECT
    customer_id,
    first_name,
    country,
    score,
    order_count,
    total_sales,
    average_order_value,
    sales_rank,

    CASE
        WHEN total_sales >= 150 THEN 'VIP'
        WHEN total_sales >= 100 THEN 'High Value'
        WHEN total_sales >= 50 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_category

FROM RankedCustomers

ORDER BY sales_rank;
GO

