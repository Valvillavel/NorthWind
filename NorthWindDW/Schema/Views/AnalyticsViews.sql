-- ============================================================
-- Analytics View: Sales by Date
-- Grain: one row per calendar date with aggregated sales
-- ============================================================
CREATE VIEW [dbo].[vw_SalesByDate]
AS
SELECT
    dd.[FullDate]                                   AS [OrderDate],
    dd.[Year]                                       AS [Year],
    dd.[Quarter]                                    AS [Quarter],
    dd.[QuarterName]                                AS [QuarterName],
    dd.[Month]                                      AS [Month],
    dd.[MonthName]                                  AS [MonthName],
    COUNT(DISTINCT fo.[OrderID])                    AS [OrderCount],
    SUM(fo.[Quantity])                              AS [TotalUnits],
    SUM(fo.[LineTotal])                             AS [TotalRevenue],
    AVG(fo.[LineTotal])                             AS [AvgLineRevenue],
    SUM(fo.[Freight])                               AS [TotalFreight],
    SUM(fo.[Discount] * fo.[UnitPrice] * fo.[Quantity]) AS [TotalDiscountAmount]
FROM [dbo].[FactOrders]  fo
INNER JOIN [dbo].[DimDate] dd ON fo.[DateKeyOrder] = dd.[DateKey]
GROUP BY
    dd.[FullDate], dd.[Year], dd.[Quarter], dd.[QuarterName],
    dd.[Month], dd.[MonthName];
GO


-- ============================================================
-- Analytics View: Sales by Customer
-- ============================================================
CREATE VIEW [dbo].[vw_SalesByCustomer]
AS
SELECT
    dc.[CustomerID],
    dc.[CompanyName],
    dc.[City],
    dc.[Country],
    COUNT(DISTINCT fo.[OrderID])   AS [OrderCount],
    SUM(fo.[Quantity])             AS [TotalUnits],
    SUM(fo.[LineTotal])            AS [TotalRevenue],
    AVG(fo.[LineTotal])            AS [AvgOrderValue],
    MAX(dd.[FullDate])             AS [LastOrderDate],
    MIN(dd.[FullDate])             AS [FirstOrderDate]
FROM [dbo].[FactOrders]   fo
INNER JOIN [dbo].[DimCustomer] dc ON fo.[CustomerKey]  = dc.[CustomerKey]
INNER JOIN [dbo].[DimDate]     dd ON fo.[DateKeyOrder] = dd.[DateKey]
WHERE dc.[IsCurrent] = 1
GROUP BY
    dc.[CustomerID], dc.[CompanyName], dc.[City], dc.[Country];
GO


-- ============================================================
-- Analytics View: Sales by Employee
-- ============================================================
CREATE VIEW [dbo].[vw_SalesByEmployee]
AS
SELECT
    de.[EmployeeID],
    de.[FullName]                  AS [EmployeeName],
    de.[Title],
    de.[Country],
    COUNT(DISTINCT fo.[OrderID])   AS [OrderCount],
    SUM(fo.[Quantity])             AS [TotalUnits],
    SUM(fo.[LineTotal])            AS [TotalRevenue],
    AVG(fo.[LineTotal])            AS [AvgOrderValue]
FROM [dbo].[FactOrders]   fo
INNER JOIN [dbo].[DimEmployee] de ON fo.[EmployeeKey]  = de.[EmployeeKey]
GROUP BY
    de.[EmployeeID], de.[FullName], de.[Title], de.[Country];
GO


-- ============================================================
-- Analytics View: Sales by Product
-- ============================================================
CREATE VIEW [dbo].[vw_SalesByProduct]
AS
SELECT
    dp.[ProductID],
    dp.[ProductName],
    dp.[CategoryName],
    dp.[SupplierCompanyName],
    dp.[Discontinued],
    COUNT(DISTINCT fo.[OrderID])   AS [OrderCount],
    SUM(fo.[Quantity])             AS [TotalUnits],
    SUM(fo.[LineTotal])            AS [TotalRevenue],
    AVG(fo.[UnitPrice])            AS [AvgUnitPrice],
    SUM(fo.[Discount] * fo.[UnitPrice] * fo.[Quantity]) AS [TotalDiscountAmount]
