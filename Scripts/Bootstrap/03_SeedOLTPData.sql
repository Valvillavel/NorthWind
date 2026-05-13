/*
================================================================================
 Bootstrap Script — Step 3: Seed OLTP Sample Data
 Script:    03_SeedOLTPData.sql
 Purpose:   Inserts the classic Northwind sample dataset into NorthWindOLTP.
            This is the canonical 1990s trading company dataset used for demos.
================================================================================
 NOTE: This script is idempotent — it uses IF NOT EXISTS guards.
       Safe to run multiple times without creating duplicates.
================================================================================
*/
USE [NorthWindOLTP];
GO

SET NOCOUNT ON;
PRINT '=== Seeding NorthWindOLTP sample data ===';

-- ============================================================
-- Categories
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Categories] WHERE [CategoryID] = 1)
BEGIN
    SET IDENTITY_INSERT [dbo].[Categories] ON;
    INSERT INTO [dbo].[Categories] ([CategoryID], [CategoryName], [Description]) VALUES
        (1, 'Beverages',    'Soft drinks, coffees, teas, beers, and ales'),
        (2, 'Condiments',   'Sweet and savory sauces, relishes, spreads, and seasonings'),
        (3, 'Confections',  'Desserts, candies, and sweet breads'),
        (4, 'Dairy Products','Cheeses'),
        (5, 'Grains/Cereals','Breads, crackers, pasta, and cereal'),
        (6, 'Meat/Poultry', 'Prepared meats'),
        (7, 'Produce',      'Dried fruit and bean curd'),
        (8, 'Seafood',      'Seaweed and fish');
    SET IDENTITY_INSERT [dbo].[Categories] OFF;
    PRINT 'Categories seeded.';
END
GO

-- ============================================================
-- Suppliers
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Suppliers] WHERE [SupplierID] = 1)
BEGIN
    SET IDENTITY_INSERT [dbo].[Suppliers] ON;
    INSERT INTO [dbo].[Suppliers] ([SupplierID],[CompanyName],[ContactName],[ContactTitle],[City],[Country],[Phone]) VALUES
        (1,  'Exotic Liquids',                  'Charlotte Cooper',   'Purchasing Manager',  'London',       'UK',        '(171) 555-2222'),
        (2,  'New Orleans Cajun Delights',       'Shelley Burke',      'Order Administrator', 'New Orleans',  'USA',       '(100) 555-4822'),
        (3,  'Grandma Kelly''s Homestead',       'Regina Murphy',      'Sales Representative','Ann Arbor',    'USA',       '(313) 555-5735'),
        (4,  'Tokyo Traders',                    'Yoshi Nagase',       'Marketing Manager',   'Tokyo',        'Japan',     '(03) 3555-5011'),
        (5,  'Cooperativa de Quesos Las Cabras', 'Antonio del Valle',  'Export Administrator','Oviedo',       'Spain',     '(98) 598 76 54'),
        (6,  'Mayumi''s',                        'Mayumi Ohkawa',      'Marketing Representative','Osaka',    'Japan',     '(06) 431-7877'),
        (7,  'Pavlova, Ltd.',                    'Ian Devling',        'Marketing Manager',   'Melbourne',    'Australia', '(03) 444-2343'),
        (8,  'Specialty Biscuits, Ltd.',         'Peter Wilson',       'Sales Representative','Manchester',   'UK',        '(161) 555-4448'),
        (9,  'PB Knäckebröd AB',                 'Lars Peterson',      'Sales Agent',         'Göteborg',     'Sweden',    '031-987 65 43'),
        (10, 'Refrescos Americanas LTDA',        'Carlos Diaz',        'Marketing Manager',   'Sao Paulo',    'Brazil',    '(11) 555 4640');
    SET IDENTITY_INSERT [dbo].[Suppliers] OFF;
    PRINT 'Suppliers seeded.';
END
GO

