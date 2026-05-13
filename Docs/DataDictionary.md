# Data Dictionary — NorthWind BI Solution

## NorthWindOLTP — Transactional Database

### dbo.Categories

| Column | Type | Nullable | Description |
|---|---|---|---|
| CategoryID | INT IDENTITY | NO | Surrogate primary key |
| CategoryName | NVARCHAR(15) | NO | Unique category name |
| Description | NVARCHAR(MAX) | YES | Product category description |
| Picture | IMAGE | YES | Category image (legacy) |
| rowversion | ROWVERSION | YES | Auto-updated binary timestamp for change tracking |
| CreatedDate | DATETIME | NO | Record creation timestamp |
| UpdatedDate | DATETIME | NO | Record last-update timestamp |

---

### dbo.Customers

| Column | Type | Nullable | Description |
|---|---|---|---|
| CustomerID | NCHAR(5) | NO | Business key — 5-char customer code |
| CompanyName | NVARCHAR(40) | NO | Customer company name |
| ContactName | NVARCHAR(30) | YES | Primary contact name |
| ContactTitle | NVARCHAR(30) | YES | Contact job title |
| Address | NVARCHAR(60) | YES | Street address |
| City | NVARCHAR(15) | YES | City |
| Region | NVARCHAR(15) | YES | Region / state |
| PostalCode | NVARCHAR(10) | YES | Postal code |
| Country | NVARCHAR(15) | YES | Country |
| Phone | NVARCHAR(24) | YES | Phone number |
| Fax | NVARCHAR(24) | YES | Fax number |
| rowversion | ROWVERSION | YES | Incremental load watermark |
| CreatedDate | DATETIME | NO | Record creation timestamp |
| UpdatedDate | DATETIME | NO | Record last-update timestamp |

---

### dbo.Employees

| Column | Type | Nullable | Description |
|---|---|---|---|
| EmployeeID | INT IDENTITY | NO | Surrogate primary key |
| LastName | NVARCHAR(20) | NO | Employee last name |
| FirstName | NVARCHAR(10) | NO | Employee first name |
| Title | NVARCHAR(30) | YES | Job title |
| TitleOfCourtesy | NVARCHAR(25) | YES | Honorific (Mr., Ms., Dr.) |
| BirthDate | DATETIME | YES | Date of birth (must be < today) |
| HireDate | DATETIME | YES | Date of hire |
| Address | NVARCHAR(60) | YES | Home address |
| City | NVARCHAR(15) | YES | City |
| Region | NVARCHAR(15) | YES | Region |
| PostalCode | NVARCHAR(10) | YES | Postal code |
| Country | NVARCHAR(15) | YES | Country |
| HomePhone | NVARCHAR(24) | YES | Home phone |
| Extension | NVARCHAR(4) | YES | Office extension |
| Photo | IMAGE | YES | Employee photo (binary) |
| Notes | NVARCHAR(MAX) | YES | Biography notes |
| ReportsTo | INT | YES | FK to self — manager's EmployeeID |
| PhotoPath | NVARCHAR(255) | YES | Path to photo file |
| rowversion | ROWVERSION | YES | Incremental load watermark |
| CreatedDate | DATETIME | NO | Record creation timestamp |
| UpdatedDate | DATETIME | NO | Record last-update timestamp |

---

### dbo.Shippers

| Column | Type | Nullable | Description |
|---|---|---|---|
| ShipperID | INT IDENTITY | NO | Surrogate primary key |
| CompanyName | NVARCHAR(40) | NO | Shipping company name |
| Phone | NVARCHAR(24) | YES | Contact phone |
| rowversion | ROWVERSION | YES | Incremental load watermark |
| CreatedDate | DATETIME | NO | Record creation timestamp |
| UpdatedDate | DATETIME | NO | Record last-update timestamp |

---

### dbo.Suppliers

| Column | Type | Nullable | Description |
|---|---|---|---|
| SupplierID | INT IDENTITY | NO | Surrogate primary key |
| CompanyName | NVARCHAR(40) | NO | Supplier company name |
| ContactName | NVARCHAR(30) | YES | Primary contact |
| ContactTitle | NVARCHAR(30) | YES | Contact title |
| Address | NVARCHAR(60) | YES | Street address |
| City | NVARCHAR(15) | YES | City |
| Region | NVARCHAR(15) | YES | Region |
| PostalCode | NVARCHAR(10) | YES | Postal code |
| Country | NVARCHAR(15) | YES | Country |
| Phone | NVARCHAR(24) | YES | Phone |
| Fax | NVARCHAR(24) | YES | Fax |
| HomePage | NVARCHAR(MAX) | YES | Company website |
| rowversion | ROWVERSION | YES | Incremental load watermark |
| CreatedDate | DATETIME | NO | Record creation timestamp |
| UpdatedDate | DATETIME | NO | Record last-update timestamp |

---

### dbo.Products

