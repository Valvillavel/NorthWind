# ETL Architecture — NorthWind BI Solution

## Overview

The NorthWind ETL pipeline is a fully modular, T-SQL-based Extract-Transform-Load framework that moves data from the `NorthWindOLTP` transactional database into the `NorthWindDW` analytical warehouse.

---

## Architecture Diagram

```
NorthWindOLTP                   NorthWindDW
─────────────                   ───────────
dbo.Customers   ──── extract ──▶ staging.Customer   ──▶ DimCustomer
dbo.Employees   ──── extract ──▶ staging.Employee   ──▶ DimEmployee
dbo.Products    ──── extract ──▶ staging.Product    ──▶ DimProduct
dbo.Shippers    ──── extract ──▶ staging.Shipper    ──▶ DimShipper
dbo.Orders      ──┐
dbo.OrderDetails──┘ extract ──▶ staging.Order       ──▶ FactOrders
                                                          │
                                                    ◀─────┘
                                              DimDate (pre-seeded)
```

---

## ETL Layers

### Layer 1 — Extraction (staging)

Staging procedures isolate raw extraction from transformation. They:

- truncate staging before each load (clean room pattern)
- apply rowversion watermark filtering for incremental loads
- join OLTP source tables and denormalize into staging-friendly columns
- capture batch metadata (`BatchID`, `LoadedAt`)

| Procedure | Source | Target |
|---|---|---|
| `DW_LoadStagingCustomers` | Customers + CustomerDemographics | staging.Customer |
| `DW_LoadStagingEmployees` | Employees + Territories + Region | staging.Employee |
| `DW_LoadStagingProducts` | Products + Categories + Suppliers | staging.Product |
| `DW_LoadStagingShippers` | Shippers | staging.Shipper |
| `DW_LoadStagingOrders` | Orders + OrderDetails (joined) | staging.Order |

### Layer 2 — Validation

`DW_ValidateStagingData` runs 8 data quality checks before any merge:

| # | Check | Severity |
|---|---|---|
| 1 | NULL or empty CustomerID / CompanyName | Error |
| 2 | Duplicate CustomerID in staging | Error |
| 3 | NULL mandatory Employee fields | Error |
| 4 | Negative UnitPrice, zero/negative Quantity, invalid Discount | Error |
| 5 | Orders referencing unknown CustomerIDs | Warning |
| 6 | Future OrderDate | Warning |
| 7 | RequiredDate before OrderDate | Warning |
| 8 | NULL CategoryName or SupplierCompanyName in Product | Warning |

Errors halt the pipeline (`@FailOnError = 1`). Warnings are logged but do not block.

### Layer 3 — Dimension Merge

Each dimension procedure uses an **upsert pattern** (UPDATE existing + INSERT new) with TRY/CATCH:

- `DW_MergeDimCustomer` — SCD Type 1 (in-place update), tracks `IsCurrent`/`ValidFrom`
- `DW_MergeDimEmployee` — SCD Type 1, denormalizes manager name, territory, region
- `DW_MergeDimProduct` — SCD Type 1, denormalizes category and supplier names
- `DW_MergeDimShipper` — SCD Type 1, direct field-level update

All use surrogate keys (`IDENTITY`). Business keys are preserved as separate columns.

### Layer 4 — Fact Load

`DW_MergeFactOrders`:

- inserts new order-line rows only (append-only pattern, no updates)
- resolves surrogate keys from each dimension by joining on business keys
- falls back to surrogate key = **-1** (Unknown) for unresolved FK lookups
- falls back to DateKey = **0** for NULL dates
- pre-computes `LineTotal` as a computed column: `Quantity × UnitPrice × (1 - Discount)`

**Fact grain**: one row per `OrderID + ProductID` combination.

---

## Incremental Load Strategy

Incremental loads use **SQL Server rowversion** (binary timestamp) as a watermark:

1. Each OLTP table has a `rowversion` column (auto-updated on every DML)
2. The last processed `rowversion` is stored in `PackageConfig` per entity
3. On incremental runs, only rows with `rowversion > @LastRowVersion` are extracted
4. After a successful load, `PackageConfig` is updated with the new high watermark
5. Shippers and Orders are always reloaded (small tables, no incremental overhead)

```
Incremental load flow:
  GetLastPackageRowVersion('Customer')  → @CustomerStart
  SELECT MAX(rowversion) FROM Customers → @CustomerEnd
  IF @CustomerEnd > @CustomerStart
      EXTRACT rows WHERE rowversion BETWEEN @CustomerStart+1 AND @CustomerEnd
      MERGE into DimCustomer
      UpdateLastPackageRowVersion('Customer', @CustomerEnd)
```

---

## Orchestration Procedures

| Procedure | Purpose |
|---|---|
| `DW_RunFullLoad` | Full reload: truncates staging, loads all entities, merges all dimensions, loads fact |
| `DW_RunIncrementalLoad` | Incremental: loads only changed entities per watermark, always reloads orders |

---

## ETL Monitoring

All ETL activity is observable via two control tables:

### ETLExecutionLog

Records every procedure call with:
- `BatchID` (auto-incremented per run)
- `ProcedureName`
- `Status`: RUNNING / SUCCESS / FAILED / WARNING / SKIPPED
- `StartTime`, `EndTime`, `DurationSeconds`
- `RowsExtracted`, `RowsInserted`, `RowsUpdated`
- `TargetObject`

### ETLErrorLog

Records every error with:
- `BatchID`, `ExecutionID`
- `ErrorNumber`, `ErrorSeverity`, `ErrorState`, `ErrorLine`
- `ErrorMessage`, `AffectedObject`

### Useful Monitoring Queries

```sql
-- Recent ETL runs
SELECT TOP 20 * FROM [dbo].[ETLExecutionLog]
ORDER BY [StartTime] DESC;

-- Failed steps
SELECT * FROM [dbo].[ETLExecutionLog]
WHERE [Status] = 'FAILED'
ORDER BY [StartTime] DESC;

-- Batch summary
SELECT [BatchID],
       MIN([StartTime])  AS [BatchStart],
       MAX([EndTime])    AS [BatchEnd],
       SUM([RowsInserted]) AS [TotalInserted],
       SUM([RowsUpdated])  AS [TotalUpdated],
       COUNT(CASE WHEN [Status]='FAILED' THEN 1 END) AS [FailedSteps]
FROM [dbo].[ETLExecutionLog]
GROUP BY [BatchID]
ORDER BY [BatchID] DESC;
```

---

## Error Handling Standards

All ETL procedures follow this pattern:

```sql
BEGIN TRY
    BEGIN TRANSACTION;
    -- ETL logic here
    COMMIT TRANSACTION;
    -- Log success to ETLExecutionLog
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    -- Insert to ETLErrorLog
    -- Update ETLExecutionLog to FAILED
    THROW; -- re-raise to caller
END CATCH;
```

---

## PackageConfig Keys

| ConfigName | Default | Purpose |
|---|---|---|
| `Customer_LastRowVersion` | 0 | Incremental watermark for Customers |
| `Employee_LastRowVersion` | 0 | Incremental watermark for Employees |
| `Product_LastRowVersion` | 0 | Incremental watermark for Products |
| `Shipper_LastRowVersion` | 0 | Incremental watermark for Shippers |
| `Orders_LastRowVersion` | 0 | Incremental watermark for Orders |
| `ETL_Enabled` | 1 | Global ETL enable/disable switch |
| `Batch_Size` | 10000 | Batch size for bulk operations |