-- ============================================================
-- Shippers
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Shippers] WHERE [ShipperID] = 1)
BEGIN
    SET IDENTITY_INSERT [dbo].[Shippers] ON;
    INSERT INTO [dbo].[Shippers] ([ShipperID],[CompanyName],[Phone]) VALUES
        (1, 'Speedy Express', '(503) 555-9831'),
        (2, 'United Package', '(503) 555-3199'),
        (3, 'Federal Shipping','(503) 555-9931');
    SET IDENTITY_INSERT [dbo].[Shippers] OFF;
    PRINT 'Shippers seeded.';
END
GO

-- ============================================================
-- Customers (20 representative records)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Customers] WHERE [CustomerID] = 'ALFKI')
BEGIN
    INSERT INTO [dbo].[Customers] ([CustomerID],[CompanyName],[ContactName],[ContactTitle],[City],[Country],[Phone]) VALUES
        ('ALFKI','Alfreds Futterkiste',         'Maria Anders',       'Sales Representative','Berlin',        'Germany',  '030-0074321'),
        ('ANATR','Ana Trujillo Emparedados',    'Ana Trujillo',       'Owner',               'México D.F.',   'Mexico',   '(5) 555-4729'),
        ('ANTON','Antonio Moreno Taquería',     'Antonio Moreno',     'Owner',               'México D.F.',   'Mexico',   '(5) 555-3932'),
        ('AROUT','Around the Horn',             'Thomas Hardy',       'Sales Representative','London',        'UK',       '(171) 555-7788'),
        ('BERGS','Berglunds snabbköp',          'Christina Berglund', 'Order Administrator', 'Luleå',         'Sweden',   '0921-12 34 65'),
        ('BLAUS','Blauer See Delikatessen',     'Hanna Moos',         'Sales Representative','Mannheim',      'Germany',  '0621-08460'),
        ('BLONP','Blondel père et fils',        'Frédérique Citeaux', 'Marketing Manager',   'Strasbourg',    'France',   '88.60.15.31'),
        ('BOLID','Bólido Comidas preparadas',   'Martín Sommer',      'Owner',               'Madrid',        'Spain',    '(91) 555 22 82'),
        ('BONAP','Bon app''',                   'Laurence Lebihan',   'Owner',               'Marseille',     'France',   '91.24.45.40'),
        ('BOTTM','Bottom-Dollar Markets',       'Elizabeth Lincoln',  'Accounting Manager',  'Tsawassen',     'Canada',   '(604) 555-4729'),
        ('BSBEV','B''s Beverages',              'Victoria Ashworth',  'Sales Representative','London',        'UK',       '(171) 555-1212'),
        ('CACTU','Cactus Comidas para llevar',  'Patricio Simpson',   'Sales Agent',         'Buenos Aires',  'Argentina','(1) 135-5555'),
        ('CENTC','Centro comercial Moctezuma',  'Francisco Chang',    'Marketing Manager',   'México D.F.',   'Mexico',   '(5) 555-3392'),
        ('CHOPS','Chop-suey Chinese',           'Yang Wang',          'Owner',               'Bern',          'Switzerland','0452-076545'),
        ('COMMI','Comércio Mineiro',            'Pedro Afonso',       'Sales Associate',     'Sao Paulo',     'Brazil',   '(11) 555-7647'),
        ('CONSH','Consolidated Holdings',       'Elizabeth Brown',    'Sales Representative','London',        'UK',       '(171) 555-2282'),
        ('DRACD','Drachenblut Delikatessen',    'Sven Ottlieb',       'Order Administrator', 'Aachen',        'Germany',  '0241-039123'),
        ('DUMON','Du monde entier',             'Janine Labrune',     'Owner',               'Nantes',        'France',   '40.67.88.88'),
        ('EASTC','Eastern Connection',          'Ann Devon',          'Sales Agent',         'London',        'UK',       '(171) 555-0297'),
        ('ERNSH','Ernst Handel',                'Roland Mendel',      'Sales Manager',       'Graz',          'Austria',  '7675-3425');
    PRINT 'Customers seeded (20 records).';
END
GO

