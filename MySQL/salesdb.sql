-- =============================================================
-- MySQL Database Creation and Table Setup Script
-- =============================================================
-- This is an EXPANDED version of the original salesdb script,
-- generated with a larger synthetic dataset for load-testing,
-- practicing SQL/PySpark queries at scale, and interview prep.
--
-- Dataset sizes in this script:
--   customers       : 300
--   employees       : 40
--   products        : 60
--   orders          : 3000
--   orders_archive  : 800
--
-- WARNING:
-- This script assumes you are connected with a user that has
-- privileges to drop/create databases and tables.
-- =============================================================

-- DROP AND CREATE DATABASE
DROP DATABASE IF EXISTS `salesdb`;
CREATE DATABASE `salesdb` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `salesdb`;

-- ======================================================
-- Table: customers
-- ======================================================
-- Holds one row per customer. `score` is a loyalty/credit
-- style score and is nullable to simulate real-world gaps.
CREATE TABLE `customers` (
  `customerid` INT NOT NULL PRIMARY KEY,   -- surrogate key
  `firstname` VARCHAR(50),                 -- can repeat across customers
  `lastname` VARCHAR(50),                  -- nullable (data-quality gap)
  `country` VARCHAR(50),                   -- used for grouping/filtering exercises
  `score` INT                              -- nullable on purpose
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Bulk insert of customer records (see CONFIG section above for count)
INSERT INTO `customers` (`customerid`,`firstname`,`lastname`,`country`,`score`) VALUES
  (1, 'Layla', 'Adams', 'Germany', 300),
  (2, 'Nadia', 'Lee', 'Jordan', 808),
  (3, 'Noah', 'Schwarz', 'Spain', 80),
  (4, 'Frank', 'Baker', 'UAE', 77),
  (5, 'Amelia', 'Baker', 'Jordan', 608),
  (6, 'Matthew', 'Smith', 'Saudi Arabia', 878),
  (7, 'Jossef', 'Thomas', 'Qatar', 482),
  (8, 'Emily', 'Johnson', 'Egypt', 831),
  (9, 'Emily', 'Adams', 'USA', 417),
  (10, 'James', 'Aziz', 'France', 797),
  (11, 'Isabella', 'Farouk', 'USA', 437),
  (12, 'Frank', 'Farouk', 'France', 683),
  (13, 'Sophia', 'ElSayed', 'UAE', 96),
  (14, 'Fatima', 'Smith', 'Qatar', 131),
  (15, 'Nadia', 'Harris', 'USA', 514),
  (16, 'Layla', 'White', 'UK', 413),
  (17, 'Youssef', 'Moore', 'France', 749),
  (18, 'Ahmed', 'Schwarz', 'Spain', 596),
  (19, 'Rania', 'Smith', 'Egypt', 326),
  (20, 'Layla', 'Taylor', 'Italy', 382),
  (21, 'Ziad', 'Thomas', 'Germany', 82),
  (22, 'John', 'Garcia', 'France', NULL),
  (23, 'Lucas', 'Martin', 'Jordan', 721),
  (24, 'Mia', 'Garcia', 'Netherlands', 519),
  (25, 'David', 'Johnson', 'Egypt', 624),
  (26, 'Noah', 'Johnson', 'Jordan', 969),
  (27, 'Harper', 'Garcia', 'UK', 191),
  (28, 'Ethan', 'Ibrahim', 'USA', 931),
  (29, 'Carol', 'Lee', 'Morocco', 746),
  (30, 'Ava', 'Aziz', 'USA', 660),
  (31, 'Isabella', 'Mostafa', 'France', 931),
  (32, 'Jossef', 'Moore', 'Jordan', 956),
  (33, 'Noah', 'Thomas', 'France', 398),
  (34, 'Carol', 'Williams', 'Canada', 53),
  (35, 'Rania', 'Martin', 'Jordan', 562),
  (36, 'Hoda', 'Ray', 'Italy', 941),
  (37, 'Layla', 'Williams', 'Kuwait', 673),
  (38, 'Lina', 'Lee', 'UK', 602),
  (39, 'Ziad', 'Thompson', 'Italy', 663),
  (40, 'John', 'Ibrahim', 'Germany', 421),
  (41, 'Tarek', 'Smith', 'Germany', 630),
  (42, 'Frank', 'Schwarz', 'Jordan', 120),
  (43, 'Hoda', 'Farouk', 'Qatar', 725),
  (44, 'Ryan', NULL, 'Italy', 590),
  (45, 'Mason', 'Martinez', 'UAE', 823),
  (46, 'Rania', 'Taylor', 'UAE', 458),
  (47, 'Fatima', 'Wilson', 'UK', 579),
  (48, 'Andrew', 'Adams', 'UAE', 396),
  (49, 'Kevin', 'ElSayed', 'Italy', 275),
  (50, 'Jossef', 'Schwarz', 'Jordan', 284),
  (51, 'Anna', 'Martin', 'Germany', 122),
  (52, 'Ethan', 'Smith', 'France', 269),
  (53, 'Noah', 'Lee', 'Jordan', 634),
  (54, 'Lucas', 'Ibrahim', 'UAE', 876),
  (55, 'Matthew', 'Baker', 'USA', NULL),
  (56, 'Ava', 'Davis', 'Canada', 934),
  (57, 'Rania', 'Brown', 'Morocco', 711),
  (58, 'Michael', 'Brown', 'Canada', 869),
  (59, 'Michael', 'Smith', 'UAE', 509),
  (60, 'Laura', 'Martinez', 'Egypt', 305),
  (61, 'Anna', 'Hassan', 'Qatar', 613),
  (62, 'Michael', 'Brown', 'Morocco', 906),
  (63, 'Jossef', 'Schwarz', 'Netherlands', 292),
  (64, 'Sara', 'Martinez', 'Saudi Arabia', 935),
  (65, 'Olivia', 'Martin', 'Germany', 52),
  (66, 'Daniel', 'Johnson', 'Netherlands', 515),
  (67, 'Mona', 'Martinez', 'Jordan', 852),
  (68, 'Amelia', 'Moore', 'Jordan', 244),
  (69, 'Mona', 'Baker', 'Germany', 605),
  (70, 'Mark', 'Anderson', 'UK', NULL),
  (71, 'Harper', 'Ibrahim', 'Italy', 593),
  (72, 'Sara', 'Brown', 'Italy', NULL),
  (73, 'Omar', 'Schwarz', 'Spain', NULL),
  (74, 'Karim', 'Garcia', 'USA', 633),
  (75, 'Karim', 'ElSayed', 'Spain', NULL),
  (76, 'Frank', 'Martinez', 'Morocco', 585),
  (77, 'John', 'Thompson', 'France', 783),
  (78, 'John', 'Smith', 'France', 737),
  (79, 'Ahmed', 'Williams', 'Saudi Arabia', 819),
  (80, 'Anna', 'Goldberg', 'Saudi Arabia', 626),
  (81, 'Michael', 'Schwarz', 'Italy', 321),
  (82, 'Laura', 'Thompson', 'UK', 950),
  (83, 'Karim', 'Davis', 'France', 903),
  (84, 'Noah', 'Taylor', 'France', 876),
  (85, 'Ahmed', 'Mostafa', 'Germany', 617),
  (86, 'Tarek', 'Thompson', 'Morocco', 949),
  (87, 'Laura', 'Johnson', 'USA', 810),
  (88, 'Amelia', 'Lee', 'France', 265),
  (89, 'Sami', 'Miller', 'UAE', 923),
  (90, 'Salma', 'Mostafa', 'Saudi Arabia', 979),
  (91, 'Mark', 'Schwarz', 'Morocco', 333),
  (92, 'Mary', 'Goldberg', 'UK', 702),
  (93, 'Salma', 'Ray', 'Jordan', 772),
  (94, 'Ava', 'Farouk', 'Germany', 954),
  (95, 'Yasmin', 'Martin', 'Egypt', 904),
  (96, 'Sophia', 'ElSayed', 'Italy', 180),
  (97, 'Mary', 'Williams', 'UK', 865),
  (98, 'Mary', 'Martin', 'UK', 305),
  (99, 'Fatima', 'Adams', 'UK', 955),
  (100, 'Matthew', 'Aziz', 'Jordan', 292),
  (101, 'Sara', 'Jackson', 'Qatar', 472),
  (102, 'Kevin', 'Ray', 'Jordan', 851),
  (103, 'Matthew', 'Jackson', 'Morocco', 880),
  (104, 'Karim', 'Johnson', 'Egypt', 160),
  (105, 'Daniel', 'Harris', 'Germany', 277),
  (106, 'Lina', 'White', 'Netherlands', 362),
  (107, 'Nadia', 'Smith', 'Germany', 458),
  (108, 'Emily', 'Johnson', 'Kuwait', NULL),
  (109, 'Ziad', 'Johnson', 'UK', 459),
  (110, 'Ali', 'White', 'Italy', 78),
  (111, 'Carol', 'Martin', 'France', 321),
  (112, 'Mary', 'Adams', 'Spain', 796),
  (113, 'John', 'Martinez', 'Spain', 168),
  (114, 'Daniel', 'Martin', 'Spain', 95),
  (115, 'Sami', 'Martinez', 'Germany', 875),
  (116, 'Noah', 'Moore', 'Jordan', 804),
  (117, 'Fatima', 'Baker', 'UK', 730),
  (118, 'Emily', 'Aziz', 'UK', 177),
  (119, 'Rania', 'Martin', 'France', 732),
  (120, 'Matthew', 'Miller', 'Canada', 617),
  (121, 'Laura', 'Baker', 'Canada', 438),
  (122, 'Ali', 'Anderson', 'Netherlands', 632),
  (123, 'Tarek', 'Garcia', 'Italy', 361),
  (124, 'Mona', 'Baker', 'Canada', 671),
  (125, 'Ahmed', 'Miller', 'Saudi Arabia', 741),
  (126, 'Youssef', 'Mostafa', 'Saudi Arabia', 865),
  (127, 'Adel', 'Ray', 'Morocco', NULL),
  (128, 'Ethan', 'Moore', 'Morocco', 145),
  (129, 'Hoda', 'Smith', 'Morocco', 875),
  (130, 'Lina', 'Lee', 'Germany', NULL),
  (131, 'Ryan', 'Aziz', 'Kuwait', 516),
  (132, 'Matthew', 'Martin', 'Morocco', 785),
  (133, 'Yasmin', 'Garcia', 'Saudi Arabia', 201),
  (134, 'Ahmed', 'Taylor', 'Germany', 931),
  (135, 'Ziad', 'Martin', 'USA', 274),
  (136, 'Omar', 'Jackson', 'Jordan', 101),
  (137, 'Amelia', 'Smith', 'Netherlands', 517),
  (138, 'Laura', 'Jackson', 'Saudi Arabia', 622),
  (139, 'Mason', 'Miller', 'Qatar', 677),
  (140, 'Rania', 'Martin', 'Italy', 978),
  (141, 'Amelia', 'Hassan', 'Netherlands', 932),
  (142, 'Ryan', 'Hassan', 'France', 910),
  (143, 'Layla', 'Johnson', 'Qatar', 546),
  (144, 'Layla', 'Smith', 'France', 780),
  (145, 'Mona', 'Smith', 'France', 964),
  (146, 'Noah', 'Schwarz', 'Egypt', 442),
  (147, 'Yasmin', 'Lee', 'Jordan', 474),
  (148, 'Matthew', 'Miller', 'Italy', 113),
  (149, 'Youssef', 'White', 'Canada', 838),
  (150, 'Harper', NULL, 'Jordan', NULL),
  (151, 'Hoda', 'ElSayed', 'Canada', 410),
  (152, 'Tarek', 'Thomas', 'Canada', 905),
  (153, 'Matthew', 'Farouk', 'Jordan', 869),
  (154, 'Mason', 'Martin', 'UAE', 329),
  (155, 'Ava', 'Ibrahim', 'Germany', 734),
  (156, 'Ali', 'Jackson', 'Canada', 910),
  (157, 'Isabella', 'Thompson', 'Egypt', 596),
  (158, 'Kevin', 'Thompson', 'Canada', 728),
  (159, 'Kevin', 'Schwarz', 'Morocco', 937),
  (160, 'Isabella', 'Ray', 'Germany', 385),
  (161, 'Youssef', 'Hassan', 'UK', 950),
  (162, 'Daniel', 'Johnson', 'Qatar', 481),
  (163, 'Salma', 'White', 'USA', 817),
  (164, 'Noah', 'Brown', 'UK', 120),
  (165, 'Ziad', NULL, 'Morocco', NULL),
  (166, 'Kevin', NULL, 'UAE', 70),
  (167, 'Evelyn', 'Lee', 'UAE', 735),
  (168, 'Carol', 'ElSayed', 'UAE', 312),
  (169, 'Ziad', 'Davis', 'Egypt', 815),
  (170, 'Sami', 'Adams', 'Qatar', 368),
  (171, 'Michael', 'ElSayed', 'Germany', 639),
  (172, 'Ali', 'Thompson', 'Canada', 782),
  (173, 'Lina', 'Schwarz', 'Spain', 692),
  (174, 'Karim', 'Adams', 'Jordan', 920),
  (175, 'Ali', 'Aziz', 'Qatar', 629),
  (176, 'Mary', 'Davis', 'Italy', 429),
  (177, 'Anna', 'Mostafa', 'Morocco', 919),
  (178, 'Matthew', 'White', 'Saudi Arabia', 420),
  (179, 'Layla', 'Martin', 'Kuwait', 206),
  (180, 'Ava', 'Ray', 'Jordan', 716),
  (181, 'Hassan', 'Aziz', 'Qatar', 843),
  (182, 'Ryan', 'Hassan', 'Canada', 656),
  (183, 'Hassan', 'Miller', 'Kuwait', 138),
  (184, 'Hassan', 'Martin', 'Saudi Arabia', 525),
  (185, 'Lucas', 'Aziz', 'Morocco', 79),
  (186, 'Mia', 'Harris', 'UK', 267),
  (187, 'James', 'Jackson', 'France', 951),
  (188, 'Mason', 'Taylor', 'Netherlands', 60),
  (189, 'Charlotte', NULL, 'UAE', NULL),
  (190, 'Rania', 'Martinez', 'Saudi Arabia', 296),
  (191, 'Yasmin', 'Ibrahim', 'Morocco', 508),
  (192, 'Kevin', 'Schwarz', 'France', 758),
  (193, 'Karim', 'Williams', 'Morocco', 534),
  (194, 'Amelia', 'Mostafa', 'UK', 813),
  (195, 'Amelia', 'Miller', 'UK', 327),
  (196, 'Tarek', 'Johnson', 'UAE', 247),
  (197, 'John', 'Adams', 'Jordan', 830),
  (198, 'Yasmin', 'Ray', 'UAE', 545),
  (199, 'Hassan', 'Anderson', 'Spain', 587),
  (200, 'Mason', 'Williams', 'USA', 353),
  (201, 'Nadia', 'Davis', 'Egypt', 775),
  (202, 'Noah', 'Lee', 'France', NULL),
  (203, 'Mark', 'Farouk', 'France', 179),
  (204, 'Layla', 'Harris', 'Qatar', 943),
  (205, 'Jossef', 'ElSayed', 'France', 501),
  (206, 'Emily', 'Ray', 'Germany', 932),
  (207, 'Ryan', 'Adams', 'Kuwait', NULL),
  (208, 'Mia', 'Schwarz', 'Spain', 104),
  (209, 'David', 'Lee', 'Qatar', 361),
  (210, 'Frank', 'Smith', 'USA', 476),
  (211, 'Mason', 'Aziz', 'Qatar', 844),
  (212, 'Charlotte', 'Garcia', 'Saudi Arabia', 354),
  (213, 'Harper', 'Martinez', 'France', 111),
  (214, 'Evelyn', NULL, 'Jordan', NULL),
  (215, 'Hoda', 'Baker', 'Morocco', 726),
  (216, 'Frank', 'Ray', 'UAE', 126),
  (217, 'Sara', 'Goldberg', 'Canada', 658),
  (218, 'Ryan', 'Williams', 'Germany', 773),
  (219, 'Mona', 'Taylor', 'Kuwait', 753),
  (220, 'Nadia', 'Thompson', 'France', 690),
  (221, 'Harper', 'Moore', 'Qatar', 485),
  (222, 'Carol', 'Farouk', 'UAE', 980),
  (223, 'Hassan', 'White', 'Egypt', NULL),
  (224, 'Sara', 'Jackson', 'France', 894),
  (225, 'Lucas', 'Thompson', 'France', 529),
  (226, 'Yasmin', 'Williams', 'Jordan', 328),
  (227, 'Ethan', 'Farouk', 'Saudi Arabia', 662),
  (228, 'Mary', 'Martin', 'Canada', 668),
  (229, 'Salma', 'Goldberg', 'USA', 740),
  (230, 'Lucas', 'ElSayed', 'Germany', 738),
  (231, 'Hassan', 'ElSayed', 'Germany', 229),
  (232, 'Ryan', 'Mostafa', 'Morocco', 334),
  (233, 'Omar', 'ElSayed', 'Canada', 553),
  (234, 'Frank', 'Ibrahim', 'UK', 378),
  (235, 'Fatima', 'Adams', 'Kuwait', 471),
  (236, 'Yasmin', 'Ibrahim', 'France', 460),
  (237, 'Hoda', 'Farouk', 'Germany', 372),
  (238, 'Salma', 'Miller', 'USA', 463),
  (239, 'Ethan', 'White', 'Germany', 605),
  (240, 'Isabella', 'Martinez', 'Germany', 420),
  (241, 'Evelyn', 'Thomas', 'Saudi Arabia', 828),
  (242, 'Mark', 'Baker', 'France', 999),
  (243, 'Mona', 'Hassan', 'Netherlands', 174),
  (244, 'Kevin', 'Wilson', 'Spain', 776),
  (245, 'Sara', 'Williams', 'Italy', NULL),
  (246, 'Matthew', 'Schwarz', 'UAE', 984),
  (247, 'Carol', 'Hassan', 'USA', 207),
  (248, 'Mia', 'Thompson', 'Jordan', 772),
  (249, 'Hassan', 'Martinez', 'Kuwait', 533),
  (250, 'Karim', 'Hassan', 'Italy', 245),
  (251, 'Mason', 'Mostafa', 'Jordan', 934),
  (252, 'Anna', 'Johnson', 'Qatar', 474),
  (253, 'Emily', 'Thompson', 'Qatar', 890),
  (254, 'Jossef', 'Williams', 'Jordan', 651),
  (255, 'Harper', 'Moore', 'Saudi Arabia', 507),
  (256, 'Noah', 'Ibrahim', 'UK', 831),
  (257, 'Noah', 'Garcia', 'Saudi Arabia', 940),
  (258, 'Lina', 'Taylor', 'UAE', 289),
  (259, 'Ziad', 'Martinez', 'Germany', 534),
  (260, 'Sami', 'Thompson', 'Qatar', 729),
  (261, 'Ahmed', 'Lee', 'Saudi Arabia', 179),
  (262, 'Ethan', NULL, 'Spain', 152),
  (263, 'Andrew', 'Adams', 'Italy', 65),
  (264, 'Rania', 'Lee', 'Canada', 208),
  (265, 'Anna', 'Ibrahim', 'Qatar', 396),
  (266, 'Evelyn', 'Taylor', 'Canada', 922),
  (267, 'Emily', 'Harris', 'Morocco', 439),
  (268, 'John', 'Wilson', 'Jordan', 549),
  (269, 'Noah', 'Brown', 'Spain', NULL),
  (270, 'Layla', 'Moore', 'Netherlands', 282),
  (271, 'Adel', 'Schwarz', 'Canada', 828),
  (272, 'Layla', 'Taylor', 'Kuwait', 220),
  (273, 'Yasmin', 'Williams', 'Netherlands', NULL),
  (274, 'John', 'Jackson', 'Germany', 433),
  (275, 'Ava', 'Lee', 'UAE', 629),
  (276, 'Ali', 'Jackson', 'Egypt', 130),
  (277, 'Evelyn', 'Harris', 'Canada', 296),
  (278, 'Mia', 'Thompson', 'Spain', 522),
  (279, 'Layla', 'Johnson', 'Saudi Arabia', 59),
  (280, 'Isabella', 'Martin', 'France', 211),
  (281, 'Anna', 'Hassan', 'UK', 356),
  (282, 'Layla', NULL, 'Canada', 517),
  (283, 'Tarek', 'Baker', 'Canada', 159),
  (284, 'Karim', 'Garcia', 'Spain', 352),
  (285, 'Yasmin', 'Williams', 'Germany', 724),
  (286, 'Olivia', 'Johnson', 'Germany', 752),
  (287, 'Ziad', 'Anderson', 'Germany', 813),
  (288, 'Mia', 'White', 'Netherlands', 844),
  (289, 'Nadia', 'Aziz', 'Qatar', 701),
  (290, 'Lina', 'Aziz', 'France', 788),
  (291, 'Ziad', 'Moore', 'Morocco', 693),
  (292, 'Michael', 'Martin', 'Morocco', 366),
  (293, 'Andrew', 'Brown', 'Spain', 184),
  (294, 'Frank', 'Thompson', 'France', 475),
  (295, 'Omar', 'Baker', 'Egypt', 947),
  (296, 'Sophia', 'Mostafa', 'Italy', 900),
  (297, 'Sara', 'Johnson', 'Netherlands', 543),
  (298, 'Mona', 'Anderson', 'Kuwait', 167),
  (299, 'Isabella', NULL, 'USA', 281),
  (300, 'Ali', 'Anderson', 'Morocco', 916);

-- ======================================================
-- Table: employees
-- ======================================================
-- Self-referencing table: `managerid` points back to another
-- employeeid, forming a manager/report hierarchy tree.
CREATE TABLE `employees` (
  `employeeid` INT NOT NULL PRIMARY KEY,
  `firstname` VARCHAR(50),
  `lastname` VARCHAR(50),
  `department` VARCHAR(50),
  `birthdate` DATE,
  `gender` CHAR(1),
  `salary` INT,
  `managerid` INT,                          -- NULL means top-of-hierarchy (no manager)
  INDEX (`managerid`),
  CONSTRAINT `fk_employees_manager`
    FOREIGN KEY (`managerid`)
    REFERENCES `employees` (`employeeid`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Bulk insert of employee records; managerid always references
-- an employeeid inserted earlier in this same statement, so the
-- self-referencing foreign key is satisfied on first load.
INSERT INTO `employees` (`employeeid`,`firstname`,`lastname`,`department`,`birthdate`,`gender`,`salary`,`managerid`) VALUES
  (1, 'Amelia', 'Davis', 'Sales', '2000-06-20', 'F', 41824, NULL),
  (2, 'Salma', 'Farouk', 'Sales', '1985-05-27', 'F', 74362, NULL),
  (3, 'Harper', 'Garcia', 'Operations', '1969-11-11', 'M', 101797, NULL),
  (4, 'Kevin', 'Aziz', 'R&D', '1979-09-19', 'M', 48285, 3),
  (5, 'Isabella', 'Thompson', 'HR', '1994-02-15', 'F', 55292, 2),
  (6, 'Mary', NULL, 'Marketing', '1978-08-27', 'F', 55220, 1),
  (7, 'Karim', 'Martin', 'R&D', '1971-02-01', 'F', 99459, 3),
  (8, 'Fatima', NULL, 'R&D', '1983-10-20', 'M', 94379, 6),
  (9, 'Michael', 'White', 'Logistics', '1992-08-13', 'F', 76666, 1),
  (10, 'Yasmin', 'Davis', 'Finance', '1984-11-21', 'F', 70947, 6),
  (11, 'Michael', 'Moore', 'Operations', '1989-06-04', 'F', 47936, 7),
  (12, 'Hassan', 'Baker', 'Sales', '1985-05-26', 'M', 67801, 11),
  (13, 'Layla', 'Aziz', 'Marketing', '1967-04-09', 'F', 71925, 3),
  (14, 'Lucas', 'Baker', 'Sales', '1999-04-29', 'M', 116858, 4),
  (15, 'Nadia', 'Miller', 'IT', '2000-05-18', 'M', 76342, 14),
  (16, 'David', 'Lee', 'R&D', '1976-03-30', 'M', 54408, 11),
  (17, 'Kevin', 'Lee', 'Marketing', '1981-01-26', 'M', 117182, 11),
  (18, 'Kevin', 'Ray', 'HR', '1967-05-09', 'M', 95176, 17),
  (19, 'Carol', 'Anderson', 'Sales', '1986-05-13', 'F', 87453, 17),
  (20, 'Harper', 'Adams', 'Logistics', '1987-08-08', 'M', 45683, 17),
  (21, 'Tarek', 'Hassan', 'Marketing', '1967-09-24', 'F', 92640, 14),
  (22, 'Ali', 'Adams', 'Logistics', '1996-12-15', 'F', 49632, 3),
  (23, 'John', 'Aziz', 'IT', '1967-12-13', 'M', 76046, 20),
  (24, 'Layla', 'ElSayed', 'R&D', '1996-12-11', 'F', 89925, 20),
  (25, 'Charlotte', 'Williams', 'Logistics', '1987-09-05', 'F', 52999, 23),
  (26, 'Carol', 'Harris', 'R&D', '1997-05-03', 'M', 96370, 15),
  (27, 'Nadia', 'Martinez', 'Operations', '1985-05-06', 'F', 94524, 24),
  (28, 'Michael', 'Miller', 'Customer Support', '1979-01-08', 'F', 89060, 5),
  (29, 'Ali', 'Thompson', 'Logistics', '1968-01-05', 'M', 51188, 3),
  (30, 'Ava', 'Adams', 'Operations', '1970-11-02', 'M', 116869, 18),
  (31, 'Amelia', 'Miller', 'Sales', '1983-06-06', 'F', 95435, 28),
  (32, 'Rania', 'Brown', 'HR', '1991-12-08', 'F', 86090, 4),
  (33, 'Lucas', 'Mostafa', 'Finance', '1971-12-11', 'F', 69392, 7),
  (34, 'James', 'Harris', 'R&D', '1981-06-28', 'M', 76512, 15),
  (35, 'Ava', 'Harris', 'R&D', '1999-06-05', 'M', 119822, 18),
  (36, 'Kevin', 'Ray', 'HR', '1996-07-10', 'F', 84541, 23),
  (37, 'Jossef', 'Ray', 'IT', '1990-05-28', 'F', 49120, 10),
  (38, 'Adel', 'Wilson', 'Marketing', '1969-02-12', 'M', 89308, 27),
  (39, 'Isabella', 'Miller', 'IT', '1981-08-07', 'F', 82517, 37),
  (40, 'Mason', 'Schwarz', 'Marketing', '1971-12-25', 'M', 46522, 6);

-- ======================================================
-- Table: products
-- ======================================================
CREATE TABLE `products` (
  `productid` INT NOT NULL PRIMARY KEY,
  `product` VARCHAR(50),
  `category` VARCHAR(50),
  `price` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Bulk insert of product records; productid starts at 101 to
-- match the numbering convention used in the original dataset.
INSERT INTO `products` (`productid`,`product`,`category`,`price`) VALUES
  (101, 'Sunglasses', 'Footwear', 222),
  (102, 'Jersey', 'Sportswear', 231),
  (103, 'Wallet', 'Electronics', 115),
  (104, 'Monitor', 'Sportswear', 63),
  (105, 'Belt', 'Footwear', 61),
  (106, 'Watch', 'Sportswear', 254),
  (107, 'Shorts', 'Electronics', 28),
  (108, 'Backpack', 'Footwear', 33),
  (109, 'Bottle', 'Clothing', 159),
  (110, 'Jacket', 'Clothing', 135),
  (111, 'Watch', 'Electronics', 66),
  (112, 'Bottle', 'Footwear', 225),
  (113, 'Helmet', 'Clothing', 199),
  (114, 'Bag', 'Clothing', 261),
  (115, 'Bag', 'Electronics', 41),
  (116, 'Scarf', 'Accessories', 228),
  (117, 'Bottle', 'Footwear', 44),
  (118, 'Camera', 'Electronics', 299),
  (119, 'Wallet', 'Sportswear', 212),
  (120, 'Mouse', 'Footwear', 153),
  (121, 'Caps', 'Footwear', 15),
  (122, 'Shoes', 'Clothing', 240),
  (123, 'Headphones', 'Electronics', 50),
  (124, 'Wallet', 'Accessories', 129),
  (125, 'Wallet', 'Sportswear', 210),
  (126, 'Shorts', 'Accessories', 207),
  (127, 'Camera', 'Electronics', 178),
  (128, 'Backpack', 'Electronics', 91),
  (129, 'Socks', 'Sportswear', 63),
  (130, 'Shorts', 'Sportswear', 104),
  (131, 'Tripod', 'Electronics', 184),
  (132, 'Keyboard', 'Clothing', 125),
  (133, 'Caps', 'Clothing', 136),
  (134, 'Jacket', 'Clothing', 83),
  (135, 'Monitor', 'Accessories', 95),
  (136, 'Monitor', 'Footwear', 242),
  (137, 'Monitor', 'Sportswear', 234),
  (138, 'Cable', 'Sportswear', 170),
  (139, 'Camera', 'Electronics', 82),
  (140, 'Hat', 'Accessories', 245),
  (141, 'Hat', 'Electronics', 145),
  (142, 'Bracelet', 'Accessories', 185),
  (143, 'Shorts', 'Accessories', 163),
  (144, 'Hat', 'Footwear', 24),
  (145, 'Tire', 'Electronics', 151),
  (146, 'Socks', 'Accessories', 264),
  (147, 'Scarf', 'Footwear', 288),
  (148, 'Speaker', 'Accessories', 235),
  (149, 'Lamp', 'Sportswear', 101),
  (150, 'Shoes', 'Sportswear', 248),
  (151, 'Shorts', 'Clothing', 36),
  (152, 'Hat', 'Accessories', 180),
  (153, 'Mouse', 'Accessories', 263),
  (154, 'Charger', 'Clothing', 25),
  (155, 'Backpack', 'Footwear', 229),
  (156, 'Shorts', 'Sportswear', 86),
  (157, 'Belt', 'Electronics', 149),
  (158, 'Scarf', 'Footwear', 178),
  (159, 'Cable', 'Sportswear', 31),
  (160, 'Speaker', 'Electronics', 38);

-- ======================================================
-- Table: orders
-- ======================================================
-- Fact table referencing products, customers and employees
-- (as the salesperson). Several columns are intentionally
-- left NULL / empty-string to mimic real messy source data.
CREATE TABLE `orders` (
  `orderid` INT NOT NULL PRIMARY KEY,
  `productid` INT,
  `customerid` INT,
  `salespersonid` INT,
  `orderdate` DATE,
  `shipdate` DATE,
  `orderstatus` VARCHAR(50),
  `shipaddress` VARCHAR(255),
  `billaddress` VARCHAR(255),
  `quantity` INT,
  `sales` INT,
  `creationtime` TIMESTAMP,
  INDEX (`productid`),
  INDEX (`customerid`),
  INDEX (`salespersonid`),
  CONSTRAINT `fk_orders_product`
    FOREIGN KEY (`productid`)
    REFERENCES `products` (`productid`)
    ON DELETE SET NULL,
  CONSTRAINT `fk_orders_customer`
    FOREIGN KEY (`customerid`)
    REFERENCES `customers` (`customerid`)
    ON DELETE SET NULL,
  CONSTRAINT `fk_orders_employee`
    FOREIGN KEY (`salespersonid`)
    REFERENCES `employees` (`employeeid`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================
-- INSERT 500 ORDERS
-- =============================================================


INSERT INTO orders
(orderid, productid, customerid, salespersonid, orderdate, shipdate,
 orderstatus, shipaddress, billaddress, quantity, sales, creationtime)
VALUES
(1,101,1,1,'2025-01-03','2025-01-06','Shipped','Cairo, Egypt','Cairo, Egypt',2,444,'2025-01-03 09:15:00'),
(2,102,8,2,'2025-01-04','2025-01-07','Shipped','Giza, Egypt','Giza, Egypt',3,693,'2025-01-04 10:20:00'),
(3,103,15,3,'2025-01-05','2025-01-08','Delivered','Amman, Jordan','Amman, Jordan',1,115,'2025-01-05 11:30:00'),
(4,104,22,4,'2025-01-06','2025-01-09','Delivered','Dubai, UAE','Dubai, UAE',4,252,'2025-01-06 12:10:00'),
(5,105,29,5,'2025-01-07','2025-01-10','Shipped','Riyadh, Saudi Arabia','Riyadh, Saudi Arabia',2,122,'2025-01-07 13:05:00'),
(6,106,36,6,'2025-01-08','2025-01-11','Delivered','Rome, Italy','Rome, Italy',1,254,'2025-01-08 09:45:00'),
(7,107,43,7,'2025-01-09','2025-01-12','Pending','Doha, Qatar','Doha, Qatar',5,140,'2025-01-09 14:20:00'),
(8,108,50,8,'2025-01-10','2025-01-13','Shipped','Paris, France','Paris, France',3,99,'2025-01-10 15:10:00'),
(9,109,57,9,'2025-01-11','2025-01-14','Delivered','Madrid, Spain','Madrid, Spain',2,318,'2025-01-11 10:05:00'),
(10,110,64,10,'2025-01-12','2025-01-15','Delivered','Berlin, Germany','Berlin, Germany',1,135,'2025-01-12 11:40:00'),
(11,111,71,11,'2025-01-13','2025-01-16','Shipped','London, UK','London, UK',2,132,'2025-01-13 12:25:00'),
(12,112,78,12,'2025-01-14','2025-01-17','Delivered','Toronto, Canada','Toronto, Canada',3,675,'2025-01-14 13:15:00'),
(13,113,85,13,'2025-01-15','2025-01-18','Pending','Kuwait City, Kuwait','Kuwait City, Kuwait',1,199,'2025-01-15 14:05:00'),
(14,114,92,14,'2025-01-16','2025-01-19','Shipped','Casablanca, Morocco','Casablanca, Morocco',2,522,'2025-01-16 09:30:00'),
(15,115,99,15,'2025-01-17','2025-01-20','Delivered','Cairo, Egypt','Cairo, Egypt',4,164,'2025-01-17 10:15:00'),
(16,116,106,16,'2025-01-18','2025-01-21','Delivered','Amsterdam, Netherlands','Amsterdam, Netherlands',2,456,'2025-01-18 11:05:00'),
(17,117,113,17,'2025-01-19','2025-01-22','Shipped','Barcelona, Spain','Barcelona, Spain',3,132,'2025-01-19 12:00:00'),
(18,118,120,18,'2025-01-20','2025-01-23','Delivered','New York, USA','New York, USA',1,299,'2025-01-20 13:10:00'),
(19,119,127,19,'2025-01-21','2025-01-24','Pending','Rabat, Morocco','Rabat, Morocco',2,424,'2025-01-21 14:15:00'),
(20,120,134,20,'2025-01-22','2025-01-25','Shipped','Munich, Germany','Munich, Germany',3,459,'2025-01-22 15:00:00'),
(21,121,141,21,'2025-01-23','2025-01-26','Delivered','Paris, France','Paris, France',5,75,'2025-01-23 09:20:00'),
(22,122,148,22,'2025-01-24','2025-01-27','Delivered','Rome, Italy','Rome, Italy',2,480,'2025-01-24 10:35:00'),
(23,123,155,23,'2025-01-25','2025-01-28','Shipped','Dubai, UAE','Dubai, UAE',3,150,'2025-01-25 11:45:00'),
(24,124,162,24,'2025-01-26','2025-01-29','Delivered','Doha, Qatar','Doha, Qatar',2,258,'2025-01-26 12:30:00'),
(25,125,169,25,'2025-01-27','2025-01-30','Pending','Cairo, Egypt','Cairo, Egypt',1,210,'2025-01-27 13:20:00'),
(26,126,176,26,'2025-01-28','2025-01-31','Shipped','Madrid, Spain','Madrid, Spain',2,414,'2025-01-28 14:10:00'),
(27,127,183,27,'2025-01-29','2025-02-01','Delivered','Kuwait City, Kuwait','Kuwait City, Kuwait',3,534,'2025-01-29 15:05:00'),
(28,128,190,28,'2025-01-30','2025-02-02','Delivered','Riyadh, Saudi Arabia','Riyadh, Saudi Arabia',4,364,'2025-01-30 09:50:00'),
(29,129,197,29,'2025-01-31','2025-02-03','Shipped','London, UK','London, UK',2,126,'2025-01-31 10:40:00'),
(30,130,204,30,'2025-02-01','2025-02-04','Delivered','Amman, Jordan','Amman, Jordan',3,312,'2025-02-01 11:30:00'),
(31,131,211,31,'2025-02-02','2025-02-05','Pending','Toronto, Canada','Toronto, Canada',1,184,'2025-02-02 12:20:00'),
(32,132,218,32,'2025-02-03','2025-02-06','Shipped','Berlin, Germany','Berlin, Germany',2,250,'2025-02-03 13:10:00'),
(33,133,225,33,'2025-02-04','2025-02-07','Delivered','Paris, France','Paris, France',3,408,'2025-02-04 14:00:00'),
(34,134,232,34,'2025-02-05','2025-02-08','Delivered','Dubai, UAE','Dubai, UAE',2,166,'2025-02-05 15:00:00'),
(35,135,239,35,'2025-02-06','2025-02-09','Shipped','Amsterdam, Netherlands','Amsterdam, Netherlands',1,95,'2025-02-06 09:15:00'),
(36,136,246,36,'2025-02-07','2025-02-10','Delivered','Riyadh, Saudi Arabia','Riyadh, Saudi Arabia',2,484,'2025-02-07 10:10:00'),
(37,137,253,37,'2025-02-08','2025-02-11','Pending','Doha, Qatar','Doha, Qatar',3,702,'2025-02-08 11:00:00'),
(38,138,260,38,'2025-02-09','2025-02-12','Shipped','Casablanca, Morocco','Casablanca, Morocco',2,340,'2025-02-09 12:00:00'),
(39,139,267,39,'2025-02-10','2025-02-13','Delivered','Cairo, Egypt','Cairo, Egypt',4,328,'2025-02-10 13:00:00'),
(40,140,274,40,'2025-02-11','2025-02-14','Delivered','Madrid, Spain','Madrid, Spain',1,245,'2025-02-11 14:00:00'),
(41,141,281,1,'2025-02-12','2025-02-15','Shipped','London, UK','London, UK',2,290,'2025-02-12 15:00:00'),
(42,142,288,2,'2025-02-13','2025-02-16','Delivered','Toronto, Canada','Toronto, Canada',3,555,'2025-02-13 09:20:00'),
(43,143,295,3,'2025-02-14','2025-02-17','Pending','Cairo, Egypt','Cairo, Egypt',2,326,'2025-02-14 10:20:00'),
(44,144,3,4,'2025-02-15','2025-02-18','Shipped','Madrid, Spain','Madrid, Spain',4,96,'2025-02-15 11:20:00'),
(45,145,10,5,'2025-02-16','2025-02-19','Delivered','Paris, France','Paris, France',2,302,'2025-02-16 12:20:00'),
(46,146,17,6,'2025-02-17','2025-02-20','Delivered','Cairo, Egypt','Cairo, Egypt',1,264,'2025-02-17 13:20:00'),
(47,147,24,7,'2025-02-18','2025-02-21','Shipped','Amsterdam, Netherlands','Amsterdam, Netherlands',3,864,'2025-02-18 14:20:00'),
(48,148,31,8,'2025-02-19','2025-02-22','Pending','Berlin, Germany','Berlin, Germany',2,470,'2025-02-19 15:20:00'),
(49,149,38,9,'2025-02-20','2025-02-23','Delivered','London, UK','London, UK',4,404,'2025-02-20 09:20:00'),
(50,150,45,10,'2025-02-21','2025-02-24','Shipped','Dubai, UAE','Dubai, UAE',2,496,'2025-02-21 10:20:00'),

(51,151,52,11,'2025-02-22','2025-02-25','Delivered','Paris, France','Paris, France',3,108,'2025-02-22 11:20:00'),
(52,152,59,12,'2025-02-23','2025-02-26','Delivered','Cairo, Egypt','Cairo, Egypt',2,360,'2025-02-23 12:20:00'),
(53,153,66,13,'2025-02-24','2025-02-27','Shipped','Riyadh, Saudi Arabia','Riyadh, Saudi Arabia',1,263,'2025-02-24 13:20:00'),
(54,154,73,14,'2025-02-25','2025-02-28','Pending','Doha, Qatar','Doha, Qatar',4,100,'2025-02-25 14:20:00'),
(55,155,80,15,'2025-02-26','2025-03-01','Delivered','London, UK','London, UK',2,458,'2025-02-26 15:20:00'),
(56,156,87,16,'2025-02-27','2025-03-02','Shipped','New York, USA','New York, USA',3,258,'2025-02-27 09:20:00'),
(57,157,94,17,'2025-02-28','2025-03-03','Delivered','Cairo, Egypt','Cairo, Egypt',2,298,'2025-02-28 10:20:00'),
(58,158,101,18,'2025-03-01','2025-03-04','Delivered','Amman, Jordan','Amman, Jordan',1,178,'2025-03-01 11:20:00'),
(59,159,108,19,'2025-03-02','2025-03-05','Shipped','Kuwait City, Kuwait','Kuwait City, Kuwait',5,155,'2025-03-02 12:20:00'),
(60,160,115,20,'2025-03-03','2025-03-06','Pending','Dubai, UAE','Dubai, UAE',2,76,'2025-03-03 13:20:00'),

(61,101,122,21,'2025-03-04','2025-03-07','Delivered','Amsterdam, Netherlands','Amsterdam, Netherlands',3,666,'2025-03-04 14:20:00'),
(62,102,129,22,'2025-03-05','2025-03-08','Shipped','Casablanca, Morocco','Casablanca, Morocco',1,231,'2025-03-05 15:20:00'),
(63,103,136,23,'2025-03-06','2025-03-09','Delivered','Cairo, Egypt','Cairo, Egypt',4,460,'2025-03-06 09:20:00'),
(64,104,143,24,'2025-03-07','2025-03-10','Pending','Doha, Qatar','Doha, Qatar',2,126,'2025-03-07 10:20:00'),
(65,105,150,25,'2025-03-08','2025-03-11','Shipped','London, UK','London, UK',3,183,'2025-03-08 11:20:00'),
(66,106,157,26,'2025-03-09','2025-03-12','Delivered','Berlin, Germany','Berlin, Germany',2,508,'2025-03-09 12:20:00'),
(67,107,164,27,'2025-03-10','2025-03-13','Delivered','Paris, France','Paris, France',1,28,'2025-03-10 13:20:00'),
(68,108,171,28,'2025-03-11','2025-03-14','Shipped','Riyadh, Saudi Arabia','Riyadh, Saudi Arabia',4,132,'2025-03-11 14:20:00'),
(69,109,178,29,'2025-03-12','2025-03-15','Pending','Cairo, Egypt','Cairo, Egypt',2,318,'2025-03-12 15:20:00'),
(70,110,185,30,'2025-03-13','2025-03-16','Delivered','Madrid, Spain','Madrid, Spain',3,405,'2025-03-13 09:20:00'),

(71,111,192,31,'2025-03-14','2025-03-17','Shipped','Rome, Italy','Rome, Italy',2,132,'2025-03-14 10:20:00'),
(72,112,199,32,'2025-03-15','2025-03-18','Delivered','Toronto, Canada','Toronto, Canada',1,225,'2025-03-15 11:20:00'),
(73,113,206,33,'2025-03-16','2025-03-19','Delivered','Cairo, Egypt','Cairo, Egypt',2,398,'2025-03-16 12:20:00'),
(74,114,213,34,'2025-03-17','2025-03-20','Shipped','Dubai, UAE','Dubai, UAE',3,783,'2025-03-17 13:20:00'),
(75,115,220,35,'2025-03-18','2025-03-21','Pending','Amman, Jordan','Amman, Jordan',4,164,'2025-03-18 14:20:00'),
(76,116,227,36,'2025-03-19','2025-03-22','Delivered','Casablanca, Morocco','Casablanca, Morocco',2,456,'2025-03-19 15:20:00'),
(77,117,234,37,'2025-03-20','2025-03-23','Shipped','Kuwait City, Kuwait','Kuwait City, Kuwait',3,132,'2025-03-20 09:20:00'),
(78,118,241,38,'2025-03-21','2025-03-24','Delivered','New York, USA','New York, USA',2,598,'2025-03-21 10:20:00'),
(79,119,248,39,'2025-03-22','2025-03-25','Pending','Cairo, Egypt','Cairo, Egypt',1,212,'2025-03-22 11:20:00'),
(80,120,255,40,'2025-03-23','2025-03-26','Delivered','London, UK','London, UK',3,459,'2025-03-23 12:20:00'),

(81,121,262,1,'2025-03-24','2025-03-27','Shipped','Madrid, Spain','Madrid, Spain',2,30,'2025-03-24 13:20:00'),
(82,122,269,2,'2025-03-25','2025-03-28','Delivered','Paris, France','Paris, France',1,240,'2025-03-25 14:20:00'),
(83,123,276,3,'2025-03-26','2025-03-29','Pending','Cairo, Egypt','Cairo, Egypt',4,200,'2025-03-26 15:20:00'),
(84,124,283,4,'2025-03-27','2025-03-30','Shipped','Toronto, Canada','Toronto, Canada',2,258,'2025-03-27 09:20:00'),
(85,125,290,5,'2025-03-28','2025-03-31','Delivered','Dubai, UAE','Dubai, UAE',3,630,'2025-03-28 10:20:00'),
(86,126,297,6,'2025-03-29','2025-04-01','Delivered','Amsterdam, Netherlands','Amsterdam, Netherlands',1,207,'2025-03-29 11:20:00'),
(87,127,4,7,'2025-03-30','2025-04-02','Shipped','Riyadh, Saudi Arabia','Riyadh, Saudi Arabia',2,356,'2025-03-30 12:20:00'),
(88,128,11,8,'2025-03-31','2025-04-03','Pending','Doha, Qatar','Doha, Qatar',3,273,'2025-03-31 13:20:00'),
(89,129,18,9,'2025-04-01','2025-04-04','Delivered','Cairo, Egypt','Cairo, Egypt',4,252,'2025-04-01 14:20:00'),
(90,130,25,10,'2025-04-02','2025-04-05','Shipped','Berlin, Germany','Berlin, Germany',2,208,'2025-04-02 15:20:00'),

(91,131,32,11,'2025-04-03','2025-04-06','Delivered','London, UK','London, UK',1,184,'2025-04-03 09:20:00'),
(92,132,39,12,'2025-04-04','2025-04-07','Pending','Paris, France','Paris, France',2,250,'2025-04-04 10:20:00'),
(93,133,46,13,'2025-04-05','2025-04-08','Shipped','Dubai, UAE','Dubai, UAE',3,408,'2025-04-05 11:20:00'),
(94,134,53,14,'2025-04-06','2025-04-09','Delivered','Cairo, Egypt','Cairo, Egypt',1,83,'2025-04-06 12:20:00'),
(95,135,60,15,'2025-04-07','2025-04-10','Delivered','Rome, Italy','Rome, Italy',2,190,'2025-04-07 13:20:00'),
(96,136,67,16,'2025-04-08','2025-04-11','Shipped','Amman, Jordan','Amman, Jordan',3,726,'2025-04-08 14:20:00'),
(97,137,74,17,'2025-04-09','2025-04-12','Pending','New York, USA','New York, USA',2,468,'2025-04-09 15:20:00'),
(98,138,81,18,'2025-04-10','2025-04-13','Delivered','Cairo, Egypt','Cairo, Egypt',4,680,'2025-04-10 09:20:00'),
(99,139,88,19,'2025-04-11','2025-04-14','Shipped','Madrid, Spain','Madrid, Spain',3,246,'2025-04-11 10:20:00'),
(100,140,95,20,'2025-04-12','2025-04-15','Delivered','Berlin, Germany','Berlin, Germany',2,490,'2025-04-12 11:20:00');

-- =============================================================
-- Generate orders 101-500 automatically
-- This creates an additional 400 realistic records.
-- =============================================================

INSERT INTO orders
(orderid, productid, customerid, salespersonid, orderdate, shipdate,
 orderstatus, shipaddress, billaddress, quantity, sales, creationtime)
SELECT
    n AS orderid,
    101 + MOD(n * 7, 60) AS productid,
    1 + MOD(n * 13, 300) AS customerid,
    1 + MOD(n * 11, 40) AS salespersonid,
    DATE_ADD('2025-04-13', INTERVAL (n - 101) DAY) AS orderdate,
    DATE_ADD('2025-04-16', INTERVAL (n - 101) DAY) AS shipdate,
    CASE MOD(n,4)
        WHEN 0 THEN 'Delivered'
        WHEN 1 THEN 'Shipped'
        WHEN 2 THEN 'Pending'
        ELSE 'Cancelled'
    END AS orderstatus,
    CASE MOD(n,10)
        WHEN 0 THEN 'Cairo, Egypt'
        WHEN 1 THEN 'Amman, Jordan'
        WHEN 2 THEN 'Dubai, UAE'
        WHEN 3 THEN 'Riyadh, Saudi Arabia'
        WHEN 4 THEN 'Doha, Qatar'
        WHEN 5 THEN 'London, UK'
        WHEN 6 THEN 'Paris, France'
        WHEN 7 THEN 'Berlin, Germany'
        WHEN 8 THEN 'Madrid, Spain'
        ELSE 'Toronto, Canada'
    END AS shipaddress,
    CASE MOD(n,10)
        WHEN 0 THEN 'Cairo, Egypt'
        WHEN 1 THEN 'Amman, Jordan'
        WHEN 2 THEN 'Dubai, UAE'
        WHEN 3 THEN 'Riyadh, Saudi Arabia'
        WHEN 4 THEN 'Doha, Qatar'
        WHEN 5 THEN 'London, UK'
        WHEN 6 THEN 'Paris, France'
        WHEN 7 THEN 'Berlin, Germany'
        WHEN 8 THEN 'Madrid, Spain'
        ELSE 'Toronto, Canada'
    END AS billaddress,
    1 + MOD(n,5) AS quantity,
    (1 + MOD(n,5)) *
        CASE MOD(n * 7,60)
            WHEN 0 THEN 222
            WHEN 1 THEN 231
            WHEN 2 THEN 115
            WHEN 3 THEN 63
            WHEN 4 THEN 61
            WHEN 5 THEN 254
            WHEN 6 THEN 28
            WHEN 7 THEN 33
            WHEN 8 THEN 159
            WHEN 9 THEN 135
            WHEN 10 THEN 66
            WHEN 11 THEN 225
            WHEN 12 THEN 199
            WHEN 13 THEN 261
            WHEN 14 THEN 41
            WHEN 15 THEN 228
            WHEN 16 THEN 44
            WHEN 17 THEN 299
            WHEN 18 THEN 212
            WHEN 19 THEN 153
            WHEN 20 THEN 15
            WHEN 21 THEN 240
            WHEN 22 THEN 50
            WHEN 23 THEN 129
            WHEN 24 THEN 210
            WHEN 25 THEN 207
            WHEN 26 THEN 178
            WHEN 27 THEN 91
            WHEN 28 THEN 63
            WHEN 29 THEN 104
            WHEN 30 THEN 184
            WHEN 31 THEN 125
            WHEN 32 THEN 136
            WHEN 33 THEN 83
            WHEN 34 THEN 95
            WHEN 35 THEN 242
            WHEN 36 THEN 234
            WHEN 37 THEN 170
            WHEN 38 THEN 82
            WHEN 39 THEN 245
            WHEN 40 THEN 145
            WHEN 41 THEN 185
            WHEN 42 THEN 163
            WHEN 43 THEN 24
            WHEN 44 THEN 151
            WHEN 45 THEN 264
            WHEN 46 THEN 288
            WHEN 47 THEN 235
            WHEN 48 THEN 101
            WHEN 49 THEN 248
            WHEN 50 THEN 36
            WHEN 51 THEN 180
            WHEN 52 THEN 263
            WHEN 53 THEN 25
            WHEN 54 THEN 229
            WHEN 55 THEN 86
            WHEN 56 THEN 149
            WHEN 57 THEN 178
            WHEN 58 THEN 31
            WHEN 59 THEN 38
        END AS sales,
    TIMESTAMP(
        DATE_ADD('2025-04-13', INTERVAL (n - 101) DAY),
        MAKETIME(8 + MOD(n,10), MOD(n * 7,60), 0)
    ) AS creationtime
FROM (
    SELECT 101 AS n UNION ALL SELECT 102 UNION ALL SELECT 103 UNION ALL SELECT 104
    UNION ALL SELECT 105 UNION ALL SELECT 106 UNION ALL SELECT 107 UNION ALL SELECT 108
    UNION ALL SELECT 109 UNION ALL SELECT 110 UNION ALL SELECT 111 UNION ALL SELECT 112
    UNION ALL SELECT 113 UNION ALL SELECT 114 UNION ALL SELECT 115 UNION ALL SELECT 116
    UNION ALL SELECT 117 UNION ALL SELECT 118 UNION ALL SELECT 119 UNION ALL SELECT 120
    UNION ALL SELECT 121 UNION ALL SELECT 122 UNION ALL SELECT 123 UNION ALL SELECT 124
    UNION ALL SELECT 125 UNION ALL SELECT 126 UNION ALL SELECT 127 UNION ALL SELECT 128
    UNION ALL SELECT 129 UNION ALL SELECT 130 UNION ALL SELECT 131 UNION ALL SELECT 132
    UNION ALL SELECT 133 UNION ALL SELECT 134 UNION ALL SELECT 135 UNION ALL SELECT 136
    UNION ALL SELECT 137 UNION ALL SELECT 138 UNION ALL SELECT 139 UNION ALL SELECT 140
    UNION ALL SELECT 141 UNION ALL SELECT 142 UNION ALL SELECT 143 UNION ALL SELECT 144
    UNION ALL SELECT 145 UNION ALL SELECT 146 UNION ALL SELECT 147 UNION ALL SELECT 148
    UNION ALL SELECT 149 UNION ALL SELECT 150 UNION ALL SELECT 151 UNION ALL SELECT 152
    UNION ALL SELECT 153 UNION ALL SELECT 154 UNION ALL SELECT 155 UNION ALL SELECT 156
    UNION ALL SELECT 157 UNION ALL SELECT 158 UNION ALL SELECT 159 UNION ALL SELECT 160
    UNION ALL SELECT 161 UNION ALL SELECT 162 UNION ALL SELECT 163 UNION ALL SELECT 164
    UNION ALL SELECT 165 UNION ALL SELECT 166 UNION ALL SELECT 167 UNION ALL SELECT 168
    UNION ALL SELECT 169 UNION ALL SELECT 170 UNION ALL SELECT 171 UNION ALL SELECT 172
    UNION ALL SELECT 173 UNION ALL SELECT 174 UNION ALL SELECT 175 UNION ALL SELECT 176
    UNION ALL SELECT 177 UNION ALL SELECT 178 UNION ALL SELECT 179 UNION ALL SELECT 180
    UNION ALL SELECT 181 UNION ALL SELECT 182 UNION ALL SELECT 183 UNION ALL SELECT 184
    UNION ALL SELECT 185 UNION ALL SELECT 186 UNION ALL SELECT 187 UNION ALL SELECT 188
    UNION ALL SELECT 189 UNION ALL SELECT 190 UNION ALL SELECT 191 UNION ALL SELECT 192
    UNION ALL SELECT 193 UNION ALL SELECT 194 UNION ALL SELECT 195 UNION ALL SELECT 196
    UNION ALL SELECT 197 UNION ALL SELECT 198 UNION ALL SELECT 199 UNION ALL SELECT 200
    UNION ALL SELECT 201 UNION ALL SELECT 202 UNION ALL SELECT 203 UNION ALL SELECT 204
    UNION ALL SELECT 205 UNION ALL SELECT 206 UNION ALL SELECT 207 UNION ALL SELECT 208
    UNION ALL SELECT 209 UNION ALL SELECT 210 UNION ALL SELECT 211 UNION ALL SELECT 212
    UNION ALL SELECT 213 UNION ALL SELECT 214 UNION ALL SELECT 215 UNION ALL SELECT 216
    UNION ALL SELECT 217 UNION ALL SELECT 218 UNION ALL SELECT 219 UNION ALL SELECT 220
    UNION ALL SELECT 221 UNION ALL SELECT 222 UNION ALL SELECT 223 UNION ALL SELECT 224
    UNION ALL SELECT 225 UNION ALL SELECT 226 UNION ALL SELECT 227 UNION ALL SELECT 228
    UNION ALL SELECT 229 UNION ALL SELECT 230 UNION ALL SELECT 231 UNION ALL SELECT 232
    UNION ALL SELECT 233 UNION ALL SELECT 234 UNION ALL SELECT 235 UNION ALL SELECT 236
    UNION ALL SELECT 237 UNION ALL SELECT 238 UNION ALL SELECT 239 UNION ALL SELECT 240
    UNION ALL SELECT 241 UNION ALL SELECT 242 UNION ALL SELECT 243 UNION ALL SELECT 244
    UNION ALL SELECT 245 UNION ALL SELECT 246 UNION ALL SELECT 247 UNION ALL SELECT 248
    UNION ALL SELECT 249 UNION ALL SELECT 250 UNION ALL SELECT 251 UNION ALL SELECT 252
    UNION ALL SELECT 253 UNION ALL SELECT 254 UNION ALL SELECT 255 UNION ALL SELECT 256
    UNION ALL SELECT 257 UNION ALL SELECT 258 UNION ALL SELECT 259 UNION ALL SELECT 260
    UNION ALL SELECT 261 UNION ALL SELECT 262 UNION ALL SELECT 263 UNION ALL SELECT 264
    UNION ALL SELECT 265 UNION ALL SELECT 266 UNION ALL SELECT 267 UNION ALL SELECT 268
    UNION ALL SELECT 269 UNION ALL SELECT 270 UNION ALL SELECT 271 UNION ALL SELECT 272
    UNION ALL SELECT 273 UNION ALL SELECT 274 UNION ALL SELECT 275 UNION ALL SELECT 276
    UNION ALL SELECT 277 UNION ALL SELECT 278 UNION ALL SELECT 279 UNION ALL SELECT 280
    UNION ALL SELECT 281 UNION ALL SELECT 282 UNION ALL SELECT 283 UNION ALL SELECT 284
    UNION ALL SELECT 285 UNION ALL SELECT 286 UNION ALL SELECT 287 UNION ALL SELECT 288
    UNION ALL SELECT 289 UNION ALL SELECT 290 UNION ALL SELECT 291 UNION ALL SELECT 292
    UNION ALL SELECT 293 UNION ALL SELECT 294 UNION ALL SELECT 295 UNION ALL SELECT 296
    UNION ALL SELECT 297 UNION ALL SELECT 298 UNION ALL SELECT 299 UNION ALL SELECT 300
    UNION ALL SELECT 301 UNION ALL SELECT 302 UNION ALL SELECT 303 UNION ALL SELECT 304
    UNION ALL SELECT 305 UNION ALL SELECT 306 UNION ALL SELECT 307 UNION ALL SELECT 308
    UNION ALL SELECT 309 UNION ALL SELECT 310 UNION ALL SELECT 311 UNION ALL SELECT 312
    UNION ALL SELECT 313 UNION ALL SELECT 314 UNION ALL SELECT 315 UNION ALL SELECT 316
    UNION ALL SELECT 317 UNION ALL SELECT 318 UNION ALL SELECT 319 UNION ALL SELECT 320
    UNION ALL SELECT 321 UNION ALL SELECT 322 UNION ALL SELECT 323 UNION ALL SELECT 324
    UNION ALL SELECT 325 UNION ALL SELECT 326 UNION ALL SELECT 327 UNION ALL SELECT 328
    UNION ALL SELECT 329 UNION ALL SELECT 330 UNION ALL SELECT 331 UNION ALL SELECT 332
    UNION ALL SELECT 333 UNION ALL SELECT 334 UNION ALL SELECT 335 UNION ALL SELECT 336
    UNION ALL SELECT 337 UNION ALL SELECT 338 UNION ALL SELECT 339 UNION ALL SELECT 340
    UNION ALL SELECT 341 UNION ALL SELECT 342 UNION ALL SELECT 343 UNION ALL SELECT 344
    UNION ALL SELECT 345 UNION ALL SELECT 346 UNION ALL SELECT 347 UNION ALL SELECT 348
    UNION ALL SELECT 349 UNION ALL SELECT 350 UNION ALL SELECT 351 UNION ALL SELECT 352
    UNION ALL SELECT 353 UNION ALL SELECT 354 UNION ALL SELECT 355 UNION ALL SELECT 356
    UNION ALL SELECT 357 UNION ALL SELECT 358 UNION ALL SELECT 359 UNION ALL SELECT 360
    UNION ALL SELECT 361 UNION ALL SELECT 362 UNION ALL SELECT 363 UNION ALL SELECT 364
    UNION ALL SELECT 365 UNION ALL SELECT 366 UNION ALL SELECT 367 UNION ALL SELECT 368
    UNION ALL SELECT 369 UNION ALL SELECT 370 UNION ALL SELECT 371 UNION ALL SELECT 372
    UNION ALL SELECT 373 UNION ALL SELECT 374 UNION ALL SELECT 375 UNION ALL SELECT 376
    UNION ALL SELECT 377 UNION ALL SELECT 378 UNION ALL SELECT 379 UNION ALL SELECT 380
    UNION ALL SELECT 381 UNION ALL SELECT 382 UNION ALL SELECT 383 UNION ALL SELECT 384
    UNION ALL SELECT 385 UNION ALL SELECT 386 UNION ALL SELECT 387 UNION ALL SELECT 388
    UNION ALL SELECT 389 UNION ALL SELECT 390 UNION ALL SELECT 391 UNION ALL SELECT 392
    UNION ALL SELECT 393 UNION ALL SELECT 394 UNION ALL SELECT 395 UNION ALL SELECT 396
    UNION ALL SELECT 397 UNION ALL SELECT 398 UNION ALL SELECT 399 UNION ALL SELECT 400
    UNION ALL SELECT 401 UNION ALL SELECT 402 UNION ALL SELECT 403 UNION ALL SELECT 404
    UNION ALL SELECT 405 UNION ALL SELECT 406 UNION ALL SELECT 407 UNION ALL SELECT 408
    UNION ALL SELECT 409 UNION ALL SELECT 410 UNION ALL SELECT 411 UNION ALL SELECT 412
    UNION ALL SELECT 413 UNION ALL SELECT 414 UNION ALL SELECT 415 UNION ALL SELECT 416
    UNION ALL SELECT 417 UNION ALL SELECT 418 UNION ALL SELECT 419 UNION ALL SELECT 420
    UNION ALL SELECT 421 UNION ALL SELECT 422 UNION ALL SELECT 423 UNION ALL SELECT 424
    UNION ALL SELECT 425 UNION ALL SELECT 426 UNION ALL SELECT 427 UNION ALL SELECT 428
    UNION ALL SELECT 429 UNION ALL SELECT 430 UNION ALL SELECT 431 UNION ALL SELECT 432
    UNION ALL SELECT 433 UNION ALL SELECT 434 UNION ALL SELECT 435 UNION ALL SELECT 436
    UNION ALL SELECT 437 UNION ALL SELECT 438 UNION ALL SELECT 439 UNION ALL SELECT 440
    UNION ALL SELECT 441 UNION ALL SELECT 442 UNION ALL SELECT 443 UNION ALL SELECT 444
    UNION ALL SELECT 445 UNION ALL SELECT 446 UNION ALL SELECT 447 UNION ALL SELECT 448
    UNION ALL SELECT 449 UNION ALL SELECT 450 UNION ALL SELECT 451 UNION ALL SELECT 452
    UNION ALL SELECT 453 UNION ALL SELECT 454 UNION ALL SELECT 455 UNION ALL SELECT 456
    UNION ALL SELECT 457 UNION ALL SELECT 458 UNION ALL SELECT 459 UNION ALL SELECT 460
    UNION ALL SELECT 461 UNION ALL SELECT 462 UNION ALL SELECT 463 UNION ALL SELECT 464
    UNION ALL SELECT 465 UNION ALL SELECT 466 UNION ALL SELECT 467 UNION ALL SELECT 468
    UNION ALL SELECT 469 UNION ALL SELECT 470 UNION ALL SELECT 471 UNION ALL SELECT 472
    UNION ALL SELECT 473 UNION ALL SELECT 474 UNION ALL SELECT 475 UNION ALL SELECT 476
    UNION ALL SELECT 477 UNION ALL SELECT 478 UNION ALL SELECT 479 UNION ALL SELECT 480
    UNION ALL SELECT 481 UNION ALL SELECT 482 UNION ALL SELECT 483 UNION ALL SELECT 484
    UNION ALL SELECT 485 UNION ALL SELECT 486 UNION ALL SELECT 487 UNION ALL SELECT 488
    UNION ALL SELECT 489 UNION ALL SELECT 490 UNION ALL SELECT 491 UNION ALL SELECT 492
    UNION ALL SELECT 493 UNION ALL SELECT 494 UNION ALL SELECT 495 UNION ALL SELECT 496
    UNION ALL SELECT 497 UNION ALL SELECT 498 UNION ALL SELECT 499 UNION ALL SELECT 500
) AS numbers;

-- =============================================================
-- VERIFY
-- =============================================================
SELECT COUNT(*) AS total_orders FROM orders;
SELECT MIN(orderid) AS first_order, MAX(orderid) AS last_order
FROM orders;
