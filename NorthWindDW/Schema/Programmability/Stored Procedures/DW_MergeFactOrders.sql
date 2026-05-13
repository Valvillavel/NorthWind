CREATE PROCEDURE [dbo].[DW_MergeFactOrders]
	@BatchID    INT = NULL,
	@ExecutionID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	-- ---------------------------------------------------------------
	-- FIX (CRITICAL-04 / HIGH-02 / HIGH-04):
	--
	-- CRITICAL-04 / HIGH-02: Original INNER JOINs to DimCustomer,
	-- DimEmployee, and DimShipper silently dropped any fact row where
	-- CustomerID, EmployeeID, or ShipVia was NULL in the OLTP Orders
	-- table.  Fix: use LEFT JOIN + ISNULL(..., -1) to route unresolved
	-- references to the pre-seeded Unknown member (surrogate key = -1).
	--
	-- HIGH-04: There was no UPDATE path — modified orders were never
	-- reflected in FactOrders after the initial load.  Fix: add an
	-- UPDATE block before the INSERT that refreshes measures for any
	-- existing fact row whose staging source has changed.
	-- ---------------------------------------------------------------

	DECLARE @ProcName     NVARCHAR(200) = OBJECT_NAME(@@PROCID);
	DECLARE @RowsInserted INT = 0;
	DECLARE @RowsUpdated  INT = 0;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- ============================================================
		-- Step A — UPDATE existing fact rows whose measures changed
		-- ============================================================
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
		-- Step B — INSERT new fact rows not yet in FactOrders
		-- ============================================================
		-- LEFT JOIN strategy: orders with NULL CustomerID/EmployeeID/
		-- ShipVia map to Unknown member (-1) instead of being dropped.
		-- DimProduct uses INNER JOIN because ProductID is NOT NULL in
		-- staging.Order and a missing product IS a data quality error.
		-- ============================================================
		INSERT INTO [dbo].[FactOrders] (
			[OrderID], [CustomerKey], [EmployeeKey], [ProductKey],
			[ShipperKey], [DateKeyOrder], [DateKeyRequired], [DateKeyShipped],
			[Quantity], [UnitPrice], [Discount], [Freight], [OrderTotal],
			[CreatedDate], [ETLBatchID], [SourceSystem]
		)
		SELECT
			so.[OrderID],
			ISNULL(dc.[CustomerKey], -1),                -- NULL CustomerID → Unknown
			ISNULL(de.[EmployeeKey], -1),                -- NULL EmployeeID → Unknown
			dp.[ProductKey],
			ISNULL(ds.[ShipperKey],  -1),                -- NULL ShipVia    → Unknown
			ISNULL(ddo.[DateKey], 0),                    -- NULL OrderDate  → DateKey 0
			ISNULL(ddr.[DateKey], 0),                    -- NULL RequiredDate
			ISNULL(dds.[DateKey], 0),                    -- NULL ShippedDate
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
		-- Existence check: skip rows already in FactOrders (handled by UPDATE above)
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
