/*
================================================================================
 Bootstrap Script — Step 1: Create NorthWindOLTP Database
 Script:    01_CreateOLTPDatabase.sql
 Purpose:   Creates the NorthWindOLTP transactional database from scratch.
            Run this ONLY if you are not deploying via SSDT DACPAC.
            If using SSDT, deploy NorthWind.sqlproj instead.
================================================================================
*/
USE [master];
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'NorthWindOLTP')
BEGIN
    CREATE DATABASE [NorthWindOLTP]
        COLLATE Latin1_General_CI_AS;
    PRINT 'Database NorthWindOLTP created.';
END
ELSE
    PRINT 'Database NorthWindOLTP already exists — skipping creation.';
GO

USE [NorthWindOLTP];
GO

-- ============================================================
-- Create tables in dependency order
-- ============================================================

IF OBJECT_ID('[dbo].[Categories]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Categories] (
        [CategoryID]   INT            IDENTITY (1, 1) NOT NULL,
        [CategoryName] NVARCHAR (15)  NOT NULL,
        [Description]  NVARCHAR (MAX) NULL,
        [Picture]      IMAGE          NULL,
        [rowversion]   ROWVERSION     NULL,
        [CreatedDate]  DATETIME       NOT NULL DEFAULT GETDATE(),
        [UpdatedDate]  DATETIME       NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED ([CategoryID] ASC),
        CONSTRAINT [UQ_Categories_CategoryName] UNIQUE ([CategoryName])
    );
    CREATE NONCLUSTERED INDEX [IX_Categories_CategoryName] ON [dbo].[Categories]([CategoryName]);
    PRINT 'Table Categories created.';
END
GO

IF OBJECT_ID('[dbo].[Customers]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Customers] (
        [CustomerID]   NCHAR (5)     NOT NULL,
        [CompanyName]  NVARCHAR (40) NOT NULL,
        [ContactName]  NVARCHAR (30) NULL,
        [ContactTitle] NVARCHAR (30) NULL,
        [Address]      NVARCHAR (60) NULL,
        [City]         NVARCHAR (15) NULL,
        [Region]       NVARCHAR (15) NULL,
        [PostalCode]   NVARCHAR (10) NULL,
        [Country]      NVARCHAR (15) NULL,
        [Phone]        NVARCHAR (24) NULL,
        [Fax]          NVARCHAR (24) NULL,
        [rowversion]   ROWVERSION    NULL,
        [CreatedDate]  DATETIME      NOT NULL DEFAULT GETDATE(),
        [UpdatedDate]  DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([CustomerID] ASC)
    );
    CREATE NONCLUSTERED INDEX [IX_Customers_City]        ON [dbo].[Customers]([City]);
    CREATE NONCLUSTERED INDEX [IX_Customers_Country]     ON [dbo].[Customers]([Country]);
    CREATE NONCLUSTERED INDEX [IX_Customers_CompanyName] ON [dbo].[Customers]([CompanyName]);
    PRINT 'Table Customers created.';
END
GO

IF OBJECT_ID('[dbo].[Shippers]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Shippers] (
        [ShipperID]   INT           IDENTITY (1, 1) NOT NULL,
        [CompanyName] NVARCHAR (40) NOT NULL,
        [Phone]       NVARCHAR (24) NULL,
        [rowversion]  ROWVERSION    NULL,
        [CreatedDate] DATETIME      NOT NULL DEFAULT GETDATE(),
        [UpdatedDate] DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_Shippers] PRIMARY KEY CLUSTERED ([ShipperID] ASC)
    );
    PRINT 'Table Shippers created.';
END
GO

