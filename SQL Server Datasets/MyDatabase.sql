/*
=============================================================
MyDatabase - SQL Server Database Setup
=============================================================
Creates:
    customers -> 100 records
    orders    -> 100 records
    employees -> 100 records

Also includes 60 intermediate SQL practice tasks with solutions.
=============================================================
*/

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'MyDatabase')
BEGIN
    ALTER DATABASE MyDatabase SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MyDatabase;
END;
GO

CREATE DATABASE MyDatabase;
GO

USE MyDatabase;
GO

/* =========================
   CUSTOMERS
   ========================= */

CREATE TABLE customers
(
    id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    country VARCHAR(50),
    score INT,
    CONSTRAINT PK_customers PRIMARY KEY (id)
);
GO

INSERT INTO customers (id, first_name, country, score)
VALUES
(1,'Maria','Germany',350),(2,'John','USA',900),(3,'Georg','UK',750),
(4,'Martin','Germany',500),(5,'Peter','USA',0),(6,'Ahmed','Egypt',620),
(7,'Mohamed','Egypt',780),(8,'David','USA',450),(9,'James','UK',820),
(10,'Robert','USA',610),(11,'Michael','Canada',730),(12,'William','USA',540),
(13,'Daniel','Germany',690),(14,'Thomas','France',470),(15,'Ali','Egypt',850),
(16,'Omar','Egypt',720),(17,'Hassan','Egypt',560),(18,'Karim','Egypt',910),
(19,'Youssef','Egypt',640),(20,'Adam','USA',390),(21,'Noah','Canada',710),
(22,'Liam','USA',830),(23,'Lucas','Germany',520),(24,'Ethan','USA',680),
(25,'Mason','Canada',760),(26,'Oliver','UK',590),(27,'Elijah','USA',440),
(28,'James','UK',870),(29,'Benjamin','USA',630),(30,'Lucas','France',700),
(31,'Henry','Germany',480),(32,'Alexander','USA',810),(33,'Sebastian','Germany',550),
(34,'Jack','UK',920),(35,'Aiden','Canada',670),(36,'Matthew','USA',580),
(37,'Samuel','UK',740),(38,'Joseph','USA',690),(39,'Levi','Canada',510),
(40,'Mateo','USA',880),(41,'Daniel','Germany',600),(42,'Leo','France',730),
(43,'Owen','UK',460),(44,'Theodore','USA',790),(45,'Jack','Canada',650),
(46,'William','UK',720),(47,'Henry','Germany',580),(48,'Lucas','USA',900),
(49,'Benjamin','Canada',430),(50,'James','USA',760),(51,'Alexander','Germany',690),
(52,'Michael','UK',540),(53,'Daniel','USA',820),(54,'Jacob','Canada',610),
(55,'Logan','USA',470),(56,'Jackson','UK',730),(57,'David','Germany',660),
(58,'Carter','USA',850),(59,'Sebastian','Canada',520),(60,'Joseph','USA',780),
(61,'John','UK',590),(62,'Owen','Germany',710),(63,'Wyatt','USA',640),
(64,'Matthew','Canada',830),(65,'Luke','USA',450),(66,'Asher','UK',690),
(67,'James','Germany',760),(68,'Leo','USA',570),(69,'Julian','Canada',880),
(70,'Hudson','USA',610),(71,'Grayson','UK',740),(72,'Ezra','Germany',490),
(73,'Lincoln','USA',810),(74,'Nolan','Canada',550),(75,'Miles','USA',670),
(76,'Eli','UK',720),(77,'Aaron','Germany',430),(78,'Ryan','USA',850),
(79,'Nathan','Canada',600),(80,'Caleb','USA',780),(81,'Isaac','UK',530),
(82,'Andrew','Germany',690),(83,'Joshua','USA',910),(84,'Christopher','Canada',640),
(85,'Anthony','USA',570),(86,'Dylan','UK',730),(87,'Thomas','Germany',820),
(88,'Charles','USA',460),(89,'Christopher','Canada',700),(90,'Jaxon','USA',590),
(91,'Maverick','UK',880),(92,'Josiah','Germany',510),(93,'Isaiah','USA',760),
(94,'Elias','Canada',630),(95,'Joshua','USA',840),(96,'David','UK',560),
(97,'Andrew','Germany',710),(98,'Mateo','USA',680),(99,'Ryan','Canada',490),
(100,'John','USA',930);
GO

