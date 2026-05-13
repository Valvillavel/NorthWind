CREATE OR ALTER PROCEDURE [dbo].[DW_MergeDimCustomer]
	@BatchID     INT = NULL,
	@ExecutionID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	-- ================================================================
	-- ARCHITECTURAL DECISION: SCD TYPE 2 (Slowly Changing Dimension)
	-- ================================================================
	-- DimCustomer tracks full history of customer attribute changes.
	-- Each time a tracked attribute changes in the OLTP source, the
	-- current DW row is expired (ValidTo = today, IsCurrent = 0) and
	-- a new row is inserted (ValidFrom = today, IsCurrent = 1).
	--
	-- Tracked attributes (any change triggers a new version):
	--   CompanyName, ContactName, ContactTitle, Address, City,
	--   Region, PostalCode, Country, Phone, Fax, CustomerDesc
	--
	-- Non-tracked (administrative, not historised):
	--   ModifiedDate — always updated in-place on the current row.
	--
	-- FK behaviour in FactOrders:
	--   Historical fact rows retain their CustomerKey, pointing to
	--   the customer version that was active when the order was placed.
	--   LEFT JOIN + IsCurrent=1 in DW_MergeFactOrders resolves the
	--   *current* customer version for new orders.
	-- ================================================================

	DECLARE @ProcName     NVARCHAR(200) = OBJECT_NAME(@@PROCID);
	DECLARE @RowsInserted INT = 0;
	DECLARE @RowsUpdated  INT = 0;   -- rows expired (version closed)
	DECLARE @RowsNew      INT = 0;   -- brand-new customers (no prior row)
	DECLARE @Now          DATETIME   = GETDATE();

	BEGIN TRY
		BEGIN TRANSACTION;

		-- ============================================================
		-- Step 1 — Expire current rows where tracked attributes changed
		-- ============================================================
		-- A row needs expiry when the current DW version (IsCurrent=1)
		-- differs from staging on any tracked attribute.
		UPDATE dc
		SET
			dc.[ValidTo]      = @Now,
			dc.[IsCurrent]    = 0,
			dc.[ModifiedDate] = @Now
		FROM [dbo].[DimCustomer] dc
		INNER JOIN [staging].[Customer] sc
			ON dc.[CustomerID] = sc.[CustomerID]
		   AND dc.[IsCurrent]  = 1
		WHERE
			ISNULL(dc.[CompanyName],  '') <> ISNULL(sc.[CompanyName],  '')
		 OR ISNULL(dc.[ContactName],  '') <> ISNULL(sc.[ContactName],  '')
		 OR ISNULL(dc.[ContactTitle], '') <> ISNULL(sc.[ContactTitle], '')
		 OR ISNULL(dc.[Address],      '') <> ISNULL(sc.[Address],      '')
		 OR ISNULL(dc.[City],         '') <> ISNULL(sc.[City],         '')
		 OR ISNULL(dc.[Region],       '') <> ISNULL(sc.[Region],       '')
		 OR ISNULL(dc.[PostalCode],   '') <> ISNULL(sc.[PostalCode],   '')
		 OR ISNULL(dc.[Country],      '') <> ISNULL(sc.[Country],      '')
		 OR ISNULL(dc.[Phone],        '') <> ISNULL(sc.[Phone],        '')
		 OR ISNULL(dc.[Fax],          '') <> ISNULL(sc.[Fax],          '')
		 OR ISNULL(dc.[CustomerDesc], '') <> ISNULL(sc.[CustomerDesc], '');

		SET @RowsUpdated = @@ROWCOUNT;

		-- ============================================================
		-- Step 2 — Insert new version rows for:
		--   a) Customers that had an attribute change (just expired above)
		--   b) Brand-new customers with no prior DW row at all
		-- ============================================================
		-- Both cases share the same INSERT: any CustomerID with no
		-- IsCurrent=1 row after step 1 needs a fresh version inserted.
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
			@Now,    -- ValidFrom: this version becomes active now
			NULL,    -- ValidTo:   open-ended (current version)
			1,       -- IsCurrent: this is the active version
			@Now,
			@Now
		FROM [staging].[Customer] sc
		-- Exclude any CustomerID that already has an IsCurrent=1 row
		-- (unchanged customers — step 1 did not expire them)
		WHERE NOT EXISTS (
			SELECT 1 FROM [dbo].[DimCustomer] dc
			WHERE dc.[CustomerID] = sc.[CustomerID]
			  AND dc.[IsCurrent]  = 1
		);

		SET @RowsInserted = @@ROWCOUNT;
		SET @RowsNew      = @RowsInserted - @RowsUpdated;  -- net new customers

		COMMIT TRANSACTION;

		UPDATE [dbo].[ETLExecutionLog]
		SET
			[Status]       = 'SUCCESS',
			[EndTime]      = GETDATE(),
			[RowsInserted] = @RowsInserted,
			[RowsUpdated]  = @RowsUpdated,
			[Notes]        = CAST(@RowsNew AS VARCHAR) + ' new customers; '
						   + CAST(@RowsUpdated AS VARCHAR) + ' versions expired'
		WHERE [ExecutionID] = @ExecutionID;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

		DECLARE @ErrMsg NVARCHAR(MAX) = ISNULL(ERROR_MESSAGE(), 'Unknown error in DW_MergeDimCustomer');

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
