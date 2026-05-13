/*
================================================================================
 Bootstrap Script — NorthWind End-to-End BI Solution
 Script:    00_MasterDeploy.sql
 Purpose:   Master deployment orchestration script.
            Execute the numbered scripts in order against a fresh SQL Server
            instance to stand up the complete NorthWind BI solution.
 Author:    NorthWind BI Team
 Version:   3.0
================================================================================
 PREREQUISITES
   - SQL Server 2017+ (rowversion, COLUMNSTORE INDEX, window functions)
   - Execute as sysadmin or db_owner on target server
   - Option A (SSDT): Deploy NorthWind.sqlproj and NorthWindDW DACPAC via SSDT
   - Option B (scripts): Run scripts 01–07 in sequence in SSMS
================================================================================
 EXECUTION ORDER
   01_CreateOLTPDatabase.sql  — Create NorthWindOLTP schema from scratch
   02_CreateDWDatabase.sql    — Create NorthWindDW database and staging schema
   03_SeedOLTPData.sql        — Insert Northwind OLTP sample data
   04_Bootstrap_DW.sql        — Build all DW tables, staging, and FK constraints
   05_SeedDimDate.sql         — Populate DimDate (1996-1999) + Unknown members
   06_RunFullLoad.sql         — Execute first full ETL pipeline (all stages)
   07_ValidateDeployment.sql  — Validate row counts and referential integrity
================================================================================
 ARCHITECTURE OVERVIEW
   NorthWindOLTP    Transactional source (3NF, SSDT project)
   NorthWindDW      Dimensional warehouse (star schema, SSDT project)
     staging.*      Extraction buffer — isolated from DW tables
     dbo.*Dim*      Conformed dimensions (SCD Type 1)
     dbo.FactOrders Order-line fact (grain: one row per OrderID + ProductID)
   Analytics/       Ad-hoc analytical SQL query library
   Scripts/         Bootstrap and deployment automation
   Docs/            Architecture and data dictionary documentation
================================================================================
*/

PRINT '================================================================';
PRINT 'NorthWind BI Solution — Master Deployment';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '================================================================';
PRINT '';
PRINT 'Execute the following scripts in sequence:';
PRINT '';
PRINT '  STEP 1: Scripts\Bootstrap\01_CreateOLTPDatabase.sql';
PRINT '          Creates NorthWindOLTP database and all OLTP tables.';
PRINT '';
PRINT '  STEP 2: Scripts\Bootstrap\02_CreateDWDatabase.sql';
PRINT '          Creates NorthWindDW database and staging schema.';
PRINT '';
PRINT '  STEP 3: Scripts\Bootstrap\03_SeedOLTPData.sql';
PRINT '          Inserts Northwind sample data (customers, products, orders...).';
PRINT '';
PRINT '  STEP 4: Scripts\Bootstrap\04_Bootstrap_DW.sql';
PRINT '          Creates DW dimensions, fact table, staging tables, and ETL procs.';
PRINT '';
PRINT '  STEP 5: Scripts\Bootstrap\05_SeedDimDate.sql';
PRINT '          Populates DimDate (1996-1999) and Unknown members (key = -1).';
PRINT '';
PRINT '  STEP 6: Scripts\Bootstrap\06_RunFullLoad.sql';
PRINT '          Executes the first full ETL load: staging -> dimensions -> fact.';
PRINT '';
PRINT '  STEP 7: Scripts\Bootstrap\07_ValidateDeployment.sql';
PRINT '          Validates row counts, FK integrity, and KPI sanity checks.';
PRINT '';
PRINT 'See README.md for full deployment documentation and architecture overview.';
PRINT '================================================================';
GO
