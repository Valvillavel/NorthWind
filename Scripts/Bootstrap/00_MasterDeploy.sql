/*
================================================================================
 NorthWind BI Solution — Master Bootstrap Script
 Script:    00_MasterDeploy.sql
 Purpose:   Single-command, fully automated deployment of the complete
            NorthWind BI solution from a clean SQL Server instance.

            Executes scripts 01–07 in strict dependency order:
              01  Create NorthWindOLTP database and all OLTP tables
              02  Create NorthWindDW database, staging schema, and DW objects
              03  Seed NorthWindOLTP with Northwind sample data
              04  Bootstrap NorthWindDW schema (tables, procs, views)
              05  Seed DimDate (1990-2030) and Unknown members (key=-1)
              06  Run first full ETL load (staging → dimensions → FactOrders)
              07  Validate deployment (row counts, FK integrity, KPI checks)

 PREREQUISITES
   - SQL Server 2017+ (rowversion, window functions, columnstore support)
   - Execute as sysadmin or db_owner on the target instance
   - Run via SQLCMD or SQL Server Agent with SQLCMD mode enabled:
       sqlcmd -S <server> -E -i "Scripts\Bootstrap\00_MasterDeploy.sql"

 ARCHITECTURE
   NorthWindOLTP   Transactional OLTP source (3NF, rowversion CDC)
   NorthWindDW     Star schema data warehouse
     staging.*     Extraction buffer (ephemeral, truncated each full load)
     dbo.Dim*      Conformed dimensions
       DimCustomer   SCD Type 2 — full attribute history preserved
       DimEmployee   SCD Type 1 — current state only (territory denormalised)
       DimProduct    SCD Type 1 — current state only
       DimShipper    SCD Type 1 — current state only
       DimDate       Static calendar 1990-01-01 to 2030-12-31
     dbo.FactOrders  Order-line fact (grain: OrderID + ProductID)
       Unknown members: surrogate key = -1 for all dimensions
       Unknown date:    DateKey = 0

 IDEMPOTENCY
   All scripts use IF NOT EXISTS / IF OBJECT_ID checks.
   Safe to re-run on an existing environment (will skip existing objects).

 DEPLOYMENT FLOW (linear dependency chain)
   master → NorthWindOLTP tables → OLTP data seed
         → NorthWindDW tables → DimDate seed → Unknown members
         → DW_RunFullLoad → validation

 VERSION   3.1 (Hardening phase — SCD2 DimCustomer, incremental Orders)
================================================================================
*/

PRINT '================================================================';
PRINT 'NorthWind BI Solution — Master Bootstrap';
PRINT 'Started: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '================================================================';
GO

-- ============================================================
-- STEP 1: Create NorthWindOLTP database and all OLTP tables
-- ============================================================
PRINT '';
PRINT '--- STEP 1: NorthWindOLTP database and tables ---';
GO
:r .\01_CreateOLTPDatabase.sql

-- ============================================================
-- STEP 2: Create NorthWindDW database
-- ============================================================
PRINT '';
PRINT '--- STEP 2: NorthWindDW database ---';
GO
:r .\02_CreateDWDatabase.sql

-- ============================================================
-- STEP 3: Seed NorthWindOLTP with Northwind sample data
-- ============================================================
PRINT '';
PRINT '--- STEP 3: NorthWindOLTP data seed ---';
GO
:r .\03_SeedOLTPData.sql

-- ============================================================
-- STEP 4: Bootstrap NorthWindDW schema
--         (tables, staging, ETL procs, views)
-- ============================================================
PRINT '';
PRINT '--- STEP 4: NorthWindDW schema bootstrap ---';
GO
:r .\04_Bootstrap_DW.sql

-- ============================================================
-- STEP 5: Seed DimDate (1990-2030) and Unknown members
-- ============================================================
PRINT '';
PRINT '--- STEP 5: DimDate and Unknown members seed ---';
GO
:r .\05_SeedDimDate.sql

-- ============================================================
-- STEP 6: Run first full ETL load
-- ============================================================
PRINT '';
PRINT '--- STEP 6: Full ETL load ---';
GO
:r .\06_RunFullLoad.sql

-- ============================================================
-- STEP 7: Validate deployment
-- ============================================================
PRINT '';
PRINT '--- STEP 7: Deployment validation ---';
GO
:r .\07_ValidateDeployment.sql

GO
PRINT '';
PRINT '================================================================';
PRINT 'NorthWind BI Solution — Bootstrap COMPLETE';
PRINT 'Finished: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '================================================================';
GO
