/*
================================================================================
 Script Post-Deployment — NorthWind Data Warehouse
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