IF OBJECT_ID('[dbo].[Suppliers]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Suppliers] (
        [SupplierID]   INT            IDENTITY (1, 1) NOT NULL,
        [CompanyName]  NVARCHAR (40)  NOT NULL,
        [ContactName]  NVARCHAR (30)  NULL,
        [ContactTitle] NVARCHAR (30)  NULL,
        [Address]      NVARCHAR (60)  NULL,
        [City]         NVARCHAR (15)  NULL,
        [Region]       NVARCHAR (15)  NULL,
        [PostalCode]   NVARCHAR (10)  NULL,
        [Country]      NVARCHAR (15)  NULL,
        [Phone]        NVARCHAR (24)  NULL,
        [Fax]          NVARCHAR (24)  NULL,
        [HomePage]     NVARCHAR (MAX) NULL,
        [rowversion]   ROWVERSION     NULL,
        [CreatedDate]  DATETIME       NOT NULL DEFAULT GETDATE(),
        [UpdatedDate]  DATETIME       NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_Suppliers] PRIMARY KEY CLUSTERED ([SupplierID] ASC)
    );
    CREATE NONCLUSTERED INDEX [IX_Suppliers_CompanyName] ON [dbo].[Suppliers]([CompanyName]);
    PRINT 'Table Suppliers created.';
END
GO

IF OBJECT_ID('[dbo].[Employees]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Employees] (
        [EmployeeID]      INT            IDENTITY (1, 1) NOT NULL,
        [LastName]        NVARCHAR (20)  NOT NULL,
        [FirstName]       NVARCHAR (10)  NOT NULL,
        [Title]           NVARCHAR (30)  NULL,
        [TitleOfCourtesy] NVARCHAR (25)  NULL,
        [BirthDate]       DATETIME       NULL,
        [HireDate]        DATETIME       NULL,
        [Address]         NVARCHAR (60)  NULL,
        [City]            NVARCHAR (15)  NULL,
        [Region]          NVARCHAR (15)  NULL,
        [PostalCode]      NVARCHAR (10)  NULL,
        [Country]         NVARCHAR (15)  NULL,
        [HomePhone]       NVARCHAR (24)  NULL,
        [Extension]       NVARCHAR (4)   NULL,
        [Photo]           IMAGE          NULL,
        [Notes]           NVARCHAR (MAX) NULL,
        [ReportsTo]       INT            NULL,
        [PhotoPath]       NVARCHAR (255) NULL,
        [rowversion]      ROWVERSION     NULL,
        [CreatedDate]     DATETIME       NOT NULL DEFAULT GETDATE(),
        [UpdatedDate]     DATETIME       NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_Employees]        PRIMARY KEY CLUSTERED ([EmployeeID] ASC),
        CONSTRAINT [CK_Birthdate]        CHECK ([BirthDate] < GETDATE()),
        CONSTRAINT [FK_Employees_Employees] FOREIGN KEY ([ReportsTo]) REFERENCES [dbo].[Employees] ([EmployeeID])
    );
    CREATE NONCLUSTERED INDEX [IX_Employees_LastName] ON [dbo].[Employees]([LastName]);
    PRINT 'Table Employees created.';
END
GO

IF OBJECT_ID('[dbo].[Products]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Products] (
        [ProductID]       INT           IDENTITY (1, 1) NOT NULL,
        [ProductName]     NVARCHAR (40) NOT NULL,
        [SupplierID]      INT           NULL,
        [CategoryID]      INT           NULL,
        [QuantityPerUnit] NVARCHAR (20) NULL,
        [UnitPrice]       MONEY         DEFAULT ((0)) NULL,
        [UnitsInStock]    SMALLINT      DEFAULT ((0)) NULL,
        [UnitsOnOrder]    SMALLINT      DEFAULT ((0)) NULL,
        [ReorderLevel]    SMALLINT      DEFAULT ((0)) NULL,
        [Discontinued]    BIT           DEFAULT ((0)) NOT NULL,
        [rowversion]      ROWVERSION    NULL,
        [CreatedDate]     DATETIME      NOT NULL DEFAULT GETDATE(),
        [UpdatedDate]     DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_Products]            PRIMARY KEY CLUSTERED ([ProductID] ASC),
        CONSTRAINT [CK_Products_UnitPrice]  CHECK ([UnitPrice]    >= 0),
        CONSTRAINT [CK_ReorderLevel]        CHECK ([ReorderLevel] >= 0),
        CONSTRAINT [CK_UnitsInStock]        CHECK ([UnitsInStock] >= 0),
        CONSTRAINT [CK_UnitsOnOrder]        CHECK ([UnitsOnOrder] >= 0),
        CONSTRAINT [FK_Products_Categories] FOREIGN KEY ([CategoryID]) REFERENCES [dbo].[Categories] ([CategoryID]),
        CONSTRAINT [FK_Products_Suppliers]  FOREIGN KEY ([SupplierID]) REFERENCES [dbo].[Suppliers]  ([SupplierID])
    );
    CREATE NONCLUSTERED INDEX [IX_Products_ProductName] ON [dbo].[Products]([ProductName]);
    CREATE NONCLUSTERED INDEX [IX_Products_CategoryID]  ON [dbo].[Products]([CategoryID]);
    CREATE NONCLUSTERED INDEX [IX_Products_SupplierID]  ON [dbo].[Products]([SupplierID]);
    PRINT 'Table Products created.';
