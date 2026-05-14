CREATE OR ALTER PROCEDURE [dbo].[DW_MergeFactOrders]
	@BatchID    INT = NULL,
	@ExecutionID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ProcName     NVARCHAR(200) = OBJECT_NAME(@@PROCID);
	DECLARE @RowsInserted INT = 0;
	DECLARE @RowsUpdated  INT = 0;

	BEGIN TRY
		BEGIN TRANSACTION;

		UPDATE fo
		SET
			fo.[Quantity]   = so.[Quantity],
			fo.[UnitPrice]  = so.[UnitPrice],
			fo.[Discount]   = so.[Discount],
			fo.[Freight]    = ISNULL(so.[Freight], 0),
			fo.[OrderTotal] = so.[OrderTotal],
			fo.[ETLBatchID] = ISNULL(so.[BatchID], @BatchID)
		FROM [dbo].[FactOrders] fo
		INNER JOIN [dbo].[DimProduct] dp
			ON fo.[ProductKey] = dp.[ProductKey]
		INNER JOIN [staging].[Order] so
			ON fo.[OrderID]   = so.[OrderID]
			AND dp.[ProductID] = so.[ProductID]
		WHERE
			fo.[Quantity]   <> so.[Quantity]
			OR fo.[UnitPrice]  <> so.[UnitPrice]
			OR fo.[Discount]   <> so.[Discount]
			OR ISNULL(fo.[Freight],    0) <> ISNULL(so.[Freight],    0)
			OR ISNULL(fo.[OrderTotal], 0) <> ISNULL(so.[OrderTotal], 0);

		SET @RowsUpdated = @@ROWCOUNT;

		-- ============================================================
		-- INSERT new fact rows not yet in FactOrders
		-- ============================================================
		INSERT INTO [dbo].[FactOrders] (
			[OrderID], [CustomerKey], [EmployeeKey], [ProductKey],
			[ShipperKey], [DateKeyOrder], [DateKeyRequired], [DateKeyShipped],
			[Quantity], [UnitPrice], [Discount], [Freight], [OrderTotal],
			[CreatedDate], [ETLBatchID], [SourceSystem]
		)
		SELECT
			so.[OrderID],
			ISNULL(dc.[CustomerKey], -1),              
			ISNULL(de.[EmployeeKey], -1),               
			dp.[ProductKey],
			ISNULL(ds.[ShipperKey],  -1),               
			ISNULL(ddo.[DateKey], 0),                    
			ISNULL(ddr.[DateKey], 0),                    
			ISNULL(dds.[DateKey], 0),                    
			so.[Quantity],
			so.[UnitPrice],
			so.[Discount],
			ISNULL(so.[Freight], 0),
			so.[OrderTotal],
			GETDATE(),
			ISNULL(so.[BatchID], @BatchID),
			'Northwind_OLTP'
		FROM [staging].[Order] so
		-- Customer: LEFT JOIN — NULL CustomerID resolves to -1 (Unknown)
		LEFT JOIN [dbo].[DimCustomer] dc
			ON so.[CustomerID] = dc.[CustomerID] AND dc.[IsCurrent] = 1
		-- Employee: LEFT JOIN — NULL EmployeeID resolves to -1 (Unknown)
		LEFT JOIN [dbo].[DimEmployee] de
			ON so.[EmployeeID] = de.[EmployeeID]
		-- Product: INNER JOIN — ProductID is mandatory; missing product = data error
		INNER JOIN [dbo].[DimProduct] dp
			ON so.[ProductID] = dp.[ProductID]
		-- Shipper: LEFT JOIN — NULL ShipVia resolves to -1 (Unknown)
		LEFT JOIN [dbo].[DimShipper] ds
			ON so.[ShipperID] = ds.[ShipperID]
		-- Date lookups: LEFT JOIN — NULL/unmapped dates resolve to DateKey 0
		LEFT JOIN [dbo].[DimDate] ddo
			ON CAST(CONVERT(VARCHAR(8), so.[OrderDate],    112) AS INT) = ddo.[DateKey]
		LEFT JOIN [dbo].[DimDate] ddr
			ON CAST(CONVERT(VARCHAR(8), so.[RequiredDate], 112) AS INT) = ddr.[DateKey]
		LEFT JOIN [dbo].[DimDate] dds
			ON CAST(CONVERT(VARCHAR(8), so.[ShippedDate],  112) AS INT) = dds.[DateKey]
		LEFT JOIN [dbo].[FactOrders] fo
			ON so.[OrderID] = fo.[OrderID] AND dp.[ProductKey] = fo.[ProductKey]
		WHERE fo.[OrderKey] IS NULL;

		SET @RowsInserted = @@ROWCOUNT;

		COMMIT TRANSACTION;

		UPDATE [dbo].[ETLExecutionLog]
		SET [Status] = 'SUCCESS', [EndTime] = GETDATE(),
			[RowsInserted] = @RowsInserted, [RowsUpdated] = @RowsUpdated
		WHERE [ExecutionID] = @ExecutionID;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		DECLARE @ErrMsg NVARCHAR(MAX) = ISNULL(ERROR_MESSAGE(), 'Unknown error in DW_MergeFactOrders');

		INSERT INTO [dbo].[ETLErrorLog] (
			[BatchID], [ExecutionID], [ProcedureName], [ErrorNumber],
			[ErrorSeverity], [ErrorState], [ErrorLine], [ErrorMessage], [AffectedObject]
		)
		VALUES (
			ISNULL(@BatchID, -1), @ExecutionID, OBJECT_NAME(@@PROCID),
			ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE(),
			@ErrMsg, '[dbo].[FactOrders]'
		);

		UPDATE [dbo].[ETLExecutionLog]
		SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
		WHERE [ExecutionID] = @ExecutionID;

		THROW;
	END CATCH;
END
GO