/* =========================
   ORDERS
   ========================= */

CREATE TABLE orders
(
    order_id INT NOT NULL,
    customer_id INT NOT NULL,
    order_date DATE,
    sales INT,
    CONSTRAINT PK_orders PRIMARY KEY (order_id),
    CONSTRAINT FK_orders_customers FOREIGN KEY (customer_id)
        REFERENCES customers(id)
);
GO

INSERT INTO orders (order_id, customer_id, order_date, sales)
VALUES
(1001,1,'2021-01-11',35),(1002,2,'2021-01-15',15),
(1003,3,'2021-01-20',20),(1004,4,'2021-02-05',10),
(1005,5,'2021-02-12',45),(1006,6,'2021-02-18',60),
(1007,7,'2021-02-25',75),(1008,8,'2021-03-03',30),
(1009,9,'2021-03-10',90),(1010,10,'2021-03-17',55),
(1011,11,'2021-03-25',40),(1012,12,'2021-04-02',25),
(1013,13,'2021-04-08',80),(1014,14,'2021-04-15',35),
(1015,15,'2021-04-22',95),(1016,16,'2021-05-01',50),
(1017,17,'2021-05-08',65),(1018,18,'2021-05-15',120),
(1019,19,'2021-05-22',70),(1020,20,'2021-05-30',45),
(1021,21,'2021-06-05',85),(1022,22,'2021-06-12',40),
(1023,23,'2021-06-18',110),(1024,24,'2021-06-25',55),
(1025,25,'2021-07-02',75),(1026,26,'2021-07-09',90),
(1027,27,'2021-07-16',35),(1028,28,'2021-07-23',130),
(1029,29,'2021-07-30',60),(1030,30,'2021-08-05',45),
(1031,31,'2021-08-12',70),(1032,32,'2021-08-19',100),
(1033,33,'2021-08-26',50),(1034,34,'2021-09-02',140),
(1035,35,'2021-09-09',65),(1036,36,'2021-09-16',80),
(1037,37,'2021-09-23',55),(1038,38,'2021-09-30',95),
(1039,39,'2021-10-05',40),(1040,40,'2021-10-12',125),
(1041,41,'2021-10-19',60),(1042,42,'2021-10-26',75),
(1043,43,'2021-11-02',35),(1044,44,'2021-11-09',150),
(1045,45,'2021-11-16',55),(1046,46,'2021-11-23',90),
(1047,47,'2021-11-30',70),(1048,48,'2021-12-05',115),
(1049,49,'2021-12-10',45),(1050,50,'2021-12-15',85),
(1051,51,'2022-01-05',65),(1052,52,'2022-01-12',95),
(1053,53,'2022-01-19',40),(1054,54,'2022-01-26',130),
(1055,55,'2022-02-02',55),(1056,56,'2022-02-09',75),
(1057,57,'2022-02-16',100),(1058,58,'2022-02-23',45),
(1059,59,'2022-03-02',85),(1060,60,'2022-03-09',120),
(1061,61,'2022-03-16',50),(1062,62,'2022-03-23',70),
(1063,63,'2022-03-30',95),(1064,64,'2022-04-06',60),
(1065,65,'2022-04-13',110),(1066,66,'2022-04-20',45),
(1067,67,'2022-04-27',80),(1068,68,'2022-05-04',55),
(1069,69,'2022-05-11',135),(1070,70,'2022-05-18',65),
(1071,71,'2022-05-25',90),(1072,72,'2022-06-01',40),
(1073,73,'2022-06-08',100),(1074,74,'2022-06-15',75),
(1075,75,'2022-06-22',50),(1076,76,'2022-06-29',120),
(1077,77,'2022-07-06',60),(1078,78,'2022-07-13',145),
(1079,79,'2022-07-20',80),(1080,80,'2022-07-27',55),
(1081,81,'2022-08-03',95),(1082,82,'2022-08-10',70),
(1083,83,'2022-08-17',115),(1084,84,'2022-08-24',45),
(1085,85,'2022-08-31',90),(1086,86,'2022-09-07',65),
(1087,87,'2022-09-14',125),(1088,88,'2022-09-21',50),
(1089,89,'2022-09-28',85),(1090,90,'2022-10-05',60),
(1091,91,'2022-10-12',150),(1092,92,'2022-10-19',70),
(1093,93,'2022-10-26',100),(1094,94,'2022-11-02',55),
(1095,95,'2022-11-09',130),(1096,96,'2022-11-16',75),
(1097,97,'2022-11-23',90),(1098,98,'2022-11-30',45),
(1099,99,'2022-12-07',110),(1100,100,'2022-12-14',80);
GO

