CREATE PROCEDURE [dbo].[usp_GetOrderSummary]
    @OrderID INT
AS
/*
================================================================================
 Procedure: usp_GetOrderSummary
 Purpose:   Returns header + line summary for a single order.
================================================================================
*/
BEGIN
    SET NOCOUNT ON;

    -- Order header
    SELECT
        o.[OrderID],
        c.[CustomerID],
        c.[CompanyName]                              AS [CustomerName],
        e.[FirstName] + ' ' + e.[LastName]           AS [SalesRep],
        o.[OrderDate],
        o.[RequiredDate],
        o.[ShippedDate],
        sh.[CompanyName]                             AS [ShipperName],
        o.[Freight],
        o.[ShipName],
        o.[ShipAddress],
        o.[ShipCity],
        o.[ShipCountry]
    FROM [dbo].[Orders]    o
    LEFT JOIN [dbo].[Customers] c  ON o.[CustomerID] = c.[CustomerID]
    LEFT JOIN [dbo].[Employees] e  ON o.[EmployeeID] = e.[EmployeeID]
    LEFT JOIN [dbo].[Shippers]  sh ON o.[ShipVia]    = sh.[ShipperID]
    WHERE o.[OrderID] = @OrderID;

    -- Order lines
    SELECT
        od.[ProductID],
        p.[ProductName],
        cat.[CategoryName],
        od.[UnitPrice],
        od.[Quantity],
        od.[Discount],
        CONVERT(MONEY, od.[Quantity] * od.[UnitPrice] * (1.0 - od.[Discount])) AS [LineTotal]
    FROM [dbo].[OrderDetails] od
    INNER JOIN [dbo].[Products]   p   ON od.[ProductID] = p.[ProductID]
    INNER JOIN [dbo].[Categories] cat ON p.[CategoryID] = cat.[CategoryID]
    WHERE od.[OrderID] = @OrderID
    ORDER BY od.[ProductID];
END
GO
