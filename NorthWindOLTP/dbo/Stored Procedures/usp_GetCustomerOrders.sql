CREATE PROCEDURE [dbo].[usp_GetCustomerOrders]
    @CustomerID NCHAR(5),
    @FromDate   DATETIME = NULL,
    @ToDate     DATETIME = NULL
AS
/*
================================================================================
 Procedure: usp_GetCustomerOrders
 Purpose:   Returns all orders for a given customer with line detail.
            Optionally filtered by date range.
================================================================================
*/
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.[OrderID],
        o.[OrderDate],
        o.[RequiredDate],
        o.[ShippedDate],
        s.[CompanyName]                            AS [ShipperName],
        od.[ProductID],
        p.[ProductName],
        cat.[CategoryName],
        od.[Quantity],
        od.[UnitPrice],
        od.[Discount],
        CONVERT(MONEY, od.[Quantity] * od.[UnitPrice] * (1.0 - od.[Discount])) AS [LineTotal],
        o.[Freight]
    FROM [dbo].[Orders]      o
    INNER JOIN [dbo].[OrderDetails] od  ON o.[OrderID]   = od.[OrderID]
    INNER JOIN [dbo].[Products]     p   ON od.[ProductID] = p.[ProductID]
    INNER JOIN [dbo].[Categories]   cat ON p.[CategoryID] = cat.[CategoryID]
    LEFT  JOIN [dbo].[Shippers]     s   ON o.[ShipVia]    = s.[ShipperID]
    WHERE o.[CustomerID] = @CustomerID
      AND (@FromDate IS NULL OR o.[OrderDate] >= @FromDate)
      AND (@ToDate   IS NULL OR o.[OrderDate] <= @ToDate)
    ORDER BY o.[OrderDate] DESC, o.[OrderID], od.[ProductID];
END
GO
