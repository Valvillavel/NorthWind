-- ================================================================================
-- Seed "Unknown" / "Not Applicable" members for all Dimensions
-- These surrogate key = -1 rows act as FK fallback targets for NULL/unresolved
-- foreign keys in FactOrders (instead of blocking inserts).
-- ================================================================================

-- DimCustomer — Unknown member (CustomerKey = -1)
SET IDENTITY_INSERT [dbo].[DimCustomer] ON;

IF NOT EXISTS (SELECT 1 FROM [dbo].[DimCustomer] WHERE [CustomerKey] = -1)
BEGIN
    INSERT INTO [dbo].[DimCustomer] (
        [CustomerKey], [CustomerID], [CompanyName], [ContactName], [ContactTitle],
        [Address], [City], [Region], [PostalCode], [Country], [Phone], [Fax],
        [CustomerDesc], [ValidFrom], [ValidTo], [IsCurrent], [CreatedDate], [ModifiedDate]
    )
    VALUES (
        -1, 'N/A', 'Unknown', NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, '1900-01-01', NULL, 1, '1900-01-01', '1900-01-01'
    );
END

SET IDENTITY_INSERT [dbo].[DimCustomer] OFF;
GO

-- DimEmployee — Unknown member (EmployeeKey = -1)
SET IDENTITY_INSERT [dbo].[DimEmployee] ON;

IF NOT EXISTS (SELECT 1 FROM [dbo].[DimEmployee] WHERE [EmployeeKey] = -1)
BEGIN
    INSERT INTO [dbo].[DimEmployee] (
        [EmployeeKey], [EmployeeID], [LastName], [FirstName], [FullName],
        [Title], [TitleOfCourtesy], [BirthDate], [HireDate],
        [Address], [City], [Region], [PostalCode], [Country],
        [HomePhone], [Extension], [ReportsTo], [ManagerName],
        [TerritoryDescription], [RegionDescription],
        [CreatedDate], [ModifiedDate]
    )
    VALUES (
        -1, -1, 'Unknown', 'Unknown', 'Unknown',
        NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL,
        NULL, NULL,
        '1900-01-01', '1900-01-01'
    );
END

SET IDENTITY_INSERT [dbo].[DimEmployee] OFF;
GO

-- DimProduct — Unknown member (ProductKey = -1)
SET IDENTITY_INSERT [dbo].[DimProduct] ON;

IF NOT EXISTS (SELECT 1 FROM [dbo].[DimProduct] WHERE [ProductKey] = -1)
BEGIN
    INSERT INTO [dbo].[DimProduct] (
        [ProductKey], [ProductID], [ProductName], [CategoryName], [SupplierCompanyName],
        [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [ReorderLevel],
        [Discontinued], [CreatedDate], [ModifiedDate]
    )
    VALUES (
        -1, -1, 'Unknown', 'Unknown', 'Unknown',
        NULL, 0, 0, 0, 0,
        0, '1900-01-01', '1900-01-01'
    );
END

SET IDENTITY_INSERT [dbo].[DimProduct] OFF;
GO

-- DimShipper — Unknown member (ShipperKey = -1)
SET IDENTITY_INSERT [dbo].[DimShipper] ON;

IF NOT EXISTS (SELECT 1 FROM [dbo].[DimShipper] WHERE [ShipperKey] = -1)
BEGIN
    INSERT INTO [dbo].[DimShipper] (
        [ShipperKey], [ShipperID], [CompanyName], [Phone], [CreatedDate], [ModifiedDate]
    )
    VALUES (
        -1, -1, 'Unknown', NULL, '1900-01-01', '1900-01-01'
    );
END

SET IDENTITY_INSERT [dbo].[DimShipper] OFF;
GO
