/*
================================================================================
 Bootstrap Script — Step 7: Validate Deployment
 Script:    07_ValidateDeployment.sql
================================================================================
 Checks row counts across OLTP and DW to confirm successful load.
================================================================================
*/
USE [NorthWindDW];
GO

PRINT '=== NorthWind BI Solution — Deployment Validation ===';
PRINT '';

-- ============================================================
-- 1. DW Dimension & Fact row counts
-- ============================================================
SELECT 'DimCustomer' AS [Table], COUNT(*) AS [RowCount] FROM [dbo].[DimCustomer]
UNION ALL
SELECT 'DimEmployee',            COUNT(*) FROM [dbo].[DimEmployee]
UNION ALL
SELECT 'DimProduct',             COUNT(*) FROM [dbo].[DimProduct]
UNION ALL
SELECT 'DimShipper',             COUNT(*) FROM [dbo].[DimShipper]
UNION ALL
SELECT 'DimDate',                COUNT(*) FROM [dbo].[DimDate]
UNION ALL
SELECT 'FactOrders',             COUNT(*) FROM [dbo].[FactOrders]
UNION ALL
SELECT 'ETLExecutionLog',        COUNT(*) FROM [dbo].[ETLExecutionLog]
UNION ALL
SELECT 'ETLErrorLog',            COUNT(*) FROM [dbo].[ETLErrorLog]
UNION ALL
SELECT 'PackageConfig',          COUNT(*) FROM [dbo].[PackageConfig];

-- ============================================================
-- 2. Confirm no FAILED ETL steps
-- ============================================================
PRINT '';
PRINT 'ETL Steps with errors (should be empty):';
SELECT [ExecutionID], [ProcedureName], [Status], [ErrorMessage], [StartTime]
FROM [dbo].[ETLExecutionLog]
WHERE [Status] = 'FAILED';

-- ============================================================
-- 3. Revenue sanity check
-- ============================================================
PRINT '';
PRINT 'Revenue KPI Snapshot:';
SELECT * FROM [dbo].[vw_KPISummary];

-- ============================================================
-- 4. FactOrders referential integrity spot-check
-- ============================================================
PRINT '';
PRINT 'Orphan CustomerKey in FactOrders (should be 0):';
SELECT COUNT(*) AS [OrphanCustomers]
FROM [dbo].[FactOrders] fo
LEFT JOIN [dbo].[DimCustomer] dc ON fo.[CustomerKey] = dc.[CustomerKey]
WHERE dc.[CustomerKey] IS NULL;

PRINT 'Orphan ProductKey in FactOrders (should be 0):';
SELECT COUNT(*) AS [OrphanProducts]
FROM [dbo].[FactOrders] fo
LEFT JOIN [dbo].[DimProduct] dp ON fo.[ProductKey] = dp.[ProductKey]
WHERE dp.[ProductKey] IS NULL;
GO