-- ============================================================
-- Employees
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Employees] WHERE [EmployeeID] = 1)
BEGIN
    SET IDENTITY_INSERT [dbo].[Employees] ON;
    INSERT INTO [dbo].[Employees] ([EmployeeID],[LastName],[FirstName],[Title],[TitleOfCourtesy],[BirthDate],[HireDate],[City],[Country],[ReportsTo]) VALUES
        (1, 'Davolio',   'Nancy',   'Sales Representative',      'Ms.', '1968-12-08', '1992-05-01', 'Seattle',  'USA',  2),
        (2, 'Fuller',    'Andrew',  'Vice President, Sales',     'Dr.', '1952-02-19', '1992-08-14', 'Tacoma',   'USA',  NULL),
        (3, 'Leverling', 'Janet',   'Sales Representative',      'Ms.', '1963-08-30', '1992-04-01', 'Kirkland', 'USA',  2),
        (4, 'Peacock',   'Margaret','Sales Representative',      'Mrs.','1958-09-19', '1993-05-03', 'Redmond',  'USA',  2),
        (5, 'Buchanan',  'Steven',  'Sales Manager',             'Mr.', '1955-03-04', '1993-10-17', 'London',   'UK',   2),
        (6, 'Suyama',    'Michael', 'Sales Representative',      'Mr.', '1963-07-02', '1993-10-17', 'London',   'UK',   5),
        (7, 'King',      'Robert',  'Sales Representative',      'Mr.', '1960-05-29', '1994-01-02', 'London',   'UK',   5),
        (8, 'Callahan',  'Laura',   'Inside Sales Coordinator',  'Ms.', '1958-01-09', '1994-03-05', 'Seattle',  'USA',  2),
        (9, 'Dodsworth', 'Anne',    'Sales Representative',      'Ms.', '1969-01-27', '1994-11-15', 'London',   'UK',   5);
    SET IDENTITY_INSERT [dbo].[Employees] OFF;
    PRINT 'Employees seeded.';
END
GO

-- ============================================================
-- Products
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductID] = 1)
BEGIN
    SET IDENTITY_INSERT [dbo].[Products] ON;
    INSERT INTO [dbo].[Products] ([ProductID],[ProductName],[SupplierID],[CategoryID],[QuantityPerUnit],[UnitPrice],[UnitsInStock],[UnitsOnOrder],[ReorderLevel],[Discontinued]) VALUES
        (1,  'Chai',                          1,  1, '10 boxes x 20 bags', 18.00,  39,  0,  10, 0),
        (2,  'Chang',                         1,  1, '24 - 12 oz bottles', 19.00,  17, 40,  25, 0),
        (3,  'Aniseed Syrup',                 1,  2, '12 - 550 ml bottles',10.00,  13, 70,  25, 0),
        (4,  'Chef Anton''s Cajun Seasoning', 2,  2, '48 - 6 oz jars',     22.00,  53,  0,   0, 0),
        (5,  'Chef Anton''s Gumbo Mix',       2,  2, '36 boxes',           21.35,   0,  0,   0, 1),
        (6,  'Grandma''s Boysenberry Spread', 3,  2, '12 - 8 oz jars',     25.00, 120,  0,  25, 0),
        (7,  'Uncle Bob''s Organic Dried Pears',3, 7,'12 - 1 lb pkgs.',    30.00,  15,  0,  10, 0),
        (8,  'Northwoods Cranberry Sauce',    3,  2, '12 - 12 oz jars',    40.00,   6,  0,   0, 0),
        (9,  'Mishi Kobe Niku',               4,  6, '18 - 500 g pkgs.',   97.00,  29,  0,   0, 1),
        (10, 'Ikura',                         4,  8, '12 - 200 ml jars',   31.00,  31,  0,   0, 0),
        (11, 'Queso Cabrales',                5,  4, '1 kg pkg.',          21.00,  22, 30,  30, 0),
        (12, 'Queso Manchego La Pastora',     5,  4, '10 - 500 g pkgs.',   38.00,  86,  0,   0, 0),
        (13, 'Konbu',                         6,  8, '2 kg box',            6.00,  24,  0,   5, 0),
        (14, 'Tofu',                          6,  7, '40 - 100 g pkgs.',   23.25,  35,  0,   0, 0),
        (15, 'Genen Shouyu',                  6,  2, '24 - 250 ml bottles',13.00,  39,  0,   5, 0),
        (16, 'Pavlova',                       7,  3, '32 - 500 g boxes',   17.45, 29,   0,  10, 0),
        (17, 'Alice Mutton',                  7,  6, '20 - 1 kg tins',     39.00,   0,  0,   0, 1),
        (18, 'Carnarvon Tigers',              7,  8, '16 kg pkg.',          62.50,  42,  0,   0, 0),
        (19, 'Teatime Chocolate Biscuits',    8,  3, '10 boxes x 12 pieces', 9.20,  25,  0,   5, 0),
        (20, 'Sir Rodney''s Marmalade',       8,  3, '30 gift boxes',      81.00,  40,  0,   0, 0);
    SET IDENTITY_INSERT [dbo].[Products] OFF;
    PRINT 'Products seeded (20 records).';