| Column | Type | Nullable | Description |
|---|---|---|---|
| ProductID | INT IDENTITY | NO | Surrogate primary key |
| ProductName | NVARCHAR(40) | NO | Product name |
| SupplierID | INT | YES | FK → Suppliers |
| CategoryID | INT | YES | FK → Categories |
| QuantityPerUnit | NVARCHAR(20) | YES | Package description (e.g. "24 cans x 8 oz") |
| UnitPrice | MONEY | YES | List price (≥ 0) |
| UnitsInStock | SMALLINT | YES | Current stock level (≥ 0) |
| UnitsOnOrder | SMALLINT | YES | Units on open purchase orders (≥ 0) |
| ReorderLevel | SMALLINT | YES | Minimum stock threshold before reorder |
| Discontinued | BIT | NO | Product availability flag |
| rowversion | ROWVERSION | YES | Incremental load watermark |
| CreatedDate | DATETIME | NO | Record creation timestamp |
| UpdatedDate | DATETIME | NO | Record last-update timestamp |

---

### dbo.Orders

| Column | Type | Nullable | Description |
|---|---|---|---|
| OrderID | INT IDENTITY | NO | Surrogate primary key |
| CustomerID | NCHAR(5) | YES | FK → Customers |
| EmployeeID | INT | YES | FK → Employees |
| OrderDate | DATETIME | YES | Date the order was placed |
| RequiredDate | DATETIME | YES | Requested delivery date (≥ OrderDate) |
| ShippedDate | DATETIME | YES | Actual shipment date (≥ OrderDate) |
| ShipVia | INT | YES | FK → Shippers |
| Freight | MONEY | YES | Shipping cost (≥ 0) |
| ShipName | NVARCHAR(40) | YES | Shipping recipient name |
| ShipAddress | NVARCHAR(60) | YES | Shipping address |
| ShipCity | NVARCHAR(15) | YES | Shipping city |
| ShipRegion | NVARCHAR(15) | YES | Shipping region |
| ShipPostalCode | NVARCHAR(10) | YES | Shipping postal code |
| ShipCountry | NVARCHAR(15) | YES | Shipping country |
| rowversion | ROWVERSION | YES | Incremental load watermark |
| CreatedDate | DATETIME | NO | Record creation timestamp |
| UpdatedDate | DATETIME | NO | Record last-update timestamp |

---

### dbo.OrderDetails

| Column | Type | Nullable | Description |
|---|---|---|---|
| OrderID | INT | NO | FK → Orders (PK component 1) |
| ProductID | INT | NO | FK → Products (PK component 2) |
| UnitPrice | MONEY | NO | Actual selling price at order time (≥ 0) |
| Quantity | SMALLINT | NO | Units ordered (> 0) |
| Discount | REAL | NO | Discount fraction applied (0.00–1.00) |
| rowversion | ROWVERSION | YES | Change tracking |
| CreatedDate | DATETIME | NO | Record creation timestamp |
| UpdatedDate | DATETIME | NO | Record last-update timestamp |

---

## NorthWindDW — Data Warehouse

### Fact: dbo.FactOrders

**Grain**: one row per `OrderID + ProductID` combination (order line level).

| Column | Type | Nullable | Description |
|---|---|---|---|
| OrderKey | BIGINT IDENTITY | NO | DW surrogate key |
| OrderID | INT | NO | OLTP source order number |
| CustomerKey | INT | NO | FK → DimCustomer (−1 = Unknown) |
| EmployeeKey | INT | NO | FK → DimEmployee (−1 = Unknown) |
| ProductKey | INT | NO | FK → DimProduct (−1 = Unknown) |
| ShipperKey | INT | NO | FK → DimShipper (−1 = Unknown) |
| DateKeyOrder | INT | NO | FK → DimDate (0 = Unknown) |
| DateKeyRequired | INT | NO | FK → DimDate (0 = Unknown) |
| DateKeyShipped | INT | NO | FK → DimDate (0 = Unknown) |
| Quantity | DECIMAL(18,4) | NO | Units ordered |
| UnitPrice | MONEY | NO | Price at time of order |
| Discount | REAL | NO | Discount fraction (0–1) |
| Freight | MONEY | NO | Freight cost for this order |
| **LineTotal** | **MONEY (computed)** | — | `Quantity × UnitPrice × (1 − Discount)` |
| OrderTotal | MONEY | YES | Sum of all line totals for the order |
| CreatedDate | DATETIME | NO | DW load timestamp |
| ETLBatchID | INT | YES | ETL batch identifier |
| SourceSystem | NVARCHAR(50) | YES | Source system identifier |

---

### Dimension: dbo.DimCustomer

