# NorthWind — Enterprise Data Management & Business Intelligence Solution

A production-grade, end-to-end BI solution built on **SQL Server / T-SQL** using the classic Northwind trading company domain. The repository demonstrates a complete data engineering stack from transactional source to analytical warehouse.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        NorthWindOLTP                            │
│         Transactional Source (3NF, SSDT DACPAC)                 │
│  Customers │ Employees │ Products │ Orders │ OrderDetails │ ...  │
└────────────────────────────┬────────────────────────────────────┘
                             │  rowversion-based extraction
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   NorthWindDW — staging schema                  │
│   staging.Customer │ Employee │ Product │ Shipper │ Order       │
│   ── validation (DW_ValidateStagingData) ──────────────────     │
└────────────────────────────┬────────────────────────────────────┘
                             │  upsert / merge
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   NorthWindDW — star schema                     │
│                                                                 │
│   DimDate    DimCustomer   DimEmployee   DimProduct  DimShipper │
│        └──────────┬──────────────┬──────────┘           │      │
│                   └──────► FactOrders ◄──────────────────┘      │
│                     (grain: OrderID + ProductID)                │
└─────────────────────────────────────────────────────────────────┘
                             │  analytical views + ad-hoc SQL
                             ▼
                       Analytics Layer
              vw_SalesByDate │ vw_SalesByCustomer │ vw_KPISummary
                   Analytics/SalesAnalytics.sql
```

---

## Repository Structure

```
NorthWind/
├── NorthWindOLTP/                      OLTP transactional database (SSDT)
│   └── dbo/
│       ├── Tables/                     13 normalized tables
│       ├── Views/                      16 operational views
│       └── Stored Procedures/          ETL helpers + business SPs
│
├── NorthWindDW/                        Data Warehouse (SSDT)
│   ├── Schema/
│   │   ├── Tables/
│   │   │   ├── dbo/                    DimDate, DimCustomer, DimEmployee,
│   │   │   │                           DimProduct, DimShipper, FactOrders,
│   │   │   │                           ETLExecutionLog, ETLErrorLog, PackageConfig
│   │   │   └── staging/                staging.Customer/Employee/Product/Shipper/Order
│   │   ├── Views/                      8 analytical views (vw_*)
│   │   └── Programmability/
│   │       └── Stored Procedures/      15 ETL procedures
│   └── Scripts/                        Post-deployment seed data
│
├── Analytics/                          Ad-hoc analytical query library
│   └── SalesAnalytics.sql              12+ BI queries with window functions
│
├── Scripts/
│   └── Bootstrap/                      Deployment automation
│       ├── 00_MasterDeploy.sql         Deployment guide and orchestration
│       ├── 01_CreateOLTPDatabase.sql   Create OLTP schema from scratch
│       ├── 02_CreateDWDatabase.sql     Create DW database + staging schema
│       ├── 03_SeedOLTPData.sql         Insert Northwind sample data
│       ├── 04_Bootstrap_DW.sql         Create all DW tables and ETL procs
│       ├── 05_SeedDimDate.sql          Populate DimDate + Unknown members
│       ├── 06_RunFullLoad.sql          Execute first full ETL pipeline
│       └── 07_ValidateDeployment.sql   Row counts + integrity checks
│
├── Docs/
│   ├── ETL_Architecture.md             ETL pipeline design, monitoring queries
│   └── DataDictionary.md               Column-level data dictionary
│
└── README.md                           This file
```

---

## 1. OLTP Database — NorthWindOLTP

### Model Summary

A fully normalized (3NF) transactional model with 13 tables:

| Table | Purpose |
|---|---|
| Categories | Product category master |
| Customers | Customer master with 5-char business key |
| Employees | Employee master with self-referencing manager FK |
| Shippers | Shipping carrier master |
| Suppliers | Product supplier master |
| Products | Product catalog with category + supplier FKs |
| Orders | Order header with date, customer, employee, shipper |
| OrderDetails | Order line items (grain: OrderID + ProductID) |
| Region | Geographic region reference |
| Territories | Territory master (FK → Region) |
| EmployeeTerritories | Employee-to-territory assignment |
| CustomerDemographics | Customer segmentation categories |
| CustomerCustomerDemo | Customer-to-segment assignment |

### Design Standards Applied

- **Primary keys** on all tables
- **Foreign keys** with referential integrity
- **CHECK constraints**: date ordering, non-negative prices, valid discount range
- **UNIQUE constraints**: CategoryName
- **Audit columns**: `CreatedDate`, `UpdatedDate`, `rowversion` on all core tables
- **Operational indexes**: covering indexes for common join patterns
- **Business rules encoded in constraints** (ShippedDate ≥ OrderDate, etc.)

---

## 2. Data Warehouse — NorthWindDW

### Star Schema Design

```
                    DimDate
                   (DateKey)
                      │
