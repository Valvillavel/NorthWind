CREATE PROCEDURE [dbo].[DW_RunIncrementalLoad]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchID     INT;
    DECLARE @ExecutionID INT;
    DECLARE @ProcName    NVARCHAR(200) = OBJECT_NAME(@@PROCID);
    DECLARE @StepName    NVARCHAR(200);

    -- Watermarks from PackageConfig
    DECLARE @CustomerStart BIGINT;
    DECLARE @CustomerEnd   BIGINT;
    DECLARE @EmployeeStart BIGINT;
    DECLARE @EmployeeEnd   BIGINT;
    DECLARE @ProductStart  BIGINT;
    DECLARE @ProductEnd    BIGINT;

    SELECT @BatchID = ISNULL(MAX([BatchID]), 0) + 1
    FROM [dbo].[ETLExecutionLog];

    PRINT '======================================================';
    PRINT 'DW_RunIncrementalLoad — BatchID: ' + CAST(@BatchID AS VARCHAR);
    PRINT '======================================================';

    BEGIN TRY

        -- Retrieve last successful watermarks
        EXEC [dbo].[GetLastPackageRowVersion] 'Customer', @LastRowVersion = @CustomerStart OUTPUT;
        EXEC [dbo].[GetLastPackageRowVersion] 'Employee', @LastRowVersion = @EmployeeStart OUTPUT;
        EXEC [dbo].[GetLastPackageRowVersion] 'Product',  @LastRowVersion = @ProductStart  OUTPUT;

        -- Compute current max rowversion per entity
        SELECT @CustomerEnd = ISNULL(MAX(CONVERT(BIGINT, [rowversion])), 0)
        FROM [NorthWindOLTP].[dbo].[Customers];

        SELECT @EmployeeEnd = ISNULL(MAX(CONVERT(BIGINT, [rowversion])), 0)
        FROM [NorthWindOLTP].[dbo].[Employees];

        SELECT @ProductEnd = ISNULL(MAX(CONVERT(BIGINT, [rowversion])), 0)
        FROM [NorthWindOLTP].[dbo].[Products];

        -- ============================================================
        -- Step 1 — Load changed Customers
        -- ============================================================
        IF @CustomerEnd > @CustomerStart
        BEGIN
            SET @StepName = 'DW_LoadStagingCustomers (incremental)';
            INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject], [Notes])
            VALUES (@BatchID, @StepName, 'RUNNING', '[staging].[Customer]',
                    'StartRow=' + CAST(@CustomerStart AS VARCHAR) + ' EndRow=' + CAST(@CustomerEnd AS VARCHAR));
            SET @ExecutionID = SCOPE_IDENTITY();

            EXEC [dbo].[DW_LoadStagingCustomers]
                @BatchID = @BatchID, @ExecutionID = @ExecutionID,
                @StartRow = @CustomerStart, @EndRow = @CustomerEnd;

            SET @StepName = 'DW_MergeDimCustomer (incremental)';
            INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
            VALUES (@BatchID, @StepName, 'RUNNING', '[dbo].[DimCustomer]');
            SET @ExecutionID = SCOPE_IDENTITY();

            EXEC [dbo].[DW_MergeDimCustomer] @BatchID = @BatchID, @ExecutionID = @ExecutionID;

            EXEC [dbo].[UpdateLastPackageRowVersion] 'Customer', @CustomerEnd;
        END
        ELSE PRINT 'Customers — No changes detected.';

        -- ============================================================
        -- Step 2 — Load changed Employees
        -- ============================================================
        IF @EmployeeEnd > @EmployeeStart
        BEGIN
            SET @StepName = 'DW_LoadStagingEmployees (incremental)';
            INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
            VALUES (@BatchID, @StepName, 'RUNNING', '[staging].[Employee]');
            SET @ExecutionID = SCOPE_IDENTITY();

            EXEC [dbo].[DW_LoadStagingEmployees]
                @BatchID = @BatchID, @ExecutionID = @ExecutionID,
                @StartRow = @EmployeeStart, @EndRow = @EmployeeEnd;

            SET @StepName = 'DW_MergeDimEmployee (incremental)';
            INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
            VALUES (@BatchID, @StepName, 'RUNNING', '[dbo].[DimEmployee]');
            SET @ExecutionID = SCOPE_IDENTITY();

            EXEC [dbo].[DW_MergeDimEmployee] @BatchID = @BatchID, @ExecutionID = @ExecutionID;

            EXEC [dbo].[UpdateLastPackageRowVersion] 'Employee', @EmployeeEnd;
        END
        ELSE PRINT 'Employees — No changes detected.';

        -- ============================================================
        -- Step 3 — Load changed Products
        -- ============================================================
        IF @ProductEnd > @ProductStart
        BEGIN
            SET @StepName = 'DW_LoadStagingProducts (incremental)';
            INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
            VALUES (@BatchID, @StepName, 'RUNNING', '[staging].[Product]');
            SET @ExecutionID = SCOPE_IDENTITY();

            EXEC [dbo].[DW_LoadStagingProducts]
                @BatchID = @BatchID, @ExecutionID = @ExecutionID,
                @StartRow = @ProductStart, @EndRow = @ProductEnd;

            SET @StepName = 'DW_MergeDimProduct (incremental)';
            INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
            VALUES (@BatchID, @StepName, 'RUNNING', '[dbo].[DimProduct]');
            SET @ExecutionID = SCOPE_IDENTITY();

            EXEC [dbo].[DW_MergeDimProduct] @BatchID = @BatchID, @ExecutionID = @ExecutionID;

            EXEC [dbo].[UpdateLastPackageRowVersion] 'Product', @ProductEnd;
        END
        ELSE PRINT 'Products — No changes detected.';

        -- ============================================================
        -- Step 4 — Always reload Orders (append-only, new orders only)
        -- ============================================================
        SET @StepName = 'DW_LoadStagingOrders (incremental)';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[staging].[Order]');
        SET @ExecutionID = SCOPE_IDENTITY();

        EXEC [dbo].[DW_LoadStagingOrders]
            @BatchID = @BatchID, @ExecutionID = @ExecutionID;

        SET @StepName = 'DW_MergeFactOrders (incremental)';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[dbo].[FactOrders]');
        SET @ExecutionID = SCOPE_IDENTITY();

        EXEC [dbo].[DW_MergeFactOrders] @BatchID = @BatchID, @ExecutionID = @ExecutionID;

        PRINT 'DW_RunIncrementalLoad — Completed successfully. BatchID: ' + CAST(@BatchID AS VARCHAR);

    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();

        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorNumber],
            [ErrorSeverity], [ErrorState], [ErrorLine], [ErrorMessage]
        )
        VALUES (
            @BatchID, @ExecutionID, @ProcName,
            ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE(), @ErrMsg
        );

        PRINT 'DW_RunIncrementalLoad — FAILED at step: ' + ISNULL(@StepName, 'Unknown');
        PRINT 'Error: ' + @ErrMsg;

        THROW;
    END CATCH;
END
GO
