CREATE OR ALTER PROCEDURE [dbo].[DW_RunFullLoad]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BatchID     INT;
    DECLARE @ExecutionID INT;
    DECLARE @ProcName    NVARCHAR(200) = OBJECT_NAME(@@PROCID);
    DECLARE @StepName    NVARCHAR(200);

    -- ================================================================
    -- Generate BatchID from sequence of completed batches
    -- ================================================================
    SELECT @BatchID = ISNULL(MAX([BatchID]), 0) + 1
    FROM [dbo].[ETLExecutionLog];

    PRINT '======================================================';
    PRINT 'DW_RunFullLoad — BatchID: ' + CAST(@BatchID AS VARCHAR);
    PRINT '======================================================';

    BEGIN TRY

        -- ============================================================
        -- Step 1 — Load Staging: Customers
        -- ============================================================
        SET @StepName = 'DW_LoadStagingCustomers';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[staging].[Customer]');
        SET @ExecutionID = SCOPE_IDENTITY();

        EXEC [dbo].[DW_LoadStagingCustomers]
            @BatchID = @BatchID, @ExecutionID = @ExecutionID,
            @StartRow = 0, @EndRow = NULL;

        -- ============================================================
        -- Step 2 — Load Staging: Employees
        -- ============================================================
        SET @StepName = 'DW_LoadStagingEmployees';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[staging].[Employee]');
        SET @ExecutionID = SCOPE_IDENTITY();

        EXEC [dbo].[DW_LoadStagingEmployees]
            @BatchID = @BatchID, @ExecutionID = @ExecutionID,
            @StartRow = 0, @EndRow = NULL;

        -- ============================================================
        -- Step 3 — Load Staging: Products
        -- ============================================================
        SET @StepName = 'DW_LoadStagingProducts';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[staging].[Product]');
        SET @ExecutionID = SCOPE_IDENTITY();

        EXEC [dbo].[DW_LoadStagingProducts]
            @BatchID = @BatchID, @ExecutionID = @ExecutionID,
            @StartRow = 0, @EndRow = NULL;

        -- ============================================================
        -- Step 4 — Load Staging: Shippers
        -- ============================================================
        SET @StepName = 'DW_LoadStagingShippers';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[staging].[Shipper]');
        SET @ExecutionID = SCOPE_IDENTITY();

        EXEC [dbo].[DW_LoadStagingShippers]
            @BatchID = @BatchID, @ExecutionID = @ExecutionID;

        -- ============================================================
        -- Step 5 — Load Staging: Orders
        -- ============================================================
        SET @StepName = 'DW_LoadStagingOrders';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[staging].[Order]');
        SET @ExecutionID = SCOPE_IDENTITY();

        EXEC [dbo].[DW_LoadStagingOrders]
            @BatchID = @BatchID, @ExecutionID = @ExecutionID,
            @StartRow = 0, @EndRow = NULL;  -- full load: all orders

        -- ============================================================
        -- Step 6 — Validate Staging Data
        -- ============================================================
        SET @StepName = 'DW_ValidateStagingData';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', 'staging.*');
        SET @ExecutionID = SCOPE_IDENTITY();

        EXEC [dbo].[DW_ValidateStagingData]
            @BatchID = @BatchID, @ExecutionID = @ExecutionID, @FailOnError = 1;

        UPDATE [dbo].[ETLExecutionLog]
        SET [Status] = 'SUCCESS', [EndTime] = GETDATE()
        WHERE [ExecutionID] = @ExecutionID;

        -- ============================================================
        -- Step 7 — Merge Dimensions
        -- ============================================================
        SET @StepName = 'DW_MergeDimCustomer';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[dbo].[DimCustomer]');
        SET @ExecutionID = SCOPE_IDENTITY();
        EXEC [dbo].[DW_MergeDimCustomer] @BatchID = @BatchID, @ExecutionID = @ExecutionID;

        SET @StepName = 'DW_MergeDimEmployee';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[dbo].[DimEmployee]');
        SET @ExecutionID = SCOPE_IDENTITY();
        EXEC [dbo].[DW_MergeDimEmployee] @BatchID = @BatchID, @ExecutionID = @ExecutionID;

        SET @StepName = 'DW_MergeDimProduct';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[dbo].[DimProduct]');
        SET @ExecutionID = SCOPE_IDENTITY();
        EXEC [dbo].[DW_MergeDimProduct] @BatchID = @BatchID, @ExecutionID = @ExecutionID;

        SET @StepName = 'DW_MergeDimShipper';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[dbo].[DimShipper]');
        SET @ExecutionID = SCOPE_IDENTITY();
        EXEC [dbo].[DW_MergeDimShipper] @BatchID = @BatchID, @ExecutionID = @ExecutionID;

        -- ============================================================
        -- Step 8 — Merge Fact
        -- ============================================================
        SET @StepName = 'DW_MergeFactOrders';
        INSERT INTO [dbo].[ETLExecutionLog] ([BatchID], [ProcedureName], [Status], [TargetObject])
        VALUES (@BatchID, @StepName, 'RUNNING', '[dbo].[FactOrders]');
        SET @ExecutionID = SCOPE_IDENTITY();
        EXEC [dbo].[DW_MergeFactOrders] @BatchID = @BatchID, @ExecutionID = @ExecutionID;

        -- ============================================================
        -- Step 9 — Update watermarks
        -- ============================================================
        DECLARE @RVCustomer  BIGINT;
        DECLARE @RVEmployee  BIGINT;
        DECLARE @RVProduct   BIGINT;
        DECLARE @RVShipper   BIGINT;
        DECLARE @RVOrders    BIGINT;
        SELECT @RVCustomer = ISNULL(MAX(CONVERT(BIGINT, [rowversion])), 0) FROM [NorthWind].[dbo].[Customers];
        SELECT @RVEmployee = ISNULL(MAX(CONVERT(BIGINT, [rowversion])), 0) FROM [NorthWind].[dbo].[Employees];
        SELECT @RVProduct  = ISNULL(MAX(CONVERT(BIGINT, [rowversion])), 0) FROM [NorthWind].[dbo].[Products];
        SELECT @RVShipper  = ISNULL(MAX(CONVERT(BIGINT, [rowversion])), 0) FROM [NorthWind].[dbo].[Shippers];
        SELECT @RVOrders   = ISNULL(MAX(CONVERT(BIGINT, [rowversion])), 0) FROM [NorthWind].[dbo].[Orders];
        EXEC [dbo].[UpdateLastPackageRowVersion] 'Customer', @RVCustomer;
        EXEC [dbo].[UpdateLastPackageRowVersion] 'Employee', @RVEmployee;
        EXEC [dbo].[UpdateLastPackageRowVersion] 'Product',  @RVProduct;
        EXEC [dbo].[UpdateLastPackageRowVersion] 'Shipper',  @RVShipper;
        EXEC [dbo].[UpdateLastPackageRowVersion] 'Orders',   @RVOrders;

        PRINT 'DW_RunFullLoad — Completed successfully. BatchID: ' + CAST(@BatchID AS VARCHAR);

    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(MAX) = ISNULL(ERROR_MESSAGE(), 'Unknown error in DW_RunFullLoad');

        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorNumber],
            [ErrorSeverity], [ErrorState], [ErrorLine], [ErrorMessage]
        )
        VALUES (
            @BatchID, @ExecutionID, @ProcName,
            ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_LINE(), @ErrMsg
        );

        PRINT 'DW_RunFullLoad — FAILED at step: ' + ISNULL(@StepName, 'Unknown');
        PRINT 'Error: ' + @ErrMsg;

        THROW;
    END CATCH;
END
GO
