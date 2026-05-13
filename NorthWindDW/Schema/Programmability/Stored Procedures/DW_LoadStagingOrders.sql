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
    -- Previous implementation: TRUNCATE + full reload of all 2155+
    -- OrderDetails rows on every ETL run — O(n) full scan regardless
    -- of how many orders actually changed.
    --
    -- New implementation: watermark-based delta extraction.
    --   @StartRow / @EndRow bound the Orders.rowversion window.
    --   Only orders whose rowversion falls in (StartRow, EndRow] are
    --   processed; for each such order ALL its OrderDetails lines are
    --   reloaded (required for OrderTotal consistency).
    --   Unchanged orders and their lines are untouched in staging.
    --
    -- Full load path: @StartRow=0, @EndRow=NULL (default) — loads
    --   everything, identical in behaviour to the original truncate+load
    --   but now also driven through the same code path as incremental.
    --
    -- Staging grain:  one row per (OrderID, ProductID)
    -- PK:             staging.Order (OrderID, ProductID)
    -- Idempotency:    DELETE changed orders' existing staging rows first,
    --                 then INSERT fresh rows.  Safe for reruns.
    -- ================================================================

    DECLARE @ProcName      NVARCHAR(200) = OBJECT_NAME(@@PROCID);
    DECLARE @RowsExtracted INT = 0;
    DECLARE @RowsDeleted   INT = 0;

    BEGIN TRY

        -- Resolve @EndRow: current max rowversion on Orders
        IF @EndRow IS NULL
            SELECT @EndRow = ISNULL(MAX(CONVERT(BIGINT, [rowversion])), 0)
            FROM [NorthWind].[dbo].[Orders];

        BEGIN TRANSACTION;

        -- ============================================================
        -- Step A — Full load path: TRUNCATE when loading all orders
        -- ============================================================
        -- On a full load (@StartRow = 0) we clear the entire staging
        -- table for a clean deterministic state.
        -- On incremental loads we surgically remove only the changed
        -- order's existing staging rows before re-inserting fresh ones.
        -- ============================================================
        IF @StartRow = 0
        BEGIN
            TRUNCATE TABLE [staging].[Order];
        END
        ELSE
        BEGIN
            -- Remove only staging rows belonging to orders in the delta window
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

        -- ============================================================
        -- Step B — Insert delta: all lines for orders in the window
        -- ============================================================
        -- One row per order line (grain: OrderID + ProductID).
        -- OrderTotal computed as window SUM over the order's lines.
        -- ============================================================
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
            -- Single-pass window: correct order total with no cross-join
            SUM(CONVERT(MONEY, od.[UnitPrice]
                    * CAST(od.[Quantity] AS DECIMAL(18,4))
                    * (1.0 - od.[Discount])))
                OVER (PARTITION BY o.[OrderID]) AS [OrderTotal],
            @BatchID
        FROM [NorthWind].[dbo].[Orders] o
        INNER JOIN [NorthWind].[dbo].[OrderDetails] od
            ON o.[OrderID] = od.[OrderID]
        WHERE
            -- Full load: @StartRow=0 passes all rows (rowversion > 0 always true)
            -- Incremental: only orders modified since last watermark
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
