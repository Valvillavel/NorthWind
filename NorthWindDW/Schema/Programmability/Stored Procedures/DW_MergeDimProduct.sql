CREATE PROCEDURE [dbo].[DW_MergeDimProduct]
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

		-- UPDATE: existing records
		UPDATE dp
		SET
			dp.[ProductName]         = sp.[ProductName],
			dp.[CategoryName]        = sp.[CategoryName],
			dp.[SupplierCompanyName] = sp.[SupplierCompanyName],
			dp.[QuantityPerUnit]     = sp.[QuantityPerUnit],
			dp.[UnitPrice]           = sp.[UnitPrice],
			dp.[UnitsInStock]        = sp.[UnitsInStock],
			dp.[UnitsOnOrder]        = sp.[UnitsOnOrder],
			dp.[ReorderLevel]        = sp.[ReorderLevel],
			dp.[Discontinued]        = sp.[Discontinued],
			dp.[ModifiedDate]        = GETDATE()
		FROM [dbo].[DimProduct] dp
		INNER JOIN [staging].[Product] sp ON dp.[ProductID] = sp.[ProductID];

		SET @RowsUpdated = @@ROWCOUNT;

		-- INSERT: new records
		INSERT INTO [dbo].[DimProduct] (
			[ProductID], [ProductName], [CategoryName], [SupplierCompanyName],
			[QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder],
			[ReorderLevel], [Discontinued], [CreatedDate], [ModifiedDate]
		)
		SELECT
			sp.[ProductID], sp.[ProductName], sp.[CategoryName], sp.[SupplierCompanyName],
			sp.[QuantityPerUnit], sp.[UnitPrice], sp.[UnitsInStock], sp.[UnitsOnOrder],
			sp.[ReorderLevel], sp.[Discontinued], GETDATE(), GETDATE()
		FROM [staging].[Product] sp
		LEFT JOIN [dbo].[DimProduct] dp ON dp.[ProductID] = sp.[ProductID]
		WHERE dp.[ProductKey] IS NULL;

		SET @RowsInserted = @@ROWCOUNT;

		COMMIT TRANSACTION;

		UPDATE [dbo].[ETLExecutionLog]
		SET [Status] = 'SUCCESS', [EndTime] = GETDATE(),
			[RowsInserted] = @RowsInserted, [RowsUpdated] = @RowsUpdated
		WHERE [ExecutionID] = @ExecutionID;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();

		INSERT INTO [dbo].[ETLErrorLog] (
			[BatchID], [ExecutionID], [ProcedureName], [ErrorNumber],
			[ErrorSeverity], [ErrorState], [ErrorLine], [ErrorMessage], [AffectedObject]
		)
		VALUES (
			ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
			ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE(),
			@ErrMsg, '[dbo].[DimProduct]'
		);

		UPDATE [dbo].[ETLExecutionLog]
		SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
		WHERE [ExecutionID] = @ExecutionID;

		THROW;
	END CATCH;
END
GO
