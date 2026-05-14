CREATE PROCEDURE [dbo].[DW_ValidateStagingCustomers]
	@BatchID     INT = NULL,
	@ExecutionID INT = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ProcName      NVARCHAR(200) = OBJECT_NAME(@@PROCID);
	DECLARE @RowsRejected  INT = 0;
	DECLARE @TotalRows     INT = 0;

	-- -------------------------------------------------------------------------
	-- 1. Auto-register execution log if not provided by the caller
	-- -------------------------------------------------------------------------
	IF @ExecutionID IS NULL OR @ExecutionID = 0
	BEGIN
		INSERT INTO [dbo].[ETLExecutionLog]
			([BatchID], [ProcedureName], [StartTime], [Status], [TargetObject], [SourceSystem])
		VALUES
			(ISNULL(@BatchID, -1), @ProcName, GETDATE(), 'RUNNING',
			 '[staging].[Customer]', 'Northwind_OLTP');

		SET @ExecutionID = SCOPE_IDENTITY();
	END

	BEGIN TRY

		SELECT @TotalRows = COUNT(*) FROM [staging].[Customer];

		-- -------------------------------------------------------------------------
		-- 2. Reset validation flags — full pass each time
		-- -------------------------------------------------------------------------
		UPDATE [staging].[Customer]
		SET [IsValid]           = 1,
			[ValidationMessage] = NULL;

		-- -------------------------------------------------------------------------
		-- Rule 1 — NULL CustomerID
		--   (defensive; PK constraint would catch it but we flag it explicitly
		--    in case staging was loaded without the constraint active)
		-- -------------------------------------------------------------------------
		UPDATE [staging].[Customer]
		SET [IsValid]           = 0,
			[ValidationMessage] = ISNULL([ValidationMessage] + ' | ', '') +
								  'NULL CustomerID'
		WHERE NULLIF(LTRIM(RTRIM(CAST([CustomerID] AS NVARCHAR(10)))), '') IS NULL;

		-- -------------------------------------------------------------------------
		-- Rule 2 — Duplicate CustomerID in staging
		--   (should not happen after de-dup in load, but belt-and-suspenders)
		-- -------------------------------------------------------------------------
		UPDATE s
		SET s.[IsValid]           = 0,
			s.[ValidationMessage] = ISNULL(s.[ValidationMessage] + ' | ', '') +
									'Duplicate CustomerID in staging'
		FROM [staging].[Customer] s
		INNER JOIN (
			SELECT [CustomerID]
			FROM   [staging].[Customer]
			GROUP BY [CustomerID]
			HAVING COUNT(*) > 1
		) dup ON s.[CustomerID] = dup.[CustomerID];

		-- -------------------------------------------------------------------------
		-- Rule 3 — Empty or NULL CompanyName
		-- -------------------------------------------------------------------------
		UPDATE [staging].[Customer]
		SET [IsValid]           = 0,
			[ValidationMessage] = ISNULL([ValidationMessage] + ' | ', '') +
								  'Missing CompanyName'
		WHERE NULLIF(LTRIM(RTRIM([CompanyName])), '') IS NULL;

		-- -------------------------------------------------------------------------
		-- Rule 4 — Country value outside known Northwind reference set
		--   (NULL is allowed — represented as 'Unknown' downstream)
		-- -------------------------------------------------------------------------
		UPDATE [staging].[Customer]
		SET [IsValid]           = 0,
			[ValidationMessage] = ISNULL([ValidationMessage] + ' | ', '') +
								  'Invalid or unrecognized Country value: ' +
								  ISNULL([Country], 'NULL')
		WHERE [Country] IS NOT NULL
		  AND [Country] NOT IN (
				'Argentina','Austria','Belgium','Brazil','Canada','Denmark',
				'Finland','France','Germany','Ireland','Italy','Mexico',
				'Netherlands','Norway','Poland','Portugal','Spain','Sweden',
				'Switzerland','UK','USA','Venezuela'
			  );

		-- -------------------------------------------------------------------------
		-- Rule 5 — Malformed Phone: must contain at least one digit
		-- -------------------------------------------------------------------------
		UPDATE [staging].[Customer]
		SET [IsValid]           = 0,
			[ValidationMessage] = ISNULL([ValidationMessage] + ' | ', '') +
								  'Phone has no digits: ' + [Phone]
		WHERE [Phone] IS NOT NULL
		  AND [Phone] NOT LIKE '%[0-9]%';

		-- -------------------------------------------------------------------------
		-- 3. Log each rejected row to ETLErrorLog
		-- -------------------------------------------------------------------------
		INSERT INTO [dbo].[ETLErrorLog] (
			[BatchID], [ExecutionID], [ProcedureName],
			[ErrorNumber], [ErrorSeverity], [ErrorState], [ErrorLine],
			[ErrorMessage], [AffectedObject]
		)
		SELECT
			ISNULL(@BatchID, -1),
			@ExecutionID,
			@ProcName,
			50000,          -- user-defined error number
			1,              -- severity: informational
			1,
			0,
			'DQ validation failed for CustomerID [' +
				ISNULL(CAST([CustomerID] AS NVARCHAR(10)), 'NULL') +
				']: ' + [ValidationMessage],
			'[staging].[Customer]'
		FROM [staging].[Customer]
		WHERE [IsValid] = 0;

		SELECT @RowsRejected = @@ROWCOUNT;

		-- -------------------------------------------------------------------------
		-- 4. Finalise execution log
		-- -------------------------------------------------------------------------
		UPDATE [dbo].[ETLExecutionLog]
		SET [Status]       = CASE WHEN @RowsRejected > 0 THEN 'WARNING' ELSE 'SUCCESS' END,
			[EndTime]      = GETDATE(),
			[RowsExtracted]= @TotalRows,
			[RowsRejected] = @RowsRejected,
			[Notes]        = CAST(@TotalRows    AS VARCHAR(10)) + ' total rows; ' +
							 CAST(@RowsRejected AS VARCHAR(10)) + ' rejected by DQ rules'
		WHERE [ExecutionID] = @ExecutionID;

	END TRY
	BEGIN CATCH
		DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();

		INSERT INTO [dbo].[ETLErrorLog] (
			[BatchID], [ExecutionID], [ProcedureName], [ErrorNumber],
			[ErrorSeverity], [ErrorState], [ErrorLine], [ErrorMessage],
			[AffectedObject], [InputParameters]
		)
		VALUES (
			ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
			ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE(),
			@ErrMsg, '[staging].[Customer]',
			'@BatchID=' + CAST(ISNULL(@BatchID, -1) AS VARCHAR)
		);

		UPDATE [dbo].[ETLExecutionLog]
		SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
		WHERE [ExecutionID] = @ExecutionID;

		THROW;
	END CATCH;
END
GO