FROM [dbo].[FactOrders]  fo
INNER JOIN [dbo].[DimProduct] dp ON fo.[ProductKey] = dp.[ProductKey]
GROUP BY
    dp.[ProductID], dp.[ProductName], dp.[CategoryName],
    dp.[SupplierCompanyName], dp.[Discontinued];
GO


-- ============================================================
-- Analytics View: Sales by Shipper
-- ============================================================
CREATE VIEW [dbo].[vw_SalesByShipper]
AS
SELECT
    ds.[ShipperID],
    ds.[CompanyName]               AS [ShipperName],
    COUNT(DISTINCT fo.[OrderID])   AS [OrderCount],
    SUM(fo.[Quantity])             AS [TotalUnits],
    SUM(fo.[LineTotal])            AS [TotalRevenue],
    SUM(fo.[Freight])              AS [TotalFreight],
    AVG(fo.[Freight])              AS [AvgFreight]
FROM [dbo].[FactOrders]  fo
INNER JOIN [dbo].[DimShipper] ds ON fo.[ShipperKey] = ds.[ShipperKey]
GROUP BY
    ds.[ShipperID], ds.[CompanyName];
GO


-- ============================================================
-- Analytics View: Monthly Revenue Trend
-- ============================================================
CREATE VIEW [dbo].[vw_MonthlyRevenueTrend]
AS
SELECT
    dd.[Year],
    dd.[Month],
    dd.[MonthName],
    dd.[Quarter],
    SUM(fo.[LineTotal])            AS [MonthlyRevenue],
    COUNT(DISTINCT fo.[OrderID])   AS [OrderCount],
    SUM(fo.[Quantity])             AS [TotalUnits],
    AVG(fo.[LineTotal])            AS [AvgTicket]
FROM [dbo].[FactOrders]  fo
INNER JOIN [dbo].[DimDate] dd ON fo.[DateKeyOrder] = dd.[DateKey]
WHERE dd.[DateKey] > 0
GROUP BY
    dd.[Year], dd.[Month], dd.[MonthName], dd.[Quarter];
GO


-- ============================================================
-- Analytics View: Top 10 Products by Revenue
-- ============================================================
CREATE VIEW [dbo].[vw_Top10Products]
AS
SELECT TOP 10
    dp.[ProductID],
    dp.[ProductName],
    dp.[CategoryName],
    SUM(fo.[Quantity])           AS [TotalUnits],
    SUM(fo.[LineTotal])          AS [TotalRevenue],
    COUNT(DISTINCT fo.[OrderID]) AS [OrderCount]
FROM [dbo].[FactOrders]  fo
INNER JOIN [dbo].[DimProduct] dp ON fo.[ProductKey] = dp.[ProductKey]
GROUP BY
    dp.[ProductID], dp.[ProductName], dp.[CategoryName]
ORDER BY
    SUM(fo.[LineTotal]) DESC;
GO


-- ============================================================
-- Analytics View: KPI Summary
-- ============================================================
CREATE VIEW [dbo].[vw_KPISummary]
AS
SELECT
    COUNT(DISTINCT fo.[OrderID])                        AS [TotalOrders],
    COUNT(DISTINCT fo.[CustomerKey])                    AS [TotalCustomers],
    COUNT(DISTINCT fo.[ProductKey])                     AS [TotalProducts],
    SUM(fo.[LineTotal])                                 AS [GrossRevenue],
    SUM(fo.[Freight])                                   AS [TotalFreight],
    SUM(fo.[Discount] * fo.[UnitPrice] * fo.[Quantity]) AS [TotalDiscountGiven],
    AVG(fo.[LineTotal])                                 AS [AvgLineValue],
    SUM(fo.[Quantity])                                  AS [TotalUnitsSold],
    MIN(dd.[FullDate])                                  AS [EarliestOrder],
    MAX(dd.[FullDate])                                  AS [LatestOrder]
FROM [dbo].[FactOrders]  fo
INNER JOIN [dbo].[DimDate] dd ON fo.[DateKeyOrder] = dd.[DateKey]
WHERE dd.[DateKey] > 0;
GO