END
GO

IF OBJECT_ID('[dbo].[Orders]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Orders] (
        [OrderID]        INT           IDENTITY (1, 1) NOT NULL,
        [CustomerID]     NCHAR (5)     NULL,
        [EmployeeID]     INT           NULL,
        [OrderDate]      DATETIME      NULL,
        [RequiredDate]   DATETIME      NULL,
        [ShippedDate]    DATETIME      NULL,
        [ShipVia]        INT           NULL,
        [Freight]        MONEY         DEFAULT ((0)) NULL,
        [ShipName]       NVARCHAR (40) NULL,
        [ShipAddress]    NVARCHAR (60) NULL,
        [ShipCity]       NVARCHAR (15) NULL,
        [ShipRegion]     NVARCHAR (15) NULL,
        [ShipPostalCode] NVARCHAR (10) NULL,
        [ShipCountry]    NVARCHAR (15) NULL,
        [rowversion]     ROWVERSION    NULL,
        [CreatedDate]    DATETIME      NOT NULL DEFAULT GETDATE(),
        [UpdatedDate]    DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED ([OrderID] ASC),
        CONSTRAINT [CK_Orders_ShippedAfterOrdered]   CHECK ([ShippedDate]  IS NULL OR [ShippedDate]  >= [OrderDate]),
        CONSTRAINT [CK_Orders_RequiredAfterOrdered]  CHECK ([RequiredDate] IS NULL OR [RequiredDate] >= [OrderDate]),
        CONSTRAINT [CK_Orders_Freight]               CHECK ([Freight] >= 0),
        CONSTRAINT [FK_Orders_Customers]  FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customers] ([CustomerID]),
        CONSTRAINT [FK_Orders_Employees]  FOREIGN KEY ([EmployeeID]) REFERENCES [dbo].[Employees] ([EmployeeID]),
        CONSTRAINT [FK_Orders_Shippers]   FOREIGN KEY ([ShipVia])    REFERENCES [dbo].[Shippers]  ([ShipperID])
    );
    CREATE NONCLUSTERED INDEX [IX_Orders_CustomerID_OrderDate] ON [dbo].[Orders]([CustomerID], [OrderDate]) INCLUDE ([EmployeeID], [ShipVia], [Freight]);
    CREATE NONCLUSTERED INDEX [IX_Orders_EmployeeID]           ON [dbo].[Orders]([EmployeeID]);
    CREATE NONCLUSTERED INDEX [IX_Orders_OrderDate]            ON [dbo].[Orders]([OrderDate]);
    CREATE NONCLUSTERED INDEX [IX_Orders_ShippedDate]          ON [dbo].[Orders]([ShippedDate]);
    PRINT 'Table Orders created.';
END
GO

IF OBJECT_ID('[dbo].[OrderDetails]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[OrderDetails] (
        [OrderID]     INT        NOT NULL,
        [ProductID]   INT        NOT NULL,
        [UnitPrice]   MONEY      DEFAULT ((0)) NOT NULL,
        [Quantity]    SMALLINT   DEFAULT ((1)) NOT NULL,
        [Discount]    REAL       DEFAULT ((0)) NOT NULL,
        [rowversion]  ROWVERSION NULL,
        [CreatedDate] DATETIME   NOT NULL DEFAULT GETDATE(),
        [UpdatedDate] DATETIME   NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_Order_Details]         PRIMARY KEY CLUSTERED ([OrderID], [ProductID]),
        CONSTRAINT [CK_Discount]              CHECK ([Discount]  >= 0 AND [Discount]  <= 1),
        CONSTRAINT [CK_Quantity]              CHECK ([Quantity]  > 0),
        CONSTRAINT [CK_UnitPrice]             CHECK ([UnitPrice] >= 0),
        CONSTRAINT [FK_Order_Details_Orders]   FOREIGN KEY ([OrderID])   REFERENCES [dbo].[Orders]   ([OrderID]),
        CONSTRAINT [FK_Order_Details_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ProductID])
    );
    CREATE NONCLUSTERED INDEX [IX_OrderDetails_ProductID] ON [dbo].[OrderDetails]([ProductID]);
    PRINT 'Table OrderDetails created.';
