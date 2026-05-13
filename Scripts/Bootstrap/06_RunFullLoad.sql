/*
================================================================================
 Bootstrap Script — Step 6: Run First Full ETL Load
 Script:    06_RunFullLoad.sql
================================================================================
 Run this after:
   - NorthWindOLTP is deployed and seeded
   - NorthWindDW is deployed (tables, procedures)
   - DimDate is populated (05_SeedDimDate.sql)
================================================================================
*/
USE [NorthWindDW];
GO

PRINT '=== Running DW Full Load ===';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 120);
GO

EXEC [dbo].[DW_RunFullLoad];
GO

PRINT 'Completed: ' + CONVERT(VARCHAR, GETDATE(), 120);
GO
