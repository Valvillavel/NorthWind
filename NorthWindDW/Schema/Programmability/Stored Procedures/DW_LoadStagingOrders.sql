CREATE PROCEDURE [dbo].[DW_LoadStagingOrders]
    @BatchID     INT    = NULL,
    @ExecutionID INT    = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- ---------------------------------------------------------------
    -- FIX (CRITICAL-01): The original query cross-joined OrderDetails
    -- (od × od2 on the same OrderID), producing O(n²) rows per order,
    -- then used GROUP BY + a window function referencing od2 columns
    -- that were outside the GROUP BY.  This produced non-deterministic
    -- (and incorrect) OrderTotal values and caused massive I/O waste.
    --
    -- Fix: Remove od2 entirely.  Use a single-pass SUM window function
    -- directly over od, partitioned by OrderID.  Each line row sees the
    -- correct pre-computed total for its parent order with zero cross-join
    -- overhead.  No GROUP BY is needed.
    -- ---------------------------------------------------------------

    DECLARE @ProcName      NVARCHAR(200) = OBJECT_NAME(@@PROCID);
    DECLARE @RowsExtracted INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        TRUNCATE TABLE [staging].[Order];

        -- One row per order line (grain: OrderID + ProductID)
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
            -- Single-pass window function: sum all line amounts for this order.
            -- CONVERT(MONEY,...) applied inside the window to match OLTP precision.
            SUM(CONVERT(MONEY, od.[UnitPrice] * CAST(od.[Quantity] AS DECIMAL(18,4)) * (1.0 - od.[Discount])))
                OVER (PARTITION BY o.[OrderID])  AS [OrderTotal],
            @BatchID
        FROM [NorthWindOLTP].[dbo].[Orders] o
        INNER JOIN [NorthWindOLTP].[dbo].[OrderDetails] od
            ON o.[OrderID] = od.[OrderID];

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
            @ErrMsg, '[staging].[Order]'
        );

        UPDATE [dbo].[ETLExecutionLog]
        SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
        WHERE [ExecutionID] = @ExecutionID;

        THROW;
    END CATCH;
END
GO
