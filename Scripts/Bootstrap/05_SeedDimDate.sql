/*
================================================================================
 Bootstrap Script — Step 5: Seed DimDate and Unknown Members
 Script:    05_SeedDimDate.sql
 Purpose:   Populates the DimDate dimension for 1990-01-01 through 2030-12-31
            (covers all Northwind OLTP data PLUS a forward buffer to 2030),
            and inserts:
              - DateKey = 0  (Unknown / N/A fallback for NULL dates)
              - Surrogate key = -1 Unknown members for all dimensions
--------------------------------------------------------------------------------
 FIX (CRITICAL-04): Original range was 1996-1999 only.  Dates outside that
 window mapped to DateKey = 0, silently corrupting date-based analytics.
 Extended to 1990-2030 to cover all historical and future transactions safely.
================================================================================
*/
USE [NorthWindDW];
GO

SET NOCOUNT ON;
PRINT '=== Seeding DimDate (1990-2030) ===';

-- ============================================================
-- 1. Seed DateKey = 0 (Unknown / Not Applicable)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[DimDate] WHERE [DateKey] = 0)
BEGIN
    INSERT INTO [dbo].[DimDate] (
        [DateKey],[FullDate],[Year],[Quarter],[Month],[Day],
        [MonthName],[QuarterName],[DayOfWeek],[DayName],
        [IsWeekend],[WeekOfYear],[Semester],[SemesterName]
    )
    VALUES (0, '1900-01-01', 1900, 1, 1, 1, 'Unknown', 'Q1', 0, 'Unknown', 0, 1, 1, 'S1');
    PRINT 'DateKey = 0 (Unknown) inserted.';
END
GO

-- ============================================================
-- 2. Seed calendar 1990-01-01 through 2030-12-31
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[DimDate] WHERE [DateKey] = 19900101)
BEGIN
    DECLARE @d   DATE = '1990-01-01';
    DECLARE @end DATE = '2030-12-31';

    WHILE @d <= @end
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM [dbo].[DimDate] WHERE [DateKey] = CONVERT(INT, CONVERT(VARCHAR(8), @d, 112)))
        BEGIN
            INSERT INTO [dbo].[DimDate] (
                [DateKey],[FullDate],[Year],[Quarter],[Month],[Day],
                [MonthName],[QuarterName],[DayOfWeek],[DayName],
                [IsWeekend],[WeekOfYear],[Semester],[SemesterName]
            )
            VALUES (
                CONVERT(INT, CONVERT(VARCHAR(8), @d, 112)),
                @d,
                YEAR(@d),
                DATEPART(QUARTER, @d),
                MONTH(@d),
                DAY(@d),
                DATENAME(MONTH, @d),
                'Q' + CAST(DATEPART(QUARTER, @d) AS VARCHAR),
                DATEPART(WEEKDAY, @d) - 1,
                DATENAME(WEEKDAY, @d),
                CASE WHEN DATEPART(WEEKDAY, @d) IN (1,7) THEN 1 ELSE 0 END,
                DATEPART(WEEK, @d),
                CASE WHEN DATEPART(QUARTER, @d) <= 2 THEN 1 ELSE 2 END,
                CASE WHEN DATEPART(QUARTER, @d) <= 2 THEN 'S1' ELSE 'S2' END
            );
        END
        SET @d = DATEADD(DAY, 1, @d);
    END

    PRINT 'DimDate calendar (1990-2030) populated.';
END
ELSE
    PRINT 'DimDate already populated — skipping.';
GO

-- ============================================================
-- 3. Seed Unknown members (surrogate key = -1) in all dimensions
-- ============================================================
PRINT '=== Seeding Unknown dimension members ===';

-- DimCustomer
SET IDENTITY_INSERT [dbo].[DimCustomer] ON;
IF NOT EXISTS (SELECT 1 FROM [dbo].[DimCustomer] WHERE [CustomerKey] = -1)
BEGIN
    INSERT INTO [dbo].[DimCustomer] (
        [CustomerKey],[CustomerID],[CompanyName],[ValidFrom],[IsCurrent],[CreatedDate],[ModifiedDate]
    )
    VALUES (-1,'N/A','Unknown','1900-01-01',1,'1900-01-01','1900-01-01');
    PRINT 'DimCustomer Unknown member inserted.';
END
SET IDENTITY_INSERT [dbo].[DimCustomer] OFF;
GO

-- DimEmployee
SET IDENTITY_INSERT [dbo].[DimEmployee] ON;
IF NOT EXISTS (SELECT 1 FROM [dbo].[DimEmployee] WHERE [EmployeeKey] = -1)
BEGIN
    INSERT INTO [dbo].[DimEmployee] (
        [EmployeeKey],[EmployeeID],[LastName],[FirstName],[FullName],[CreatedDate],[ModifiedDate]
    )
    VALUES (-1,-1,'Unknown','Unknown','Unknown','1900-01-01','1900-01-01');
    PRINT 'DimEmployee Unknown member inserted.';
END
SET IDENTITY_INSERT [dbo].[DimEmployee] OFF;
GO

-- DimProduct
SET IDENTITY_INSERT [dbo].[DimProduct] ON;
IF NOT EXISTS (SELECT 1 FROM [dbo].[DimProduct] WHERE [ProductKey] = -1)
BEGIN
    INSERT INTO [dbo].[DimProduct] (
        [ProductKey],[ProductID],[ProductName],[CategoryName],[SupplierCompanyName],
        [UnitPrice],[Discontinued],[CreatedDate],[ModifiedDate]
    )
    VALUES (-1,-1,'Unknown','Unknown','Unknown',0,0,'1900-01-01','1900-01-01');
    PRINT 'DimProduct Unknown member inserted.';
END
SET IDENTITY_INSERT [dbo].[DimProduct] OFF;
GO

-- DimShipper
SET IDENTITY_INSERT [dbo].[DimShipper] ON;
IF NOT EXISTS (SELECT 1 FROM [dbo].[DimShipper] WHERE [ShipperKey] = -1)
BEGIN
    INSERT INTO [dbo].[DimShipper] (
        [ShipperKey],[ShipperID],[CompanyName],[CreatedDate],[ModifiedDate]
    )
    VALUES (-1,-1,'Unknown','1900-01-01','1900-01-01');
    PRINT 'DimShipper Unknown member inserted.';
END
SET IDENTITY_INSERT [dbo].[DimShipper] OFF;
GO

PRINT '';
PRINT '=== DimDate and Unknown members seeding complete ===';
PRINT 'Next: run 06_RunFullLoad.sql to execute the first ETL pipeline.';
GO