DimCustomer ─── FactOrders ─── DimEmployee
(CustomerKey)  (OrderKey)     (EmployeeKey)
                    │
          DimProduct    DimShipper
          (ProductKey) (ShipperKey)
```

**Fact grain**: one row per `OrderID + ProductID` (order line level)

**Key measures** in FactOrders:
- `Quantity` — units ordered
- `UnitPrice` — selling price at order time
- `Discount` — discount fraction
- `Freight` — shipping cost
- `LineTotal` (computed) — `Quantity × UnitPrice × (1 − Discount)`
- `OrderTotal` — pre-aggregated sum for the order header

### Dimensional Design Decisions

| Dimension | Type | Notes |
|---|---|---|
| DimCustomer | SCD Type 1 | `IsCurrent`, `ValidFrom`, `ValidTo` columns present for optional SCD Type 2 upgrade |
| DimEmployee | SCD Type 1 | Denormalized manager name, territory, region |
| DimProduct | SCD Type 1 | Denormalized category and supplier names |
| DimShipper | SCD Type 1 | Simple carrier reference |
| DimDate | Static | Pre-seeded calendar 1996–1999 + DateKey=0 Unknown |

**Unknown members** (surrogate key = −1) seeded for all dimensions. DateKey = 0 for NULL dates. These allow FactOrders inserts to never fail due to unresolved FK.

---

## 3. Staging Layer

The `staging` schema acts as an isolated extraction buffer:

| Staging Table | Source OLTP Tables |
|---|---|
| staging.Customer | Customers + CustomerDemographics |
| staging.Employee | Employees + Territories + Region |
| staging.Product | Products + Categories + Suppliers |
| staging.Shipper | Shippers |
| staging.Order | Orders + OrderDetails (joined at line grain) |

**Benefits**: isolates extraction failures, enables troubleshooting, supports replay.

---

## 4. ETL Architecture

### Pipeline Overview

```
Extract ──► Validate ──► Merge Dimensions ──► Load Fact ──► Update Watermarks
```

### ETL Procedures

| Procedure | Purpose |
|---|---|
| `DW_LoadStagingCustomers` | Extract customers (full or incremental by rowversion) |
| `DW_LoadStagingEmployees` | Extract employees + denormalize territory/region |
| `DW_LoadStagingProducts` | Extract products + denormalize category/supplier |
| `DW_LoadStagingShippers` | Extract shippers |
| `DW_LoadStagingOrders` | Extract order lines (OrderHeader JOIN OrderDetails) |
| `DW_ValidateStagingData` | 8 data quality checks (4 errors, 4 warnings) |
| `DW_MergeDimCustomer` | Upsert customers into DimCustomer |
| `DW_MergeDimEmployee` | Upsert employees into DimEmployee |
| `DW_MergeDimProduct` | Upsert products into DimProduct |
| `DW_MergeDimShipper` | Upsert shippers into DimShipper |
| `DW_MergeFactOrders` | Append new order lines into FactOrders |
| `DW_RunFullLoad` | Orchestrates complete full reload |
| `DW_RunIncrementalLoad` | Orchestrates incremental load by watermark |
| `GetLastPackageRowVersion` | Helper: read watermark from PackageConfig |
| `UpdateLastPackageRowVersion` | Helper: write watermark to PackageConfig |

### ETL Quality Standards

All ETL procedures implement:
- `SET NOCOUNT ON` + `TRY/CATCH/THROW`
- Explicit `BEGIN TRANSACTION` / `ROLLBACK`
- Structured logging to `ETLExecutionLog` (success path) and `ETLErrorLog` (error path)
- `BatchID` tracking across all steps of a run
- Row count metrics (`RowsExtracted`, `RowsInserted`, `RowsUpdated`)

---

## 5. Incremental Load Strategy

Uses **SQL Server `rowversion`** as a monotonic change-detection watermark:

1. OLTP tables each carry a `rowversion` column (auto-updated by SQL Server on every row change)
2. After each successful load, the max rowversion processed is stored in `PackageConfig`
3. Next incremental run extracts only rows where `rowversion > lastProcessed`
4. Shippers and Orders are always full-reloaded (small tables or append-only pattern)

---

## 6. Data Quality Validation

`DW_ValidateStagingData` runs before any dimension or fact merge:

| Check | Type | Action |
|---|---|---|
| NULL/empty CustomerID or CompanyName | Error | Halt ETL |
| Duplicate CustomerID in staging | Error | Halt ETL |
| NULL mandatory Employee fields | Error | Halt ETL |
| Invalid UnitPrice, Quantity, Discount | Error | Halt ETL |
| Orders referencing unknown CustomerIDs | Warning | Log only |
| Future OrderDate | Warning | Log only |
| RequiredDate before OrderDate | Warning | Log only |
| NULL CategoryName or SupplierCompanyName | Warning | Log only |

---

## 7. Analytics Layer

### Analytical Views (NorthWindDW)

| View | Description |
|---|---|
| `vw_SalesByDate` | Revenue, order count, units by calendar date |
| `vw_SalesByCustomer` | Revenue, order count, first/last order by customer |
| `vw_SalesByEmployee` | Sales rep performance metrics |
| `vw_SalesByProduct` | Product revenue, units, discount impact |
| `vw_SalesByShipper` | Shipper freight and order volume |
| `vw_MonthlyRevenueTrend` | Monthly revenue with quarter context |
| `vw_Top10Products` | Top 10 products by total revenue |
| `vw_KPISummary` | Single-row KPI snapshot (total revenue, orders, etc.) |

### Ad-Hoc Query Library (`Analytics/SalesAnalytics.sql`)

12 queries covering:
- Revenue by Year/Quarter
- Monthly YoY Growth (LAG window function)
- Top 10 Customers
- Sales by Geography
- Employee performance ranking (RANK)
- Product category revenue share (SUM OVER)
- Discount band impact analysis
- Average Order Value by country
- Shipper freight analysis
- Rolling 3-month trend
- Customer retention cohort (first order year)
- Late shipment analysis

---

## 8. Deployment Guide

### Prerequisites

- SQL Server 2017 or later
- SQL Server Management Studio (SSMS) or Azure Data Studio
- Optional: Visual Studio with SQL Server Data Tools (SSDT) for DACPAC deployment

### Option A — SSDT (Recommended)

1. Open `NorthWind.slnx` in Visual Studio
2. Build and publish `NorthWindOLTP` (NorthWind.sqlproj) to your SQL Server
3. Build and publish `NorthWindDW` project to your SQL Server
4. Run `Scripts/Bootstrap/03_SeedOLTPData.sql` to populate sample data
5. Run `Scripts/Bootstrap/06_RunFullLoad.sql` to execute the first ETL run
6. Run `Scripts/Bootstrap/07_ValidateDeployment.sql` to verify

### Option B — Scripts Only

Execute in order in SSMS against your SQL Server instance:

```
01_CreateOLTPDatabase.sql   → creates NorthWindOLTP tables
02_CreateDWDatabase.sql     → creates NorthWindDW + staging schema
03_SeedOLTPData.sql         → inserts sample data
04_Bootstrap_DW.sql         → creates DW tables, FKs, staging tables
05_SeedDimDate.sql          → populates DimDate + Unknown members
06_RunFullLoad.sql          → runs first full ETL pipeline
07_ValidateDeployment.sql   → validates row counts and KPIs
```

All scripts are **idempotent** — safe to re-run.

---

## 9. Quick Start Queries

```sql
-- KPI snapshot
USE NorthWindDW;
SELECT * FROM [dbo].[vw_KPISummary];

