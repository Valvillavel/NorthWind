CREATE OR ALTER PROCEDURE [dbo].[DW_MergeDimCustomer]
	@BatchID     INT = NULL,
	@ExecutionID INT = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ProcName      NVARCHAR(200) = OBJECT_NAME(@@PROCID);
	DECLARE @RowsInserted  INT = 0;  -- new SCD2 versions (new customers + re-versions)
	DECLARE @RowsExpired   INT = 0;  -- old versions closed
	DECLARE @RowsNew       INT = 0;  -- brand-new customers (no prior DimCustomer row)
	DECLARE @RowsRejected  INT = 0;  -- staging rows skipped due to DQ failures
	DECLARE @Now           DATETIME = GETDATE();

	-- -------------------------------------------------------------------------
	-- 1. Auto-register execution log if not provided by the caller
	-- -------------------------------------------------------------------------
	IF @ExecutionID IS NULL OR @ExecutionID = 0
	BEGIN
		INSERT INTO [dbo].[ETLExecutionLog]
			([BatchID], [ProcedureName], [StartTime], [Status], [TargetObject], [SourceSystem])
		VALUES
			(ISNULL(@BatchID, -1), @ProcName, GETDATE(), 'RUNNING',
			 '[dbo].[DimCustomer]', 'Northwind_OLTP');

		SET @ExecutionID = SCOPE_IDENTITY();
	END

	BEGIN TRY

		-- Count DQ-rejected rows for reporting
		SELECT @RowsRejected = COUNT(*) FROM [staging].[Customer] WHERE [IsValid] = 0;

		BEGIN TRANSACTION;

		-- =====================================================================
		-- SCD TYPE 2 — STEP A: Expire current rows that have changed
		-- =====================================================================
		UPDATE dc
		SET
			dc.[ValidTo]      = @Now,
			dc.[IsCurrent]    = 0,
			dc.[ModifiedDate] = @Now
		FROM [dbo].[DimCustomer] dc
		INNER JOIN [staging].[Customer] sc
			ON  dc.[CustomerID] = sc.[CustomerID]
			AND dc.[IsCurrent]  = 1
			AND sc.[IsValid]    = 1
		WHERE
			ISNULL(dc.[CompanyName],    '') <> ISNULL(sc.[CompanyName],    '')
		 OR ISNULL(dc.[ContactName],    '') <> ISNULL(sc.[ContactName],    '')
		 OR ISNULL(dc.[ContactTitle],   '') <> ISNULL(sc.[ContactTitle],   '')
		 OR ISNULL(dc.[Address],        '') <> ISNULL(sc.[Address],        '')
		 OR ISNULL(dc.[City],           '') <> ISNULL(sc.[City],           '')
		 OR ISNULL(dc.[Region],         '') <> ISNULL(sc.[Region],         '')
		 OR ISNULL(dc.[PostalCode],     '') <> ISNULL(sc.[PostalCode],     '')
		 OR ISNULL(dc.[Country],        '') <> ISNULL(sc.[Country],        '')
		 OR ISNULL(dc.[Phone],          '') <> ISNULL(sc.[Phone],          '')
		 OR ISNULL(dc.[Fax],            '') <> ISNULL(sc.[Fax],            '')
		 OR ISNULL(dc.[CustomerDesc],   '') <> ISNULL(sc.[CustomerDesc],   '');

		SET @RowsExpired = @@ROWCOUNT;

		-- =====================================================================
		-- SCD TYPE 2 — STEP B: Insert new current versions
		--   Covers two cases:
		--     (a) brand-new CustomerID — no prior row in DimCustomer
		--     (b) existing CustomerID whose current row was just expired (Step A)
		-- =====================================================================
		-- Count net-new customers before the insert so we can report them
		SELECT @RowsNew = COUNT(*)
		FROM [staging].[Customer] sc
		WHERE sc.[IsValid] = 1
		  AND NOT EXISTS (
				SELECT 1 FROM [dbo].[DimCustomer] dc
				WHERE dc.[CustomerID] = sc.[CustomerID]
			  );

		INSERT INTO [dbo].[DimCustomer] (
			[CustomerID], [CompanyName], [ContactName], [ContactTitle],
			[Address], [City], [Region], [PostalCode], [Country],
			[Phone], [Fax], [CustomerDesc],
			[ValidFrom], [ValidTo], [IsCurrent],
			[CreatedDate], [ModifiedDate]
		)
		SELECT
			sc.[CustomerID],
			sc.[CompanyName],
			sc.[ContactName],
			sc.[ContactTitle],
			sc.[Address],
			sc.[City],
			sc.[Region],
			sc.[PostalCode],
			sc.[Country],
			sc.[Phone],
			sc.[Fax],
			sc.[CustomerDesc],
			@Now,   -- ValidFrom
			NULL,   -- ValidTo  (open-ended = current version)
			1,      -- IsCurrent
			@Now,   -- CreatedDate
			@Now    -- ModifiedDate
		FROM [staging].[Customer] sc
		WHERE sc.[IsValid] = 1
		  AND NOT EXISTS (
				SELECT 1 FROM [dbo].[DimCustomer] dc
				WHERE dc.[CustomerID] = sc.[CustomerID]
				  AND dc.[IsCurrent]  = 1
			  );

		SET @RowsInserted = @@ROWCOUNT;

		COMMIT TRANSACTION;

		-- -------------------------------------------------------------------------
		-- 2. Finalise execution log
		-- -------------------------------------------------------------------------
		UPDATE [dbo].[ETLExecutionLog]
		SET
			[Status]       = 'SUCCESS',
			[EndTime]      = GETDATE(),
			[RowsInserted] = @RowsInserted,
			[RowsUpdated]  = @RowsExpired,
			[RowsRejected] = @RowsRejected,
			[Notes]        = CAST(@RowsNew      AS VARCHAR(10)) + ' new customers; ' +
							 CAST(@RowsExpired  AS VARCHAR(10)) + ' versions expired; ' +
							 CAST(@RowsInserted AS VARCHAR(10)) + ' versions inserted; ' +
							 CAST(@RowsRejected AS VARCHAR(10)) + ' staging rows skipped (DQ)'
		WHERE [ExecutionID] = @ExecutionID;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		DECLARE @ErrMsg NVARCHAR(MAX) = ISNULL(ERROR_MESSAGE(), 'Unknown error in DW_MergeDimCustomer');

		INSERT INTO [dbo].[ETLErrorLog] (
			[BatchID], [ExecutionID], [ProcedureName], [ErrorNumber],
			[ErrorSeverity], [ErrorState], [ErrorLine], [ErrorMessage],
			[AffectedObject], [InputParameters]
		)
		VALUES (
			ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
			ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE(),
			@ErrMsg, '[dbo].[DimCustomer]',
			'@BatchID=' + CAST(ISNULL(@BatchID, -1) AS VARCHAR)
		);

		UPDATE [dbo].[ETLExecutionLog]
		SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
		WHERE [ExecutionID] = @ExecutionID;

		THROW;
	END CATCH;
END
GO
