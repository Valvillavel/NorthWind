CREATE PROCEDURE [dbo].[DW_MergeDimCustomer]
	@BatchID    INT = NULL,
	@ExecutionID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ProcName     NVARCHAR(200) = OBJECT_NAME(@@PROCID);
	DECLARE @RowsInserted INT = 0;
	DECLARE @RowsUpdated  INT = 0;
	DECLARE @StartTime    DATETIME = GETDATE();

	BEGIN TRY
		BEGIN TRANSACTION;

		-- UPDATE: existing records
		UPDATE dc
		SET
			dc.[CompanyName]  = sc.[CompanyName],
			dc.[ContactName]  = sc.[ContactName],
			dc.[ContactTitle] = sc.[ContactTitle],
			dc.[Address]      = sc.[Address],
			dc.[City]         = sc.[City],
			dc.[Region]       = sc.[Region],
			dc.[PostalCode]   = sc.[PostalCode],
			dc.[Country]      = sc.[Country],
			dc.[Phone]        = sc.[Phone],
			dc.[Fax]          = sc.[Fax],
			dc.[CustomerDesc] = sc.[CustomerDesc],
			dc.[ModifiedDate] = GETDATE()
		FROM [dbo].[DimCustomer] dc
		INNER JOIN [staging].[Customer] sc ON dc.[CustomerID] = sc.[CustomerID];

		SET @RowsUpdated = @@ROWCOUNT;

		-- INSERT: new records
		INSERT INTO [dbo].[DimCustomer] (
			[CustomerID], [CompanyName], [ContactName], [ContactTitle],
			[Address], [City], [Region], [PostalCode], [Country],
			[Phone], [Fax], [CustomerDesc],
			[ValidFrom], [ValidTo], [IsCurrent], [CreatedDate], [ModifiedDate]
		)
		SELECT
			sc.[CustomerID], sc.[CompanyName], sc.[ContactName], sc.[ContactTitle],
			sc.[Address], sc.[City], sc.[Region], sc.[PostalCode], sc.[Country],
			sc.[Phone], sc.[Fax], sc.[CustomerDesc],
			GETDATE(), NULL, 1, GETDATE(), GETDATE()
		FROM [staging].[Customer] sc
		LEFT JOIN [dbo].[DimCustomer] dc ON dc.[CustomerID] = sc.[CustomerID]
		WHERE dc.[CustomerKey] IS NULL;

		SET @RowsInserted = @@ROWCOUNT;

		COMMIT TRANSACTION;

		-- Log success
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
			@ErrMsg, '[dbo].[DimCustomer]'
		);

		UPDATE [dbo].[ETLExecutionLog]
		SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
		WHERE [ExecutionID] = @ExecutionID;

		THROW;
	END CATCH;
END
GO