END
GO

-- ============================================================
-- Region
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Region] WHERE [RegionID] = 1)
BEGIN
    INSERT INTO [dbo].[Region] ([RegionID],[RegionDescription]) VALUES
        (1, 'Eastern '),
        (2, 'Western '),
        (3, 'Northern'),
        (4, 'Southern');
    PRINT 'Region seeded.';
END
GO

-- ============================================================
-- Orders & OrderDetails (sample — 5 orders, multiple lines)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Orders] WHERE [OrderID] = 10248)
BEGIN
    SET IDENTITY_INSERT [dbo].[Orders] ON;
    INSERT INTO [dbo].[Orders] ([OrderID],[CustomerID],[EmployeeID],[OrderDate],[RequiredDate],[ShippedDate],[ShipVia],[Freight],[ShipName],[ShipCity],[ShipCountry]) VALUES
        (10248,'VINET',5,'1996-07-04','1996-08-01','1996-07-16',3,32.38,'Vins et alcools Chevalier','Reims','France'),
        (10249,'TOMSP',6,'1996-07-05','1996-08-16','1996-07-10',1,11.61,'Toms Spezialitäten','Münster','Germany'),
        (10250,'HANAR',4,'1996-07-08','1996-08-05','1996-07-12',2,65.83,'Hanari Carnes','Rio de Janeiro','Brazil'),
        (10251,'VICTE',3,'1996-07-08','1996-08-05','1996-07-15',1,41.34,'Victuailles en stock','Lyon','France'),
        (10252,'SUPRD',4,'1996-07-09','1996-08-06','1996-07-11',2,51.30,'Suprêmes délices','Charleroi','Belgium');
    SET IDENTITY_INSERT [dbo].[Orders] OFF;

    INSERT INTO [dbo].[OrderDetails] ([OrderID],[ProductID],[UnitPrice],[Quantity],[Discount]) VALUES
        (10248, 11, 14.00, 12, 0),
        (10248, 42, 9.80,  10, 0),
        (10248, 72, 34.80,  5, 0),
        (10249, 14, 18.60,  9, 0),
        (10249, 51, 42.40, 40, 0),
        (10250,  41,7.70,  10, 0),
        (10250,  51,42.40, 35, 0.15),
        (10250,  65,16.80, 15, 0.15),
        (10251,  22,16.80,  6, 0.05),
        (10251,  57,15.60, 15, 0.05),
        (10251,  65,16.80, 20, 0),
        (10252,  20,64.80, 40, 0.05),
        (10252,  33,2.00,  25, 0.05),
        (10252,  60,27.20, 40, 0);
    PRINT 'Orders and OrderDetails seeded (5 orders, 14 lines).';
END
GO

PRINT '';
PRINT '=== NorthWindOLTP seed data complete ===';
PRINT 'Next: run 02_CreateDWDatabase.sql to create the Data Warehouse.';
GO
