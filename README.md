# NorthWind - Diseño de Base de Datos OLTP y Data Warehouse en SQL Server

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

## Recomendaciones de mejora

Como mejoras futuras del proyecto, se podrían incorporar:

- script explícito de carga para `FactOrders`
- documentación de métricas con ejemplos de consultas analíticas
- evidencias de compilación del `.dacpac`
- capturas del modelo ER dentro del README
- sección de consultas ejemplo para OLTP y DW
- automatización del despliegue mediante pipeline

---

## Autor

Proyecto desarrollado por **Valvillavel** como parte de la actividad académica de diseño de base de datos **OLTP y Data Warehouse en SQL Server** usando **Northwind** como caso de estudio.

## Repositorio

- GitHub: https://github.com/Valvillavel/NorthWind