END
GO

IF OBJECT_ID('[dbo].[Region]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Region] (
        [RegionID]          INT        NOT NULL,
        [RegionDescription] NCHAR (50) NOT NULL,
        [rowversion]        ROWVERSION NULL,
        [CreatedDate]       DATETIME   NOT NULL DEFAULT GETDATE(),
        [UpdatedDate]       DATETIME   NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_Region] PRIMARY KEY NONCLUSTERED ([RegionID] ASC)
    );
    PRINT 'Table Region created.';
END
GO

IF OBJECT_ID('[dbo].[Territories]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Territories] (
        [TerritoryID]          NVARCHAR (20) NOT NULL,
        [TerritoryDescription] NCHAR (50)    NOT NULL,
        [RegionID]             INT           NOT NULL,
        [rowversion]           ROWVERSION    NULL,
        [CreatedDate]          DATETIME      NOT NULL DEFAULT GETDATE(),
        [UpdatedDate]          DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_Territories]       PRIMARY KEY NONCLUSTERED ([TerritoryID] ASC),
        CONSTRAINT [FK_Territories_Region] FOREIGN KEY ([RegionID]) REFERENCES [dbo].[Region] ([RegionID])
    );
    PRINT 'Table Territories created.';
END
GO

IF OBJECT_ID('[dbo].[EmployeeTerritories]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[EmployeeTerritories] (
        [EmployeeID]  INT           NOT NULL,
        [TerritoryID] NVARCHAR (20) NOT NULL,
        [rowversion]  ROWVERSION    NULL,
        CONSTRAINT [PK_EmployeeTerritories]              PRIMARY KEY NONCLUSTERED ([EmployeeID], [TerritoryID]),
        CONSTRAINT [FK_EmployeeTerritories_Employees]    FOREIGN KEY ([EmployeeID])  REFERENCES [dbo].[Employees]  ([EmployeeID]),
        CONSTRAINT [FK_EmployeeTerritories_Territories]  FOREIGN KEY ([TerritoryID]) REFERENCES [dbo].[Territories] ([TerritoryID])
    );
    PRINT 'Table EmployeeTerritories created.';
END
GO

IF OBJECT_ID('[dbo].[CustomerDemographics]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[CustomerDemographics] (
        [CustomerTypeID] NCHAR (10)     NOT NULL,
        [CustomerDesc]   NVARCHAR (MAX) NULL,
        [rowversion]     ROWVERSION     NULL,
        CONSTRAINT [PK_CustomerDemographics] PRIMARY KEY NONCLUSTERED ([CustomerTypeID] ASC)
    );
    PRINT 'Table CustomerDemographics created.';
END
GO

IF OBJECT_ID('[dbo].[CustomerCustomerDemo]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[CustomerCustomerDemo] (
        [CustomerID]     NCHAR (5)  NOT NULL,
        [CustomerTypeID] NCHAR (10) NOT NULL,
        [rowversion]     ROWVERSION NULL,
        CONSTRAINT [PK_CustomerCustomerDemo]            PRIMARY KEY NONCLUSTERED ([CustomerID], [CustomerTypeID]),
        CONSTRAINT [FK_CustomerCustomerDemo]            FOREIGN KEY ([CustomerTypeID]) REFERENCES [dbo].[CustomerDemographics] ([CustomerTypeID]),
        CONSTRAINT [FK_CustomerCustomerDemo_Customers]  FOREIGN KEY ([CustomerID])     REFERENCES [dbo].[Customers]            ([CustomerID])
    );
    PRINT 'Table CustomerCustomerDemo created.';
END
GO

PRINT '';
PRINT 'NorthWindOLTP schema deployment complete.';
PRINT 'Next: run 03_SeedOLTPData.sql to populate sample data.';
GO
