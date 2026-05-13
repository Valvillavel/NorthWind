/*
================================================================================
 Bootstrap Script — Step 4: Bootstrap NorthWindDW Schema
 Script:    04_Bootstrap_DW.sql
 Purpose:   Creates the complete NorthWindDW schema:
              - staging schema
              - ETL control tables
              - dimension tables
              - fact table
              - staging tables
              - ETL stored procedures
              - analytical views
            Run this ONLY if you are not deploying via SSDT DACPAC.
            If using SSDT, deploy the NorthWindDW project instead.
================================================================================
*/
USE [NorthWindDW];
GO

SET NOCOUNT ON;
PRINT '=== Bootstrapping NorthWindDW schema ===';
GO

-- ============================================================
-- Schemas
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
    EXEC ('CREATE SCHEMA [staging] AUTHORIZATION [dbo]');
PRINT 'Schema [staging] ready.';
GO

-- ============================================================
-- ETL Control: PackageConfig
-- ============================================================
IF OBJECT_ID('[dbo].[PackageConfig]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[PackageConfig] (
        [ConfigID]     INT            IDENTITY (1,1) NOT NULL,
        [ConfigName]   NVARCHAR(100)  NOT NULL,
        [ConfigValue]  NVARCHAR(500)  NOT NULL,
        [Description]  NVARCHAR(500)  NULL,
        [CreatedDate]  DATETIME       NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] DATETIME       NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_PackageConfig] PRIMARY KEY CLUSTERED ([ConfigID]),
        CONSTRAINT [UQ_PackageConfig_ConfigName] UNIQUE ([ConfigName])
    );
    PRINT 'Table PackageConfig created.';
END
GO

-- ============================================================
-- ETL Control: ETLExecutionLog
-- ============================================================
IF OBJECT_ID('[dbo].[ETLExecutionLog]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[ETLExecutionLog] (
        [ExecutionID]     INT            IDENTITY (1,1) NOT NULL,
        [BatchID]         INT            NOT NULL,
        [ProcedureName]   NVARCHAR(200)  NOT NULL,
        [StartTime]       DATETIME       NOT NULL DEFAULT GETDATE(),
        [EndTime]         DATETIME       NULL,
        [DurationSeconds] AS (DATEDIFF(SECOND, [StartTime], [EndTime])) PERSISTED,
        [Status]          NVARCHAR(20)   NOT NULL DEFAULT 'RUNNING',
        [RowsExtracted]   INT            NULL,
        [RowsInserted]    INT            NULL,
        [RowsUpdated]     INT            NULL,
        [RowsRejected]    INT            NULL,
        [ErrorMessage]    NVARCHAR(MAX)  NULL,
        [SourceSystem]    NVARCHAR(50)   NULL DEFAULT 'Northwind_OLTP',
        [TargetObject]    NVARCHAR(200)  NULL,
        [Notes]           NVARCHAR(MAX)  NULL,
        CONSTRAINT [PK_ETLExecutionLog] PRIMARY KEY CLUSTERED ([ExecutionID]),
        CONSTRAINT [CK_ETLExecutionLog_Status]
            CHECK ([Status] IN ('RUNNING','SUCCESS','FAILED','WARNING','SKIPPED'))
    );
    CREATE NONCLUSTERED INDEX [IX_ETLExecutionLog_BatchID]  ON [dbo].[ETLExecutionLog] ([BatchID]);
    CREATE NONCLUSTERED INDEX [IX_ETLExecutionLog_Status]   ON [dbo].[ETLExecutionLog] ([Status]);
    PRINT 'Table ETLExecutionLog created.';
END
GO

