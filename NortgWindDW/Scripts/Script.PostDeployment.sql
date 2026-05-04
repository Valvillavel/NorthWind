/*
================================================================================
Script Post-Deployment - Northwind Data Warehouse
================================================================================
Este script se ejecuta DESPUÉS de crear las tablas y procedimientos.
Orden de ejecución:
1. PackageConfig.data.sql  - Configuración ETL
2. DimDate.data.sql        - Poblar calendario
3. PatchDimDate.data.sql   - Fecha cero para integridad referencial
4. DimCustomer.data.sql    - Poblar clientes
5. DimEmployee.data.sql    - Poblar empleados
6. DimProduct.data.sql     - Poblar productos
7. DimShipper.data.sql     - Poblar transportistas
8. FactOrders.data.sql     - Poblar hechos (opcional, normalmente se hace vía ETL)
================================================================================
*/

PRINT '================================================================================'
PRINT 'Iniciando Post-Deployment para Northwind Data Warehouse'
PRINT '================================================================================'
GO

-- 1. Configuración de paquetes ETL
PRINT '1. Cargando PackageConfig...'
:r .\PackageConfig.data.sql

-- 2. Poblar dimensión fecha (calendario 1996-1999)
PRINT '2. Poblando DimDate...'
:r .\DimDate.data.sql

-- 3. Parche para fecha cero (para integridad referencial)
PRINT '3. Aplicando patch a DimDate...'
:r .\PatchDimDate.data.sql

-- 4. Poblar dimensiones
PRINT '4. Cargando DimCustomer...'
:r .\DimCustomer.data.sql

PRINT '5. Cargando DimEmployee...'
:r .\DimEmployee.data.sql

PRINT '6. Cargando DimProduct...'
:r .\DimProduct.data.sql

PRINT '7. Cargando DimShipper...'
:r .\DimShipper.data.sql

-- 8. (Opcional) Poblar hechos - Comentar si se usa ETL incremental
-- PRINT '8. Cargando FactOrders...'
-- :r .\FactOrders.data.sql

PRINT '================================================================================'
PRINT 'Post-Deployment completado exitosamente'
PRINT '================================================================================'
GO