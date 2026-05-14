CREATE OR ALTER PROCEDURE [dbo].[DW_LoadStagingOrders]
    @BatchID     INT    = NULL,
    @ExecutionID INT    = NULL,
    @StartRow    BIGINT = 0,
    @EndRow      BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- ================================================================
    -- INCREMENTAL LOAD REDESIGN (Hardening)
    -- ================================================================

    DECLARE @ProcName      NVARCHAR(200) = OBJECT_NAME(@@PROCID);
    DECLARE @RowsExtracted INT = 0;
    DECLARE @RowsDeleted   INT = 0;

    BEGIN TRY

        IF @EndRow IS NULL
            SELECT @EndRow = ISNULL(MAX(CONVERT(BIGINT, [rowversion])), 0)
            FROM [NorthWind].[dbo].[Orders];

        BEGIN TRANSACTION;

        IF @StartRow = 0
        BEGIN
            TRUNCATE TABLE [staging].[Order];
        END
        ELSE
        BEGIN
            DELETE so
            FROM [staging].[Order] so
            WHERE so.[OrderID] IN (
                SELECT o.[OrderID]
                FROM [NorthWind].[dbo].[Orders] o
                WHERE CONVERT(BIGINT, o.[rowversion]) > @StartRow
                  AND CONVERT(BIGINT, o.[rowversion]) <= @EndRow
            );
            SET @RowsDeleted = @@ROWCOUNT;
        END

        INSERT INTO [staging].[Order] (
            [OrderID], [CustomerID], [EmployeeID], [ShipperID], [ProductID],
            [OrderDate], [RequiredDate], [ShippedDate], [Freight],
            [UnitPrice], [Quantity], [Discount], [OrderTotal], [BatchID]
        )
        SELECT
            o.[OrderID],
            o.[CustomerID],
            o.[EmployeeID],
            o.[ShipVia],
            od.[ProductID],
            o.[OrderDate],
            o.[RequiredDate],
            o.[ShippedDate],
            ISNULL(o.[Freight], 0),
            od.[UnitPrice],
            od.[Quantity],
            od.[Discount],
            SUM(CONVERT(MONEY, od.[UnitPrice]
                    * CAST(od.[Quantity] AS DECIMAL(18,4))
                    * (1.0 - od.[Discount])))
                OVER (PARTITION BY o.[OrderID]) AS [OrderTotal],
            @BatchID
        FROM [NorthWind].[dbo].[Orders] o
        INNER JOIN [NorthWind].[dbo].[OrderDetails] od
            ON o.[OrderID] = od.[OrderID]
        WHERE
            CONVERT(BIGINT, o.[rowversion]) > @StartRow
            AND CONVERT(BIGINT, o.[rowversion]) <= @EndRow;

        SET @RowsExtracted = @@ROWCOUNT;

        COMMIT TRANSACTION;

        UPDATE [dbo].[ETLExecutionLog]
        SET
            [Status]       = 'SUCCESS',
            [EndTime]      = GETDATE(),
            [RowsExtracted] = @RowsExtracted,
            [Notes]        = CASE WHEN @StartRow = 0
                                  THEN 'Full load: ' + CAST(@RowsExtracted AS VARCHAR) + ' rows'
                                  ELSE 'Incremental: ' + CAST(@RowsDeleted AS VARCHAR) + ' deleted, '
                                     + CAST(@RowsExtracted AS VARCHAR) + ' inserted'
                             END
        WHERE [ExecutionID] = @ExecutionID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(MAX) = ISNULL(ERROR_MESSAGE(), 'Unknown error in DW_LoadStagingOrders');

        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorNumber],
            [ErrorSeverity], [ErrorState], [ErrorLine], [ErrorMessage], [AffectedObject]
        )
        VALUES (
            ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
            ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE(),
            @ErrMsg, '[staging].[Order]'
        );

        UPDATE [dbo].[ETLExecutionLog]
        SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
        WHERE [ExecutionID] = @ExecutionID;

        THROW;
    END CATCH;
END
GO