-- ============================================================
-- ETL Control: ETLErrorLog
-- ============================================================
IF OBJECT_ID('[dbo].[ETLErrorLog]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[ETLErrorLog] (
        [ErrorID]        INT            IDENTITY (1,1) NOT NULL,
        [BatchID]        INT            NOT NULL,
        [ExecutionID]    INT            NULL,
        [ProcedureName]  NVARCHAR(200)  NOT NULL,
        [ErrorTime]      DATETIME       NOT NULL DEFAULT GETDATE(),
        [ErrorNumber]    INT            NULL,
        [ErrorSeverity]  INT            NULL,
        [ErrorState]     INT            NULL,
        [ErrorLine]      INT            NULL,
        [ErrorMessage]   NVARCHAR(MAX)  NOT NULL,
        [SourceSystem]   NVARCHAR(50)   NULL DEFAULT 'Northwind_OLTP',
        [AffectedObject] NVARCHAR(200)  NULL,
        [InputParameters]NVARCHAR(MAX)  NULL,
        CONSTRAINT [PK_ETLErrorLog] PRIMARY KEY CLUSTERED ([ErrorID])
    );
    CREATE NONCLUSTERED INDEX [IX_ETLErrorLog_BatchID]   ON [dbo].[ETLErrorLog] ([BatchID]);
    CREATE NONCLUSTERED INDEX [IX_ETLErrorLog_ErrorTime] ON [dbo].[ETLErrorLog] ([ErrorTime] DESC);
    PRINT 'Table ETLErrorLog created.';
END
GO

-- ============================================================
-- Dimension: DimDate
-- ============================================================
IF OBJECT_ID('[dbo].[DimDate]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DimDate] (
        [DateKey]      INT           NOT NULL,
        [FullDate]     DATE          NOT NULL,
        [Year]         INT           NOT NULL,
        [Quarter]      INT           NOT NULL,
        [Month]        INT           NOT NULL,
        [Day]          INT           NOT NULL,
        [MonthName]    NVARCHAR(20)  NOT NULL,
        [QuarterName]  NVARCHAR(10)  NOT NULL,
        [DayOfWeek]    INT           NOT NULL,
        [DayName]      NVARCHAR(20)  NOT NULL,
        [IsWeekend]    BIT           NOT NULL DEFAULT 0,
        [WeekOfYear]   INT           NOT NULL,
        [Semester]     INT           NOT NULL,
        [SemesterName] NVARCHAR(10)  NOT NULL,
        [IsHoliday]    BIT           NOT NULL DEFAULT 0,
        [HolidayName]  NVARCHAR(100) NULL,
        CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED ([DateKey])
    );
    CREATE NONCLUSTERED INDEX [IX_DimDate_Year_Month] ON [dbo].[DimDate] ([Year],[Month]);
    CREATE NONCLUSTERED INDEX [IX_DimDate_FullDate]   ON [dbo].[DimDate] ([FullDate]);
    PRINT 'Table DimDate created.';
END
GO

-- ============================================================
-- Dimension: DimCustomer (SCD Type 1 with IsCurrent flag)
-- ============================================================
IF OBJECT_ID('[dbo].[DimCustomer]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DimCustomer] (
        [CustomerKey]  INT            IDENTITY (1,1) NOT NULL,
        [CustomerID]   NCHAR(5)       NOT NULL,
        [CompanyName]  NVARCHAR(40)   NOT NULL,
        [ContactName]  NVARCHAR(30)   NULL,
        [ContactTitle] NVARCHAR(30)   NULL,
        [Address]      NVARCHAR(60)   NULL,
        [City]         NVARCHAR(15)   NULL,
        [Region]       NVARCHAR(15)   NULL,
        [PostalCode]   NVARCHAR(10)   NULL,
        [Country]      NVARCHAR(15)   NULL,
        [Phone]        NVARCHAR(24)   NULL,
        [Fax]          NVARCHAR(24)   NULL,
        [CustomerDesc] NVARCHAR(MAX)  NULL,
        [ValidFrom]    DATETIME       NOT NULL DEFAULT GETDATE(),
        [ValidTo]      DATETIME       NULL,
        [IsCurrent]    BIT            NOT NULL DEFAULT 1,
        [CreatedDate]  DATETIME       NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] DATETIME       NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_DimCustomer] PRIMARY KEY CLUSTERED ([CustomerKey])
    );
    CREATE NONCLUSTERED INDEX [IX_DimCustomer_CustomerID] ON [dbo].[DimCustomer] ([CustomerID]);
    CREATE NONCLUSTERED INDEX [IX_DimCustomer_IsCurrent]  ON [dbo].[DimCustomer] ([IsCurrent]);
    CREATE NONCLUSTERED INDEX [IX_DimCustomer_Country]    ON [dbo].[DimCustomer] ([Country]);
    PRINT 'Table DimCustomer created.';
END
GO

