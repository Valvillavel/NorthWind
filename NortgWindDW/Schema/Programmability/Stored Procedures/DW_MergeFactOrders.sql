CREATE PROCEDURE [dbo].[DW_MergeFactOrders]
AS
BEGIN
	-- INSERT: Nuevos hechos (FactOrders típicamente solo inserta, no actualiza)
	INSERT INTO [dbo].[FactOrders] (
		[OrderID], [CustomerKey], [EmployeeKey], [ProductKey],
		[ShipperKey], [DateKeyOrder], [DateKeyRequired], [DateKeyShipped],
		[Quantity], [UnitPrice], [Discount], [Freight], [OrderTotal],
		[CreatedDate], [ETLBatchID], [SourceSystem]
	)
	SELECT 
		so.[OrderID],
		dc.[CustomerKey],
		de.[EmployeeKey],
		dp.[ProductKey],
		ds.[ShipperKey],
		ddo.[DateKey],
		ddr.[DateKey],
		dds.[DateKey],
		so.[Quantity],
		so.[UnitPrice],
		so.[Discount],
		so.[Freight],
		so.[OrderTotal],
		GETDATE(),
		so.[BatchID],
		'Northwind_OLTP'
	FROM [staging].[Order] so
	INNER JOIN [dbo].[DimCustomer] dc ON so.[CustomerID] = dc.[CustomerID] AND dc.[IsCurrent] = 1
	INNER JOIN [dbo].[DimEmployee] de ON so.[EmployeeID] = de.[EmployeeID]
	INNER JOIN [dbo].[DimProduct] dp ON so.[ProductID] = dp.[ProductID]
	INNER JOIN [dbo].[DimShipper] ds ON so.[ShipperID] = ds.[ShipperID]
	INNER JOIN [dbo].[DimDate] ddo ON CAST(CONVERT(VARCHAR(8), so.[OrderDate], 112) AS INT) = ddo.[DateKey]
	INNER JOIN [dbo].[DimDate] ddr ON CAST(CONVERT(VARCHAR(8), so.[RequiredDate], 112) AS INT) = ddr.[DateKey]
	INNER JOIN [dbo].[DimDate] dds ON CAST(CONVERT(VARCHAR(8), so.[ShippedDate], 112) AS INT) = dds.[DateKey]
	LEFT JOIN [dbo].[FactOrders] fo ON so.[OrderID] = fo.[OrderID] AND dp.[ProductKey] = fo.[ProductKey]
	WHERE fo.[OrderKey] IS NULL
END
GO