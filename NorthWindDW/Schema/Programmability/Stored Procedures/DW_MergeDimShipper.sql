CREATE PROCEDURE [dbo].[DW_MergeDimShipper]
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
		UPDATE ds
		SET
			ds.[CompanyName]  = ss.[CompanyName],
			ds.[Phone]        = ss.[Phone],
			ds.[ModifiedDate] = GETDATE()
		FROM [dbo].[DimShipper] ds
		INNER JOIN [staging].[Shipper] ss ON ds.[ShipperID] = ss.[ShipperID];

		SET @RowsUpdated = @@ROWCOUNT;

		-- INSERT: new records
		INSERT INTO [dbo].[DimShipper] (
			[ShipperID], [CompanyName], [Phone], [CreatedDate], [ModifiedDate]
		)
		SELECT
			ss.[ShipperID], ss.[CompanyName], ss.[Phone], GETDATE(), GETDATE()
		FROM [staging].[Shipper] ss
		LEFT JOIN [dbo].[DimShipper] ds ON ds.[ShipperID] = ss.[ShipperID]
		WHERE ds.[ShipperKey] IS NULL;

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
			@ErrMsg, '[dbo].[DimShipper]'
		);

		UPDATE [dbo].[ETLExecutionLog]
		SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
		WHERE [ExecutionID] = @ExecutionID;

		THROW;
	END CATCH;
END
GO
