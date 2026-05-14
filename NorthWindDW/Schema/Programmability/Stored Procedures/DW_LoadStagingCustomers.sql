CREATE OR ALTER PROCEDURE [dbo].[DW_LoadStagingCustomers]
    @BatchID     INT    = NULL,
    @ExecutionID INT    = NULL OUTPUT,
    @StartRow    BIGINT = NULL,
    @EndRow      BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProcName       NVARCHAR(200) = OBJECT_NAME(@@PROCID);
    DECLARE @RowsExtracted  INT  = 0;
    DECLARE @OLTPCount      INT  = 0;
    DECLARE @StagingCount   INT  = 0;
    DECLARE @Notes          NVARCHAR(MAX);

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
        -- -------------------------------------------------------------------------
        -- 2. Resolve watermark: read from PackageConfig when not supplied by caller
        -- -------------------------------------------------------------------------
        IF @StartRow IS NULL
        BEGIN
            SELECT @StartRow = ISNULL(CONVERT(BIGINT, [LastRowVersion]), 0)
            FROM   [dbo].[PackageConfig]
            WHERE  [TableName] = 'Customer';

            SET @StartRow = ISNULL(@StartRow, 0);
        END

        -- Determine upper bound (current DB rowversion)
        IF @EndRow IS NULL
            SELECT @EndRow = ISNULL(CONVERT(BIGINT, MAX([rowversion])), 0)
            FROM   [NorthWind].[dbo].[Customers];

        -- Count OLTP rows in the window for reconciliation note
        SELECT @OLTPCount = COUNT(*)
        FROM   [NorthWind].[dbo].[Customers]
        WHERE  CONVERT(BIGINT, [rowversion]) > @StartRow
          AND  CONVERT(BIGINT, [rowversion]) <= @EndRow;

        -- -------------------------------------------------------------------------
        -- 3. Load staging — truncate first to guarantee deterministic state
        -- -------------------------------------------------------------------------
        BEGIN TRANSACTION;

        TRUNCATE TABLE [staging].[Customer];

        -- De-duplicate: a CustomerID can appear in CustomerCustomerDemo multiple times
        -- (multiple CustomerTypeIDs). Use ROW_NUMBER to keep the first demographic row.
        ;WITH src AS (
            SELECT
                c.[CustomerID],
                c.[CompanyName],
                c.[ContactName],
                c.[ContactTitle],
                c.[Address],
                c.[City],
                c.[Region],
                c.[PostalCode],
                c.[Country],
                c.[Phone],
                c.[Fax],
                g.[CustomerDesc],
                CONVERT(BIGINT, c.[rowversion]) AS [RowVersion],
                ROW_NUMBER() OVER (PARTITION BY c.[CustomerID] ORDER BY c.[CustomerID]) AS rn
            FROM [NorthWind].[dbo].[Customers] c
            LEFT JOIN [NorthWind].[dbo].[CustomerCustomerDemo] d
                ON  c.[CustomerID] = d.[CustomerID]
            LEFT JOIN [NorthWind].[dbo].[CustomerDemographics] g
                ON  d.[CustomerTypeID] = g.[CustomerTypeID]
            WHERE
                CONVERT(BIGINT, c.[rowversion]) > @StartRow
                AND CONVERT(BIGINT, c.[rowversion]) <= @EndRow
        )
        INSERT INTO [staging].[Customer] (
            [CustomerID], [CompanyName], [ContactName], [ContactTitle],
            [Address], [City], [Region], [PostalCode], [Country],
            [Phone], [Fax], [CustomerDesc], [RowVersion], [BatchID]
        )
        SELECT
            [CustomerID], [CompanyName], [ContactName], [ContactTitle],
            [Address], [City], [Region], [PostalCode], [Country],
            [Phone], [Fax], [CustomerDesc], [RowVersion], @BatchID
        FROM src
        WHERE rn = 1;

        SET @RowsExtracted = @@ROWCOUNT;
        SET @StagingCount  = @RowsExtracted;

        COMMIT TRANSACTION;

        -- -------------------------------------------------------------------------
        -- 4. Update watermark only after a successful load with at least one row
        -- -------------------------------------------------------------------------
        IF @RowsExtracted > 0
            UPDATE [dbo].[PackageConfig]
            SET    [LastRowVersion] = @EndRow
            WHERE  [TableName] = 'Customer';

        -- -------------------------------------------------------------------------
        -- 5. Reconciliation note
        -- -------------------------------------------------------------------------
        SET @Notes =
            'OLTP window rows: '    + CAST(@OLTPCount    AS VARCHAR(10)) + '; ' +
            'Staged (distinct): '   + CAST(@StagingCount AS VARCHAR(10)) + '; ' +
            'Watermark before: '    + CAST(@StartRow     AS VARCHAR(20)) + '; ' +
            'Watermark after: '     + CAST(@EndRow       AS VARCHAR(20));

        UPDATE [dbo].[ETLExecutionLog]
        SET [Status]        = 'SUCCESS',
            [EndTime]       = GETDATE(),
            [RowsExtracted] = @RowsExtracted,
            [Notes]         = @Notes
        WHERE [ExecutionID] = @ExecutionID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

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
            '@BatchID='     + CAST(ISNULL(@BatchID, -1) AS VARCHAR) +
            ', @StartRow='  + CAST(ISNULL(@StartRow, -1) AS VARCHAR) +
            ', @EndRow='    + CAST(ISNULL(@EndRow,   -1) AS VARCHAR)
        );

        UPDATE [dbo].[ETLExecutionLog]
        SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
        WHERE [ExecutionID] = @ExecutionID;

        THROW;
    END CATCH;
END
GO