| Column | Type | Description |
|---|---|---|
| CustomerKey | INT IDENTITY | DW surrogate key |
| CustomerID | NCHAR(5) | OLTP business key |
| CompanyName | NVARCHAR(40) | Company name |
| ContactName | NVARCHAR(30) | Contact person |
| City / Region / Country | NVARCHAR | Geography attributes |
| CustomerDesc | NVARCHAR(MAX) | Customer segment description |
| ValidFrom | DATETIME | SCD validity start |
| ValidTo | DATETIME | SCD validity end (NULL = current) |
| IsCurrent | BIT | 1 = active current record |
| CreatedDate / ModifiedDate | DATETIME | Audit timestamps |

**Special member**: `CustomerKey = −1` → "Unknown" / unresolved FK fallback.

---

### Dimension: dbo.DimDate

| Column | Type | Description |
|---|---|---|
| DateKey | INT | YYYYMMDD integer key (0 = Unknown) |
| FullDate | DATE | Calendar date |
| Year | INT | Calendar year |
| Quarter | INT | 1–4 |
| Month | INT | 1–12 |
| Day | INT | Day of month |
| MonthName | NVARCHAR(20) | Full month name |
| QuarterName | NVARCHAR(10) | Q1–Q4 |
| DayOfWeek | INT | 0 = Sunday |
| DayName | NVARCHAR(20) | Full day name |
| IsWeekend | BIT | 1 = Saturday or Sunday |
| WeekOfYear | INT | ISO week number |
| Semester | INT | 1 or 2 |
| SemesterName | NVARCHAR(10) | S1 or S2 |
| IsHoliday | BIT | Holiday flag (enrichable) |
| HolidayName | NVARCHAR(100) | Holiday name if applicable |

**Special member**: `DateKey = 0` → "Unknown" date fallback for NULL dates.

---

### Dimension: dbo.DimEmployee

| Column | Type | Description |
|---|---|---|
| EmployeeKey | INT IDENTITY | DW surrogate key |
| EmployeeID | INT | OLTP business key |
| FullName | NVARCHAR(31) | Concatenated first + last name |
| Title | NVARCHAR(30) | Job title |
| Country | NVARCHAR(15) | Country of employment |
| ManagerName | NVARCHAR(31) | Denormalized manager full name |
| TerritoryDescription | NCHAR(50) | Primary territory |
| RegionDescription | NCHAR(50) | Region |

---

### Dimension: dbo.DimProduct

| Column | Type | Description |
|---|---|---|
| ProductKey | INT IDENTITY | DW surrogate key |
| ProductID | INT | OLTP business key |
| ProductName | NVARCHAR(40) | Product name |
| CategoryName | NVARCHAR(15) | Denormalized category name |
| SupplierCompanyName | NVARCHAR(40) | Denormalized supplier name |
| UnitPrice | MONEY | Current list price |
| Discontinued | BIT | Product discontinuation flag |

---

### Dimension: dbo.DimShipper

| Column | Type | Description |
|---|---|---|
| ShipperKey | INT IDENTITY | DW surrogate key |
| ShipperID | INT | OLTP business key |
| CompanyName | NVARCHAR(40) | Shipping company name |
| Phone | NVARCHAR(24) | Contact phone |

---

## ETL Control Tables

### dbo.PackageConfig

Key-value configuration store for ETL watermarks and settings.

| ConfigName | Default | Purpose |
|---|---|---|
| `Customer_LastRowVersion` | 0 | Incremental watermark for Customers |
| `Employee_LastRowVersion` | 0 | Incremental watermark for Employees |
| `Product_LastRowVersion` | 0 | Incremental watermark for Products |
| `Shipper_LastRowVersion` | 0 | Incremental watermark for Shippers |
| `Orders_LastRowVersion` | 0 | Incremental watermark for Orders |
| `ETL_Enabled` | 1 | Pipeline enable/disable flag |
| `Batch_Size` | 10000 | Rows per batch |

### dbo.ETLExecutionLog

Execution audit trail. One row per procedure call. Status values: `RUNNING`, `SUCCESS`, `FAILED`, `WARNING`, `SKIPPED`.

### dbo.ETLErrorLog

Error detail log. Captures SQL Server error metadata (`ErrorNumber`, `ErrorSeverity`, `ErrorLine`, `ErrorMessage`) plus the affected object and batch context.

---

## Naming Conventions

| Convention | Rule | Example |
|---|---|---|
| DW Tables | PascalCase with Dim/Fact prefix | `DimCustomer`, `FactOrders` |
| Staging Tables | PascalCase, `staging` schema | `staging.Customer` |
| OLTP Tables | PascalCase | `OrderDetails`, `Customers` |
| Primary Keys | `PK_<TableName>` | `PK_DimCustomer` |
| Foreign Keys | `FK_<Table>_<Referenced>` | `FK_FactOrders_DimCustomer` |
| Indexes (DW) | `IX_<Table>_<Column>` | `IX_DimCustomer_CustomerID` |
| ETL Procedures | `DW_<Action><Object>` | `DW_MergeDimCustomer` |
| OLTP Procedures | `usp_<Verb><Object>` | `usp_GetCustomerOrders` |
| Analytics Views | `vw_<Description>` | `vw_SalesByCustomer` |