-- ============================================================
-- Dimension: DimEmployee
-- ============================================================
IF OBJECT_ID('[dbo].[DimEmployee]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DimEmployee] (
        [EmployeeKey]          INT           IDENTITY (1,1) NOT NULL,
        [EmployeeID]           INT           NOT NULL,
        [LastName]             NVARCHAR(20)  NOT NULL,
        [FirstName]            NVARCHAR(10)  NOT NULL,
        [FullName]             NVARCHAR(31)  NOT NULL,
        [Title]                NVARCHAR(30)  NULL,
        [TitleOfCourtesy]      NVARCHAR(25)  NULL,
        [BirthDate]            DATETIME      NULL,
        [HireDate]             DATETIME      NULL,
        [Address]              NVARCHAR(60)  NULL,
        [City]                 NVARCHAR(15)  NULL,
        [Region]               NVARCHAR(15)  NULL,
        [PostalCode]           NVARCHAR(10)  NULL,
        [Country]              NVARCHAR(15)  NULL,
        [HomePhone]            NVARCHAR(24)  NULL,
        [Extension]            NVARCHAR(4)   NULL,
        [ReportsTo]            INT           NULL,
        [ManagerName]          NVARCHAR(31)  NULL,
        [TerritoryDescription] NCHAR(50)     NULL,
        [RegionDescription]    NCHAR(50)     NULL,
        [CreatedDate]          DATETIME      NOT NULL DEFAULT GETDATE(),
        [ModifiedDate]         DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_DimEmployee] PRIMARY KEY CLUSTERED ([EmployeeKey])
    );
    CREATE NONCLUSTERED INDEX [IX_DimEmployee_EmployeeID] ON [dbo].[DimEmployee] ([EmployeeID]);
    CREATE NONCLUSTERED INDEX [IX_DimEmployee_Country]    ON [dbo].[DimEmployee] ([Country]);
    PRINT 'Table DimEmployee created.';
END
GO

-- ============================================================
-- Dimension: DimProduct
-- ============================================================
IF OBJECT_ID('[dbo].[DimProduct]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DimProduct] (
        [ProductKey]          INT           IDENTITY (1,1) NOT NULL,
        [ProductID]           INT           NOT NULL,
        [ProductName]         NVARCHAR(40)  NOT NULL,
        [CategoryName]        NVARCHAR(15)  NOT NULL,
        [SupplierCompanyName] NVARCHAR(40)  NOT NULL,
        [QuantityPerUnit]     NVARCHAR(20)  NULL,
        [UnitPrice]           MONEY         NULL,
        [UnitsInStock]        SMALLINT      NULL,
        [UnitsOnOrder]        SMALLINT      NULL,
        [ReorderLevel]        SMALLINT      NULL,
        [Discontinued]        BIT           NOT NULL,
        [CreatedDate]         DATETIME      NOT NULL DEFAULT GETDATE(),
        [ModifiedDate]        DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_DimProduct] PRIMARY KEY CLUSTERED ([ProductKey])
    );
    CREATE NONCLUSTERED INDEX [IX_DimProduct_ProductID]  ON [dbo].[DimProduct] ([ProductID]);
    CREATE NONCLUSTERED INDEX [IX_DimProduct_Category]   ON [dbo].[DimProduct] ([CategoryName]);
    PRINT 'Table DimProduct created.';
END
GO

-- ============================================================
-- Dimension: DimShipper
-- ============================================================
IF OBJECT_ID('[dbo].[DimShipper]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[DimShipper] (
        [ShipperKey]   INT           IDENTITY (1,1) NOT NULL,
        [ShipperID]    INT           NOT NULL,
        [CompanyName]  NVARCHAR(40)  NOT NULL,
        [Phone]        NVARCHAR(24)  NULL,
        [CreatedDate]  DATETIME      NOT NULL DEFAULT GETDATE(),
        [ModifiedDate] DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_DimShipper] PRIMARY KEY CLUSTERED ([ShipperKey])
    );
    CREATE NONCLUSTERED INDEX [IX_DimShipper_ShipperID] ON [dbo].[DimShipper] ([ShipperID]);
    PRINT 'Table DimShipper created.';
END
GO

