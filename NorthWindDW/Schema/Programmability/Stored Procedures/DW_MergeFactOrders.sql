CREATE PROCEDURE [dbo].[DW_MergeFactOrders]
AS
BEGIN
	-- UPDATE: Registros existentes
	UPDATE fo
	SET 
		[OrderID]           = so.[OrderID],
		[ProductID]         = so.[ProductID],
		[Quantity]          = CAST(so.[Quantity] AS DECIMAL(18,4)),
		[UnitPrice]			= so.[UnitPrice],
		[Discount]			= so.[Discount],
		[Freight]			= so.[Freight],
		[OrderTotal]		= so.[OrderTotal],
		[ETLBatchID]       = so.[BatchID]

	FROM [dbo].[FactOrders] fo
	INNER JOIN [staging].[Orders] so ON (fo.[OrderID] = so.[OrderID] and fo.[ProductID] = so.[ProductID])
END
GO