/*
================================================================================
 Script Post-Deployment — NorthWind Data Warehouse
================================================================================
 FIX (CRITICAL-05): This script was a documentation stub (PRINT-only) that
 caused SSDT DACPAC deployments to produce an empty, non-functional database.
 No seed data was applied, leaving DimDate empty, PackageConfig uninitialized,
 and Unknown dimension members absent.  Running DW_RunFullLoad after a SSDT
 deploy would immediately fail with FK violations and silent no-ops.

 Fix: Replace stub with actual :r references executed in dependency order:
   1. PackageConfig rows must exist BEFORE any ETL procedure reads watermarks.
   2. DimDate calendar must exist BEFORE FactOrders inserts (FK on DateKeyOrder).
   3. DateKey = 0 (Unknown date) must exist as FK fallback target.
   4. Unknown members (key = -1) must exist BEFORE FactOrders references them.
================================================================================
 Execution order (SSDT evaluates :r paths relative to project root):
================================================================================
*/

-- Step 1: Initialize ETL configuration keys in PackageConfig
:r .\Scripts\PackageConfig.data.sql

-- Step 2: Populate DimDate calendar (1990-2030) + DateKey = 0 Unknown row
:r .\Scripts\DimDate.data.sql

-- Step 3: Patch DateKey = 0 (Unknown / N/A fallback for NULL dates in FactOrders)
:r .\Scripts\PatchDimDate.data.sql

-- Step 4: Insert surrogate key = -1 Unknown members for all dimensions
--         (DimCustomer, DimEmployee, DimProduct, DimShipper)
--         These are FK targets for NULL dimension references in FactOrders.
:r .\Scripts\UnknownMembers.data.sql