-- ============================================================
-- Fact: FactOrders
-- ============================================================
IF OBJECT_ID('[dbo].[FactOrders]', 'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[FactOrders] (
        [OrderKey]        BIGINT         IDENTITY (1,1) NOT NULL,
        [OrderID]         INT            NOT NULL,
        [CustomerKey]     INT            NOT NULL,
        [EmployeeKey]     INT            NOT NULL,
        [ProductKey]      INT            NOT NULL,
        [ShipperKey]      INT            NOT NULL,
        [DateKeyOrder]    INT            NOT NULL,
        [DateKeyRequired] INT            NOT NULL,
        [DateKeyShipped]  INT            NOT NULL,
        [Quantity]        DECIMAL(18,4)  NOT NULL,
        [UnitPrice]       MONEY          NOT NULL,
        [Discount]        REAL           NOT NULL,
        [Freight]         MONEY          NOT NULL,
        [LineTotal]       AS (CONVERT(MONEY, [Quantity] * [UnitPrice] * (1 - [Discount]))),
        [OrderTotal]      MONEY          NULL,
        [CreatedDate]     DATETIME       NOT NULL DEFAULT GETDATE(),
        [ETLBatchID]      INT            NULL,
        [SourceSystem]    NVARCHAR(50)   DEFAULT ('Northwind_OLTP'),
        CONSTRAINT [PK_FactOrders] PRIMARY KEY CLUSTERED ([OrderKey]),
        CONSTRAINT [FK_FactOrders_DimCustomer]       FOREIGN KEY ([CustomerKey])     REFERENCES [dbo].[DimCustomer] ([CustomerKey]),
        CONSTRAINT [FK_FactOrders_DimEmployee]       FOREIGN KEY ([EmployeeKey])     REFERENCES [dbo].[DimEmployee] ([EmployeeKey]),
        CONSTRAINT [FK_FactOrders_DimProduct]        FOREIGN KEY ([ProductKey])      REFERENCES [dbo].[DimProduct]  ([ProductKey]),
        CONSTRAINT [FK_FactOrders_DimShipper]        FOREIGN KEY ([ShipperKey])      REFERENCES [dbo].[DimShipper]  ([ShipperKey]),
        CONSTRAINT [FK_FactOrders_DimDate_Order]     FOREIGN KEY ([DateKeyOrder])    REFERENCES [dbo].[DimDate]     ([DateKey]),
        CONSTRAINT [FK_FactOrders_DimDate_Required]  FOREIGN KEY ([DateKeyRequired]) REFERENCES [dbo].[DimDate]     ([DateKey]),
        CONSTRAINT [FK_FactOrders_DimDate_Shipped]   FOREIGN KEY ([DateKeyShipped])  REFERENCES [dbo].[DimDate]     ([DateKey])
    );
    CREATE NONCLUSTERED INDEX [IX_FactOrders_CustomerKey]  ON [dbo].[FactOrders] ([CustomerKey]);
    CREATE NONCLUSTERED INDEX [IX_FactOrders_EmployeeKey]  ON [dbo].[FactOrders] ([EmployeeKey]);
    CREATE NONCLUSTERED INDEX [IX_FactOrders_ProductKey]   ON [dbo].[FactOrders] ([ProductKey]);
    CREATE NONCLUSTERED INDEX [IX_FactOrders_DateKeyOrder] ON [dbo].[FactOrders] ([DateKeyOrder]);
    PRINT 'Table FactOrders created.';
END
GO

-- ============================================================
-- Staging tables
-- ============================================================
IF OBJECT_ID('[staging].[Customer]', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[Customer] (
        [CustomerID]   NCHAR(5)      NOT NULL,
        [CompanyName]  NVARCHAR(40)  NOT NULL,
        [ContactName]  NVARCHAR(30)  NULL,
        [ContactTitle] NVARCHAR(30)  NULL,
        [Address]      NVARCHAR(60)  NULL,
        [City]         NVARCHAR(15)  NULL,
        [Region]       NVARCHAR(15)  NULL,
        [PostalCode]   NVARCHAR(10)  NULL,
        [Country]      NVARCHAR(15)  NULL,
        [Phone]        NVARCHAR(24)  NULL,
        [Fax]          NVARCHAR(24)  NULL,
        [CustomerDesc] NVARCHAR(MAX) NULL,
        [RowVersion]   BIGINT        NULL,
        [BatchID]      INT           NULL,
        [LoadedAt]     DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_stg_Customer] PRIMARY KEY CLUSTERED ([CustomerID])
    );
    PRINT 'Table staging.Customer created.';
