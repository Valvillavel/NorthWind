CREATE   PROCEDURE [dbo].[GetOrderChangesByRowVersion]
(
    @startRow BIGINT 
    ,@endRow  BIGINT 
)
AS
BEGIN
  SELECT o.[OrderID]
    ,o.[CustomerID]
    ,o.[EmployeeID]
    ,CAST(o.[OrderDate] AS DATE) AS [OrderDate]
    ,CAST(o.[RequiredDate] AS DATE) AS [RequiredDate]
    ,CAST(o.[ShippedDate] AS DATE) AS [ShippedDate]
    ,o.[ShipVia]
    ,o.[Freight]
    ,o.[ShipName]
    ,o.[ShipAddress]
    ,o.[ShipCity]
    ,o.[ShipRegion]
    ,o.[ShipPostalCode]
    ,o.[ShipCountry]
    ,o.[rowversion]
    ,c.[CategoryID]
    ,od.[ProductID]
    ,od.[Quantity]
	,od.[UnitPrice]
	,od.[Discount]
  FROM 
    [dbo].[Orders] o
    left join [dbo].[OrderDetails] od on o.OrderID = od.OrderID
    inner join [dbo].[Products] p on od.ProductID = p.ProductID
    inner join [dbo].[Categories] c on p.CategoryID = c.CategoryID
  WHERE 
    (o.[rowversion] > CONVERT(ROWVERSION,@startRow) AND o.[rowversion] <= CONVERT(ROWVERSION,@endRow))
END