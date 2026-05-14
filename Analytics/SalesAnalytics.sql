

USE [NorthWindDW];
GO

-- ============================================================
-- Q01 — Total Revenue and Orders by Year and Quarter
-- ============================================================
SELECT
    dd.[Year],
    dd.[QuarterName],
    COUNT(DISTINCT fo.[OrderID])   AS [Orders],
    SUM(fo.[Quantity])             AS [UnitsSold],
    SUM(fo.[LineTotal])            AS [Revenue],
    AVG(fo.[LineTotal])            AS [AvgLineValue]
FROM [dbo].[FactOrders] fo
INNER JOIN [dbo].[DimDate] dd ON fo.[DateKeyOrder] = dd.[DateKey]
WHERE dd.[DateKey] > 0
GROUP BY dd.[Year], dd.[Quarter], dd.[QuarterName]
ORDER BY dd.[Year], dd.[Quarter];
GO

-- ============================================================
-- Q02 — Monthly Revenue Trend with YoY Growth
-- ============================================================
WITH Monthly AS (
    SELECT
        dd.[Year],
        dd.[Month],
        dd.[MonthName],
        SUM(fo.[LineTotal]) AS [Revenue]
    FROM [dbo].[FactOrders] fo
    INNER JOIN [dbo].[DimDate] dd ON fo.[DateKeyOrder] = dd.[DateKey]
    WHERE dd.[DateKey] > 0
    GROUP BY dd.[Year], dd.[Month], dd.[MonthName]
)
SELECT
    m.[Year],
    m.[Month],
    m.[MonthName],
    m.[Revenue],
    LAG(m.[Revenue]) OVER (PARTITION BY m.[Month] ORDER BY m.[Year]) AS [PriorYearRevenue],
    CASE
        WHEN LAG(m.[Revenue]) OVER (PARTITION BY m.[Month] ORDER BY m.[Year]) IS NULL THEN NULL
        ELSE ROUND(
            (m.[Revenue] - LAG(m.[Revenue]) OVER (PARTITION BY m.[Month] ORDER BY m.[Year]))
            / LAG(m.[Revenue]) OVER (PARTITION BY m.[Month] ORDER BY m.[Year]) * 100, 2)
    END AS [YoY_Growth_Pct]
FROM Monthly m
ORDER BY m.[Year], m.[Month];
GO

-- ============================================================
-- Q03 — Top 10 Customers by Total Revenue
-- ============================================================
SELECT TOP 10
    dc.[CustomerID],
    dc.[CompanyName],
    dc.[Country],
    COUNT(DISTINCT fo.[OrderID])  AS [Orders],
    SUM(fo.[LineTotal])           AS [TotalRevenue],
    AVG(fo.[LineTotal])           AS [AvgOrderValue]
FROM [dbo].[FactOrders]   fo
INNER JOIN [dbo].[DimCustomer] dc ON fo.[CustomerKey] = dc.[CustomerKey]
WHERE dc.[IsCurrent] = 1
GROUP BY dc.[CustomerID], dc.[CompanyName], dc.[Country]
ORDER BY SUM(fo.[LineTotal]) DESC;
GO

-- ============================================================
-- Q04 — Sales by Country (Customer Geography)
-- ============================================================
SELECT
    dc.[Country],
    COUNT(DISTINCT dc.[CustomerID]) AS [CustomerCount],
    COUNT(DISTINCT fo.[OrderID])    AS [OrderCount],
    SUM(fo.[LineTotal])             AS [TotalRevenue],
    AVG(fo.[LineTotal])             AS [AvgOrderValue]
FROM [dbo].[FactOrders]   fo
INNER JOIN [dbo].[DimCustomer] dc ON fo.[CustomerKey] = dc.[CustomerKey]
WHERE dc.[IsCurrent] = 1
GROUP BY dc.[Country]
ORDER BY SUM(fo.[LineTotal]) DESC;
GO

-- ============================================================
-- Q05 — Employee Performance Ranking
-- ============================================================
SELECT
    de.[FullName]                  AS [Employee],
    de.[Title],
    COUNT(DISTINCT fo.[OrderID])   AS [OrderCount],
    SUM(fo.[LineTotal])            AS [TotalRevenue],
    RANK() OVER (ORDER BY SUM(fo.[LineTotal]) DESC) AS [RevenueRank]
FROM [dbo].[FactOrders]   fo
INNER JOIN [dbo].[DimEmployee] de ON fo.[EmployeeKey] = de.[EmployeeKey]
GROUP BY de.[FullName], de.[Title]
ORDER BY [RevenueRank];
GO

-- ============================================================
-- Q06 — Product Category Revenue Breakdown
-- ============================================================
SELECT
    dp.[CategoryName],
    COUNT(DISTINCT dp.[ProductID]) AS [ProductCount],
    SUM(fo.[Quantity])             AS [UnitsSold],
    SUM(fo.[LineTotal])            AS [TotalRevenue],
    ROUND(
        SUM(fo.[LineTotal]) / SUM(SUM(fo.[LineTotal])) OVER () * 100, 2
    )                              AS [RevenuePct]
FROM [dbo].[FactOrders]  fo
INNER JOIN [dbo].[DimProduct] dp ON fo.[ProductKey] = dp.[ProductKey]
GROUP BY dp.[CategoryName]
ORDER BY SUM(fo.[LineTotal]) DESC;
GO