-- Revenue by month
SELECT * FROM [dbo].[vw_MonthlyRevenueTrend]
ORDER BY [Year], [Month];

-- Top customers
SELECT * FROM [dbo].[vw_SalesByCustomer]
ORDER BY [TotalRevenue] DESC;

-- Check ETL status
SELECT TOP 10 * FROM [dbo].[ETLExecutionLog]
ORDER BY [StartTime] DESC;

-- Run incremental load
EXEC [dbo].[DW_RunIncrementalLoad];
```

---

## 10. Design Decisions & Assumptions

| Decision | Rationale |
|---|---|
| rowversion watermark (not ModifiedDate) | Auto-maintained by SQL Server, immune to application-layer gaps |
| staging TRUNCATE per load | Clean room pattern — no stale data in staging |
| Unknown members (key = −1) | FK integrity without blocking fact inserts from unresolved lookups |
| SCD Type 1 for all dimensions | Appropriate for Northwind analytical scope; Type 2 upgrade path is prepared in DimCustomer |
| Computed LineTotal in FactOrders | Removes ETL calculation risk; always formula-consistent |
| Columnstore index on FactOrders | Accelerates analytical aggregation workloads |
| Modular staging procedures | Each entity independently extractable and testable |
| Separate DimDate (pre-seeded) | Standard DW pattern — no ETL dependency, supports arbitrary date attributes |

---

## 11. Naming Conventions

| Object Type | Convention | Example |
|---|---|---|
| DW Dimension | `Dim` prefix, PascalCase | `DimCustomer` |
| DW Fact | `Fact` prefix, PascalCase | `FactOrders` |
| Staging | `staging.` schema, singular | `staging.Customer` |
| OLTP Tables | PascalCase, plural | `OrderDetails` |
| Primary Keys | `PK_<Table>` | `PK_FactOrders` |
| Foreign Keys | `FK_<Table>_<Ref>` | `FK_FactOrders_DimCustomer` |
| Indexes (DW) | `IX_<Table>_<Column>` | `IX_DimCustomer_CustomerID` |
| ETL Procedures | `DW_<Action><Object>` | `DW_MergeDimCustomer` |
| OLTP Procedures | `usp_<Verb><Object>` | `usp_GetCustomerOrders` |
| Analytical Views | `vw_<Description>` | `vw_SalesByDate` |

---

## Technology Stack

| Component | Technology |
|---|---|
| Database engine | SQL Server 2017+ |
| Schema management | SSDT / DACPAC |
| ETL | T-SQL stored procedures |
| Analytics | T-SQL views + ad-hoc queries |
| Change detection | SQL Server `rowversion` |
| Performance | Columnstore index on FactOrders |

---

## Documentation

- [`Docs/ETL_Architecture.md`](Docs/ETL_Architecture.md) — ETL pipeline design, monitoring queries, error handling patterns
- [`Docs/DataDictionary.md`](Docs/DataDictionary.md) — Column-level data dictionary for all OLTP and DW tables


## Descripción del proyecto

Este repositorio contiene el desarrollo de una solución de bases de datos en **SQL Server** basada en la base de datos **Northwind**, con enfoque en dos componentes principales:

1. **Modelo transaccional OLTP**, diseñado y organizado bajo principios de normalización.
2. **Modelo analítico Data Warehouse (DW)**, orientado a consulta y análisis de información mediante un esquema dimensional.

Además, la solución fue empaquetada como **proyecto de base de datos tipo DACPAC**, permitiendo su compilación, despliegue y versionamiento desde Visual Studio / SQL Server Data Tools (SSDT).

## Objetivo académico

Desarrollar un esquema de base de datos transaccional y su correspondiente modelo analítico aplicando buenas prácticas de:

- modelado de datos
- normalización
- integridad referencial
- diseño dimensional
- organización de scripts SQL
- empaquetado mediante proyecto DACPAC
- documentación y publicación en GitHub

---

## Dominio de negocio

El dominio de negocio seleccionado es **ventas y distribución comercial**, usando como base el caso clásico de **Northwind**.

La solución modela procesos relacionados con:

- gestión de clientes
- empleados de ventas
- productos y categorías
- proveedores
- órdenes de venta
- detalle de órdenes
- transportistas
- análisis histórico de ventas

---

## Alcance del sistema

El proyecto cubre dos niveles de modelado:

### 1. Sistema OLTP
Diseñado para soportar operaciones transaccionales del negocio, tales como:

- registrar clientes
- gestionar productos y proveedores
- almacenar órdenes
- registrar detalle de productos vendidos
- relacionar empleados con territorios
- mantener consistencia entre entidades mediante claves primarias y foráneas

### 2. Sistema Data Warehouse
Diseñado para soportar análisis y consulta histórica, permitiendo:

- analizar ventas por fecha
- analizar ventas por cliente
- analizar ventas por empleado
- analizar ventas por producto
- analizar ventas por transportista
- calcular métricas agregadas para soporte a decisiones

---

## Estructura del repositorio

```text
.
├── Modelo ER/
│   ├── Modelo ER.pdf
│   └── Proyecto en SAP PowerDesigner/
├── NorthWind/
│   ├── NorthWind.sqlproj
│   └── dbo/
│       ├── Tables/
│       ├── Views/
│       └── Stored Procedures/
├── NortgWindDW/
│   ├── Schema/
│   │   ├── Tables/
│   │   └── Programmability/
│   └── Scripts/
└── NorthWind.slnx
```

---

## Modelo OLTP

El modelo OLTP fue implementado en el proyecto:

- `NorthWind/NorthWind.sqlproj`

### Principales entidades

Las tablas principales identificadas en el modelo transaccional son:

- `Categories`
- `Customers`
- `Employees`
- `Shippers`
- `Suppliers`
- `Products`
- `Orders`
- `OrderDetails`
- `Region`
- `Territories`
- `EmployeeTerritories`
- `CustomerDemographics`
- `CustomerCustomerDemo`

### Relaciones principales

Algunas relaciones importantes del modelo son:

- **Products** se relaciona con **Categories** y **Suppliers**
- **Orders** se relaciona con **Customers**, **Employees** y **Shippers**
- **OrderDetails** se relaciona con **Orders** y **Products**
- **EmployeeTerritories** relaciona **Employees** con **Territories**
- **Territories** se relaciona con **Region**
- **CustomerCustomerDemo** relaciona **Customers** con **CustomerDemographics**

### Normalización

El modelo OLTP sigue principios de normalización hasta al menos **Tercera Forma Normal (3FN)**, buscando:

- eliminación de redundancias innecesarias
- separación de entidades maestras y transaccionales
- uso correcto de claves primarias
- uso de claves foráneas para mantener integridad referencial
- separación entre encabezado de pedido (`Orders`) y detalle (`OrderDetails`)

### Reglas de negocio básicas

- un cliente puede realizar múltiples órdenes
- una orden debe pertenecer a un cliente
- una orden puede contener múltiples productos
- un producto puede aparecer en múltiples órdenes
- un empleado puede gestionar múltiples órdenes
- un producto pertenece a una categoría y puede tener un proveedor
- una orden puede ser entregada por un transportista
- los territorios se asignan a empleados mediante una tabla intermedia

---

## Modelo Data Warehouse

El modelo analítico fue implementado en:

- `NortgWindDW/`

### Enfoque dimensional

Se diseñó un **modelo estrella**, donde la tabla de hechos central almacena medidas del proceso de ventas y las dimensiones aportan contexto descriptivo para el análisis.

### Tabla de hechos

- `FactOrders`

### Dimensiones

- `DimCustomer`
- `DimDate`
- `DimEmployee`
- `DimProduct`
- `DimShipper`

### Métricas principales

El modelo permite analizar métricas como:

- total de ventas
- cantidad vendida
- precio unitario
- descuento aplicado
- importe por línea de pedido
- comportamiento histórico de pedidos

### Beneficios del modelo DW

A diferencia del OLTP, el Data Warehouse está orientado a:

- consultas analíticas
- agregaciones
- reportes históricos
- comparación por dimensiones de negocio
- soporte a decisiones

El DW **no replica el OLTP directamente**, sino que reorganiza la información para facilitar el análisis.

---

## Procesos ETL y carga del DW

Dentro del proyecto DW se incluyen procedimientos y scripts para poblar el modelo dimensional.

### Procedimientos almacenados ETL

Ubicados en:

- `NortgWindDW/Schema/Programmability/Stored Procedures/`

Procedimientos identificados:

- `DW_MergeDimCustomer.sql`
- `DW_MergeDimEmployee.sql`
- `DW_MergeDimProduct.sql`
- `DW_MergeDimShipper.sql`
- `DW_MergeFactOrders.sql`
- `GetLastPackageRowVersion.sql`
- `UpdateLastPackageRowVersion.sql`

Estos procedimientos permiten una estrategia de carga basada en inserciones/actualizaciones controladas para dimensiones y hechos.

### Scripts de datos y post-deployment

Ubicados en:

- `NortgWindDW/Scripts/`

Archivos principales:

- `PackageConfig.data.sql`
- `DimDate.data.sql`
- `PatchDimDate.data.sql`
- `DimCustomer.data.sql`
- `DimEmployee.data.sql`
- `DimProduct.data.sql`
- `DimShipper.data.sql`
- `Script.PostDeployment.sql`

El script `Script.PostDeployment.sql` organiza la carga inicial del Data Warehouse en el siguiente orden:

1. configuración ETL
2. carga de la dimensión fecha
3. parche de fecha cero para integridad referencial
4. carga de dimensiones de cliente
5. carga de dimensiones de empleado
6. carga de dimensiones de producto
7. carga de dimensiones de transportista

---

## Diagrama Entidad-Relación

El repositorio incluye el diagrama ER en:

- `Modelo ER/Modelo ER.pdf`

Y el proyecto fuente de modelado en:

- `Modelo ER/Proyecto en SAP PowerDesigner/`

> Se recomienda abrir el PDF para visualizar el modelo conceptual/lógico del sistema y validar las relaciones entre entidades.

---

## Proyecto DACPAC

La solución fue estructurada como proyecto de base de datos para SSDT / Visual Studio.

### Proyecto identificado

- `NorthWind/NorthWind.sqlproj`

Este proyecto permite:

- versionar objetos de base de datos
- compilar el esquema
- generar scripts de despliegue
- producir un archivo `.dacpac`

### Requisitos sugeridos

- Visual Studio con **SQL Server Data Tools (SSDT)**
- SQL Server
- SQL Server Management Studio (SSMS) opcional

---

## Instrucciones para desplegar

## 1. Clonar el repositorio

```bash
git clone https://github.com/Valvillavel/NorthWind.git
cd NorthWind
```

## 2. Abrir la solución

Abrir el archivo:

- `NorthWind.slnx`

Desde Visual Studio con soporte para proyectos SQL.

## 3. Compilar el proyecto OLTP

Abrir el proyecto:

- `NorthWind/NorthWind.sqlproj`

Compilar para validar que el esquema SQL se genera correctamente.

## 4. Publicar o desplegar el esquema OLTP

Opciones:

- publicar directamente desde Visual Studio a una instancia SQL Server
- generar script de despliegue
- generar archivo `.dacpac`

## 5. Desplegar el Data Warehouse

Publicar también el proyecto o scripts asociados al DW y ejecutar los scripts de carga ubicados en:

- `NortgWindDW/Scripts/`

Especialmente:

- `Script.PostDeployment.sql`

## 6. Validar la carga

Comprobar:

- existencia de tablas del OLTP
- existencia de dimensiones y tabla de hechos
- integridad referencial
- carga de registros en dimensiones principales
- consistencia entre el modelo transaccional y el analítico

---

## Validaciones realizadas en el proyecto

Este proyecto contempla los criterios solicitados en la actividad:

- modelo OLTP normalizado
- implementación física en SQL Server
- modelo dimensional para Data Warehouse
- definición de hechos y dimensiones
- scripts SQL organizados por objeto
- uso de claves primarias y foráneas
- procedimientos de carga ETL
- proyecto tipo DACPAC
- documentación y publicación en GitHub

---

## Tecnologías utilizadas

- **SQL Server**
- **T-SQL**
- **Visual Studio / SSDT**
- **DACPAC**
- **GitHub**
- **SAP PowerDesigner** (para el modelado ER)

---

## Autores

Proyecto desarrollado por **Garcia Andrade Alex Rafael**, **Verastegui Orozco Raisa** y **Villarroel Veliz Valeria** como parte de la actividad académica de diseño de base de datos **OLTP y Data Warehouse en SQL Server** usando **Northwind** como caso de estudio.

## Repositorio

- GitHub: https://github.com/Valvillavel/NorthWind