END
GO

IF OBJECT_ID('[staging].[Employee]', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[Employee] (
        [EmployeeID]           INT           NOT NULL,
        [LastName]             NVARCHAR(20)  NOT NULL,
        [FirstName]            NVARCHAR(10)  NOT NULL,
        [Title]                NVARCHAR(30)  NULL,
        [TitleOfCourtesy]      NVARCHAR(25)  NULL,
        [BirthDate]            DATETIME      NULL,
        [HireDate]             DATETIME      NULL,
        [Address]              NVARCHAR(60)  NULL,
        [City]                 NVARCHAR(15)  NULL,
        [Region]               NVARCHAR(15)  NULL,
        [PostalCode]           NVARCHAR(10)  NULL,
        [Country]              NVARCHAR(15)  NULL,
        [HomePhone]            NVARCHAR(24)  NULL,
        [Extension]            NVARCHAR(4)   NULL,
        [ReportsTo]            INT           NULL,
        [ManagerName]          NVARCHAR(31)  NULL,
        [TerritoryDescription] NCHAR(50)     NULL,
        [RegionDescription]    NCHAR(50)     NULL,
        [RowVersion]           BIGINT        NULL,
        [BatchID]              INT           NULL,
        [LoadedAt]             DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_stg_Employee] PRIMARY KEY CLUSTERED ([EmployeeID])
    );
    PRINT 'Table staging.Employee created.';
END
GO

IF OBJECT_ID('[staging].[Product]', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[Product] (
        [ProductID]           INT           NOT NULL,
        [ProductName]         NVARCHAR(40)  NOT NULL,
        [CategoryName]        NVARCHAR(15)  NOT NULL,
        [SupplierCompanyName] NVARCHAR(40)  NOT NULL,
        [QuantityPerUnit]     NVARCHAR(20)  NULL,
        [UnitPrice]           MONEY         NULL,
        [UnitsInStock]        SMALLINT      NULL,
        [UnitsOnOrder]        SMALLINT      NULL,
        [ReorderLevel]        SMALLINT      NULL,
        [Discontinued]        BIT           NOT NULL,
        [RowVersion]          BIGINT        NULL,
        [BatchID]             INT           NULL,
        [LoadedAt]            DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_stg_Product] PRIMARY KEY CLUSTERED ([ProductID])
    );
    PRINT 'Table staging.Product created.';
END
GO

IF OBJECT_ID('[staging].[Shipper]', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[Shipper] (
        [ShipperID]   INT           NOT NULL,
        [CompanyName] NVARCHAR(40)  NOT NULL,
        [Phone]       NVARCHAR(24)  NULL,
        [RowVersion]  BIGINT        NULL,
        [BatchID]     INT           NULL,
        [LoadedAt]    DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_stg_Shipper] PRIMARY KEY CLUSTERED ([ShipperID])
    );
    PRINT 'Table staging.Shipper created.';
END
GO

IF OBJECT_ID('[staging].[Order]', 'U') IS NULL
BEGIN
    CREATE TABLE [staging].[Order] (
        [OrderID]      INT       NOT NULL,
        [CustomerID]   NCHAR(5)  NULL,
        [EmployeeID]   INT       NULL,
        [ShipperID]    INT       NULL,
        [ProductID]    INT       NOT NULL,
        [OrderDate]    DATETIME  NULL,
        [RequiredDate] DATETIME  NULL,
        [ShippedDate]  DATETIME  NULL,
        [Freight]      MONEY     NULL,
        [UnitPrice]    MONEY     NOT NULL,
        [Quantity]     SMALLINT  NOT NULL,
        [Discount]     REAL      NOT NULL,
        [OrderTotal]   MONEY     NULL,
        [BatchID]      INT       NULL,
        [LoadedAt]     DATETIME  NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_stg_Order] PRIMARY KEY CLUSTERED ([OrderID],[ProductID])
    );
    PRINT 'Table staging.Order created.';
END
GO

PRINT '';
PRINT '=== NorthWindDW schema bootstrap complete ===';
PRINT 'Next: run 05_SeedDimDate.sql to populate the date dimension.';
GO