-- ============================================================
-- Q07 — Top 10 Products by Revenue
-- ============================================================
SELECT TOP 10
    dp.[ProductName],
    dp.[CategoryName],
    SUM(fo.[Quantity])           AS [UnitsSold],
    SUM(fo.[LineTotal])          AS [TotalRevenue],
    COUNT(DISTINCT fo.[OrderID]) AS [OrderCount],
    AVG(fo.[UnitPrice])          AS [AvgUnitPrice]
FROM [dbo].[FactOrders]  fo
INNER JOIN [dbo].[DimProduct] dp ON fo.[ProductKey] = dp.[ProductKey]
GROUP BY dp.[ProductName], dp.[CategoryName]
ORDER BY SUM(fo.[LineTotal]) DESC;
GO

-- ============================================================
-- Q08 — Discount Impact Analysis
-- ============================================================
SELECT
    CASE
        WHEN fo.[Discount] = 0             THEN 'No Discount'
        WHEN fo.[Discount] BETWEEN 0.01 AND 0.05 THEN '1%-5%'
        WHEN fo.[Discount] BETWEEN 0.06 AND 0.10 THEN '6%-10%'
        WHEN fo.[Discount] BETWEEN 0.11 AND 0.20 THEN '11%-20%'
        ELSE '> 20%'
    END                                    AS [DiscountBand],
    COUNT(*)                               AS [LineCount],
    COUNT(DISTINCT fo.[OrderID])           AS [OrderCount],
    SUM(fo.[LineTotal])                    AS [RevenueAfterDiscount],
    SUM(fo.[Discount] * fo.[UnitPrice] * fo.[Quantity]) AS [DiscountAmount]
FROM [dbo].[FactOrders] fo
GROUP BY
    CASE
        WHEN fo.[Discount] = 0             THEN 'No Discount'
        WHEN fo.[Discount] BETWEEN 0.01 AND 0.05 THEN '1%-5%'
        WHEN fo.[Discount] BETWEEN 0.06 AND 0.10 THEN '6%-10%'
        WHEN fo.[Discount] BETWEEN 0.11 AND 0.20 THEN '11%-20%'
        ELSE '> 20%'
    END
ORDER BY [DiscountAmount] DESC;
GO

-- ============================================================
-- Q09 — Average Order Value (AOV) by Customer Segment / Country
-- ============================================================
SELECT
    dc.[Country],
    COUNT(DISTINCT fo.[OrderID])                        AS [OrderCount],
    SUM(fo.[LineTotal])                                 AS [TotalRevenue],
    ROUND(SUM(fo.[LineTotal]) / COUNT(DISTINCT fo.[OrderID]), 2) AS [AOV]
FROM [dbo].[FactOrders]   fo
INNER JOIN [dbo].[DimCustomer] dc ON fo.[CustomerKey] = dc.[CustomerKey]
WHERE dc.[IsCurrent] = 1
GROUP BY dc.[Country]
ORDER BY [AOV] DESC;
GO

-- ============================================================
-- Q10 — Shipper Performance: Freight and Order Volume
-- ============================================================
SELECT
    ds.[CompanyName]               AS [Shipper],
    COUNT(DISTINCT fo.[OrderID])   AS [OrderCount],
    SUM(fo.[Freight])              AS [TotalFreight],
    AVG(fo.[Freight])              AS [AvgFreight],
    SUM(fo.[LineTotal])            AS [TotalRevenue]
FROM [dbo].[FactOrders]  fo
INNER JOIN [dbo].[DimShipper] ds ON fo.[ShipperKey] = ds.[ShipperKey]
GROUP BY ds.[CompanyName]
ORDER BY [TotalFreight] DESC;
GO

-- ============================================================
-- Q11 — Quarterly Sales Summary (Pivot-ready)
-- ============================================================
SELECT
    dd.[Year],
    SUM(CASE WHEN dd.[Quarter] = 1 THEN fo.[LineTotal] ELSE 0 END) AS [Q1],
    SUM(CASE WHEN dd.[Quarter] = 2 THEN fo.[LineTotal] ELSE 0 END) AS [Q2],
    SUM(CASE WHEN dd.[Quarter] = 3 THEN fo.[LineTotal] ELSE 0 END) AS [Q3],
    SUM(CASE WHEN dd.[Quarter] = 4 THEN fo.[LineTotal] ELSE 0 END) AS [Q4],
    SUM(fo.[LineTotal])                                              AS [YearTotal]
FROM [dbo].[FactOrders] fo
INNER JOIN [dbo].[DimDate] dd ON fo.[DateKeyOrder] = dd.[DateKey]
WHERE dd.[DateKey] > 0
GROUP BY dd.[Year]
ORDER BY dd.[Year];
GO

-- ============================================================
-- Q12 — ETL Execution History (Monitoring Dashboard)
-- ============================================================
SELECT
    [BatchID],
    [ProcedureName],
    [Status],
    [StartTime],
    [EndTime],
    [DurationSeconds],
    [RowsExtracted],
    [RowsInserted],
    [RowsUpdated],
    [ErrorMessage]
FROM [dbo].[ETLExecutionLog]
ORDER BY [ExecutionID] DESC;
GO
