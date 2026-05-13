CREATE OR ALTER PROCEDURE [dbo].[DW_LoadStagingProducts]
    @BatchID     INT    = NULL,
    @ExecutionID INT    = NULL,
    @StartRow    BIGINT = 0,
    @EndRow      BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProcName      NVARCHAR(200) = OBJECT_NAME(@@PROCID);
    DECLARE @RowsExtracted INT = 0;

    BEGIN TRY
        IF @EndRow IS NULL
            SELECT @EndRow = CONVERT(BIGINT, MAX([rowversion])) FROM [NorthWind].[dbo].[Products];

        BEGIN TRANSACTION;

        TRUNCATE TABLE [staging].[Product];

        INSERT INTO [staging].[Product] (
            [ProductID], [ProductName], [CategoryName], [SupplierCompanyName],
            [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder],
            [ReorderLevel], [Discontinued], [RowVersion], [BatchID]
        )
        SELECT
            p.[ProductID],
            p.[ProductName],
            ISNULL(c.[CategoryName], 'Unknown'),
            ISNULL(s.[CompanyName], 'Unknown'),
            p.[QuantityPerUnit],
            ISNULL(p.[UnitPrice], 0),
            ISNULL(p.[UnitsInStock], 0),
            ISNULL(p.[UnitsOnOrder], 0),
            ISNULL(p.[ReorderLevel], 0),
            p.[Discontinued],
            CONVERT(BIGINT, p.[rowversion]),
            @BatchID
        FROM [NorthWind].[dbo].[Products] p
        LEFT JOIN [NorthWind].[dbo].[Categories] c
            ON p.[CategoryID] = c.[CategoryID]
        LEFT JOIN [NorthWind].[dbo].[Suppliers] s
            ON p.[SupplierID] = s.[SupplierID]
        WHERE
            CONVERT(BIGINT, p.[rowversion]) > @StartRow
            AND CONVERT(BIGINT, p.[rowversion]) <= @EndRow;

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
            @ErrMsg, '[staging].[Product]'
        );

        UPDATE [dbo].[ETLExecutionLog]
        SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
        WHERE [ExecutionID] = @ExecutionID;

        THROW;
    END CATCH;
END
GO