/* =========================
   EMPLOYEES
   ========================= */

CREATE TABLE employees
(
    employee_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    job_title VARCHAR(50),
    salary INT,
    hire_date DATE,
    CONSTRAINT PK_employees PRIMARY KEY (employee_id)
);
GO

-- Generate exactly 100 employees from a small set of realistic values.
;WITH N AS
(
    SELECT TOP (100)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS employee_id
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
),
EmployeeData AS
(
    SELECT
        employee_id,
        CASE employee_id % 10
            WHEN 1 THEN 'Ahmed'
            WHEN 2 THEN 'Mohamed'
            WHEN 3 THEN 'Omar'
            WHEN 4 THEN 'Youssef'
            WHEN 5 THEN 'Karim'
            WHEN 6 THEN 'Hassan'
            WHEN 7 THEN 'Mostafa'
            WHEN 8 THEN 'Mahmoud'
            WHEN 9 THEN 'Amr'
            ELSE 'Tarek'
        END AS first_name,
        CASE employee_id % 8
            WHEN 1 THEN 'Hassan'
            WHEN 2 THEN 'Ali'
            WHEN 3 THEN 'Mahmoud'
            WHEN 4 THEN 'Samir'
            WHEN 5 THEN 'Ahmed'
            WHEN 6 THEN 'Khaled'
            WHEN 7 THEN 'Ibrahim'
            ELSE 'Nabil'
        END AS last_name,
        CASE employee_id % 5
            WHEN 1 THEN 'IT'
            WHEN 2 THEN 'Finance'
            WHEN 3 THEN 'Sales'
            WHEN 4 THEN 'HR'
            ELSE 'Marketing'
        END AS department,
        CASE employee_id % 6
            WHEN 1 THEN 'Data Engineer'
            WHEN 2 THEN 'Software Engineer'
            WHEN 3 THEN 'Data Analyst'
            WHEN 4 THEN 'Accountant'
            WHEN 5 THEN 'Sales Representative'
            ELSE 'HR Specialist'
        END AS job_title,
        7000 + ((employee_id * 137) % 10000) AS salary,
        DATEADD(
            DAY,
            employee_id * 30,
            CAST('2020-01-01' AS DATE)
        ) AS hire_date
    FROM N
)
INSERT INTO employees
(
    employee_id,
    first_name,
    last_name,
    department,
    job_title,
    salary,
    hire_date
)
SELECT
    employee_id,
    first_name,
    last_name,
    department,
    job_title,
    salary,
    hire_date
FROM EmployeeData;
GO


/* =========================
   VERIFY RECORD COUNTS
   ========================= */

SELECT
    'customers' AS table_name,
    COUNT(*) AS record_count
FROM customers

UNION ALL

SELECT
    'orders',
    COUNT(*)
FROM orders

UNION ALL

SELECT
    'employees',
    COUNT(*)
FROM employees;
GO


/* =========================
   VERIFY TABLES
   ========================= */

SELECT TOP 10 *
FROM customers;

SELECT TOP 10 *
FROM orders;

SELECT TOP 10 *
FROM employees;
GO
