CREATE PROCEDURE [dbo].[DW_ValidateStagingData]
    @BatchID     INT  = NULL,
    @ExecutionID INT  = NULL,
    @FailOnError BIT  = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProcName      NVARCHAR(200) = OBJECT_NAME(@@PROCID);
    DECLARE @ErrorCount    INT = 0;
    DECLARE @WarningCount  INT = 0;

    -- ================================================================
    -- NULL checks on mandatory Customer fields
    -- ================================================================
    IF EXISTS (
        SELECT 1 FROM [staging].[Customer]
        WHERE [CustomerID] IS NULL OR LTRIM(RTRIM([CustomerID])) = ''
           OR [CompanyName] IS NULL OR LTRIM(RTRIM([CompanyName])) = ''
    )
    BEGIN
        SET @ErrorCount += 1;
        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorMessage], [AffectedObject]
        )
        VALUES (
            ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
            'NULL or empty CustomerID / CompanyName detected in staging.Customer',
            '[staging].[Customer]'
        );
    END

    -- ================================================================
    -- Duplicate CustomerID in staging
    -- ================================================================
    IF EXISTS (
        SELECT [CustomerID] FROM [staging].[Customer]
        GROUP BY [CustomerID] HAVING COUNT(*) > 1
    )
    BEGIN
        SET @ErrorCount += 1;
        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorMessage], [AffectedObject]
        )
        VALUES (
            ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
            'Duplicate CustomerID values found in staging.Customer',
            '[staging].[Customer]'
        );
    END

    -- ================================================================
    -- NULL checks on mandatory Employee fields
    -- ================================================================
    IF EXISTS (
        SELECT 1 FROM [staging].[Employee]
        WHERE [EmployeeID] IS NULL
           OR [LastName] IS NULL OR LTRIM(RTRIM([LastName])) = ''
           OR [FirstName] IS NULL OR LTRIM(RTRIM([FirstName])) = ''
    )
    BEGIN
        SET @ErrorCount += 1;
        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorMessage], [AffectedObject]
        )
        VALUES (
            ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
            'NULL or empty mandatory Employee fields detected in staging.Employee',
            '[staging].[Employee]'
        );
    END

    -- ================================================================
    -- Negative or zero unit prices in staging.Order
    -- ================================================================
    IF EXISTS (
        SELECT 1 FROM [staging].[Order]
        WHERE [UnitPrice] < 0 OR [Quantity] <= 0
           OR [Discount] < 0 OR [Discount] > 1
    )
    BEGIN
        SET @ErrorCount += 1;
        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorMessage], [AffectedObject]
        )
        VALUES (
            ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
            'Invalid UnitPrice (<0), Quantity (<=0), or Discount (outside 0-1) in staging.Order',
            '[staging].[Order]'
        );
    END

    -- ================================================================
    -- Orders referencing unknown customers (orphan FK)
    -- ================================================================
    IF EXISTS (
        SELECT 1 FROM [staging].[Order] so
        WHERE so.[CustomerID] IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM [dbo].[DimCustomer] dc
              WHERE dc.[CustomerID] = so.[CustomerID]
                AND dc.[IsCurrent] = 1
          )
    )
    BEGIN
        SET @WarningCount += 1;
        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorMessage], [AffectedObject]
        )
        VALUES (
            ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
            'WARNING: Orders reference CustomerIDs not present in DimCustomer (IsCurrent = 1)',
            '[staging].[Order]'
        );
    END

    -- ================================================================
    -- Orders referencing unknown products (orphan FK)
    -- ================================================================
    IF EXISTS (
        SELECT 1 FROM [staging].[Order] so
        WHERE so.[ProductID] IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM [dbo].[DimProduct] dp
              WHERE dp.[ProductID] = so.[ProductID]
          )
    )
    BEGIN
        SET @WarningCount += 1;
        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorMessage], [AffectedObject]
        )
        VALUES (
            ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
            'WARNING: Orders reference ProductIDs not present in DimProduct',
            '[staging].[Order]'
        );
    END

    -- ================================================================
    -- Orders referencing unknown employees (orphan FK)
    -- ================================================================
    IF EXISTS (
        SELECT 1 FROM [staging].[Order] so
        WHERE so.[EmployeeID] IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM [dbo].[DimEmployee] de
              WHERE de.[EmployeeID] = so.[EmployeeID]
          )
    )
    BEGIN
        SET @WarningCount += 1;
        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorMessage], [AffectedObject]
        )
        VALUES (
            ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
            'WARNING: Orders reference EmployeeIDs not present in DimEmployee',
            '[staging].[Order]'
        );
    END

    -- ================================================================
    -- Future OrderDate validation
    -- ================================================================
    IF EXISTS (
        SELECT 1 FROM [staging].[Order]
        WHERE [OrderDate] > GETDATE()
    )
    BEGIN
        SET @WarningCount += 1;
        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorMessage], [AffectedObject]
        )
        VALUES (
            ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
            'WARNING: Future OrderDate values detected in staging.Order',
            '[staging].[Order]'
        );
    END

    -- ================================================================
    -- RequiredDate before OrderDate
    -- ================================================================
    IF EXISTS (
        SELECT 1 FROM [staging].[Order]
        WHERE [RequiredDate] IS NOT NULL
          AND [OrderDate] IS NOT NULL
          AND [RequiredDate] < [OrderDate]
    )
    BEGIN
        SET @WarningCount += 1;
        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorMessage], [AffectedObject]
        )
        VALUES (
            ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
            'WARNING: RequiredDate is before OrderDate in staging.Order',
            '[staging].[Order]'
        );
    END

    -- ================================================================
    -- Products with NULL CategoryName or SupplierCompanyName
    -- ================================================================
    IF EXISTS (
        SELECT 1 FROM [staging].[Product]
        WHERE [CategoryName] IS NULL OR [SupplierCompanyName] IS NULL
    )
    BEGIN
        SET @WarningCount += 1;
        INSERT INTO [dbo].[ETLErrorLog] (
            [BatchID], [ExecutionID], [ProcedureName], [ErrorMessage], [AffectedObject]
        )
        VALUES (
            ISNULL(@BatchID, -1), @ExecutionID, @ProcName,
            'WARNING: NULL CategoryName or SupplierCompanyName in staging.Product',
            '[staging].[Product]'
        );
    END

    -- ================================================================
    -- Result summary
    -- ================================================================
    SELECT
        @ErrorCount   AS [ErrorCount],
        @WarningCount AS [WarningCount],
        CASE WHEN @ErrorCount = 0 THEN 'PASSED' ELSE 'FAILED' END AS [ValidationResult];

    IF @FailOnError = 1 AND @ErrorCount > 0
        THROW 60001, 'DW_ValidateStagingData: Validation errors found. ETL halted.', 1;
END
GO
