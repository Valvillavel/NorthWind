CREATE OR ALTER PROCEDURE [dbo].[DW_LoadStagingCustomers]
    @BatchID     INT  = NULL,
    @ExecutionID INT  = NULL,
    @StartRow    BIGINT = 0,
    @EndRow      BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProcName      NVARCHAR(200) = OBJECT_NAME(@@PROCID);
    DECLARE @RowsExtracted INT = 0;

    BEGIN TRY
        -- Resolve upper bound to current max rowversion when not provided
        IF @EndRow IS NULL
            SELECT @EndRow = CONVERT(BIGINT, MAX([rowversion])) FROM [NorthWind].[dbo].[Customers];

        BEGIN TRANSACTION;

        TRUNCATE TABLE [staging].[Customer];

        INSERT INTO [staging].[Customer] (
            [CustomerID], [CompanyName], [ContactName], [ContactTitle],
            [Address], [City], [Region], [PostalCode], [Country],
            [Phone], [Fax], [CustomerDesc], [RowVersion], [BatchID]
        )
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
            CONVERT(BIGINT, c.[rowversion]),
            @BatchID
        FROM [NorthWind].[dbo].[Customers] c
        LEFT JOIN [NorthWind].[dbo].[CustomerCustomerDemo] d
            ON c.[CustomerID] = d.[CustomerID]
        LEFT JOIN [NorthWind].[dbo].[CustomerDemographics] g
            ON d.[CustomerTypeID] = g.[CustomerTypeID]
        WHERE
            CONVERT(BIGINT, c.[rowversion]) > @StartRow
            AND CONVERT(BIGINT, c.[rowversion]) <= @EndRow;

        SET @RowsExtracted = @@ROWCOUNT;

        COMMIT TRANSACTION;

        UPDATE [dbo].[ETLExecutionLog]
        SET [Status] = 'SUCCESS', [EndTime] = GETDATE(), [RowsExtracted] = @RowsExtracted
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
            @ErrMsg, '[staging].[Customer]'
        );

        UPDATE [dbo].[ETLExecutionLog]
        SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
        WHERE [ExecutionID] = @ExecutionID;

        THROW;
    END CATCH;
END
GO
