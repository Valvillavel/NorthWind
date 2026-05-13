CREATE PROCEDURE [dbo].[DW_LoadStagingEmployees]
    @BatchID     INT    = NULL,
    @ExecutionID INT    = NULL,
    @StartRow    BIGINT = 0,
    @EndRow      BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- ---------------------------------------------------------------
    -- FIX (CRITICAL-02): The original SELECT DISTINCT across the
    -- EmployeeTerritories bridge table produced N rows per employee
    -- (one per territory assignment), causing a PRIMARY KEY violation
    -- on staging.Employee.EmployeeID on the 2nd insert per employee.
    --
    -- Fix: Use GROUP BY on all scalar employee columns and aggregate
    -- multi-valued territory/region fields with MIN() to pick one
    -- deterministic value per employee.  This matches the SCD1
    -- denormalised design of DimEmployee (one territory string per row).
    -- ---------------------------------------------------------------

    DECLARE @ProcName      NVARCHAR(200) = OBJECT_NAME(@@PROCID);
    DECLARE @RowsExtracted INT = 0;

    BEGIN TRY
        IF @EndRow IS NULL
            SELECT @EndRow = ISNULL(CONVERT(BIGINT, MAX([rowversion])), 0)
            FROM [NorthWindOLTP].[dbo].[Employees];

        BEGIN TRANSACTION;

        TRUNCATE TABLE [staging].[Employee];

        INSERT INTO [staging].[Employee] (
            [EmployeeID], [LastName], [FirstName], [Title], [TitleOfCourtesy],
            [BirthDate], [HireDate], [Address], [City], [Region], [PostalCode],
            [Country], [HomePhone], [Extension], [ReportsTo],
            [ManagerName], [TerritoryDescription], [RegionDescription],
            [RowVersion], [BatchID]
        )
        SELECT
            e.[EmployeeID],
            -- Scalar employee columns: identical across territory rows, safe to take any value
            MAX(e.[LastName])                                       AS [LastName],
            MAX(e.[FirstName])                                      AS [FirstName],
            MAX(e.[Title])                                          AS [Title],
            MAX(e.[TitleOfCourtesy])                                AS [TitleOfCourtesy],
            MAX(e.[BirthDate])                                      AS [BirthDate],
            MAX(e.[HireDate])                                       AS [HireDate],
            MAX(e.[Address])                                        AS [Address],
            MAX(e.[City])                                           AS [City],
            MAX(e.[Region])                                         AS [Region],
            MAX(e.[PostalCode])                                     AS [PostalCode],
            MAX(e.[Country])                                        AS [Country],
            MAX(e.[HomePhone])                                      AS [HomePhone],
            MAX(e.[Extension])                                      AS [Extension],
            MAX(e.[ReportsTo])                                      AS [ReportsTo],
            -- Manager name: single value per employee, MAX is deterministic
            MAX(ISNULL(m.[FirstName] + ' ' + m.[LastName], 'N/A')) AS [ManagerName],
            -- Territory / Region: employee may have many; MIN picks a consistent value
            MIN(ISNULL(CAST(t.[TerritoryDescription] AS NVARCHAR(50)), 'N/A')) AS [TerritoryDescription],
            MIN(ISNULL(CAST(r.[RegionDescription]    AS NVARCHAR(50)), 'N/A')) AS [RegionDescription],
            -- rowversion: same physical value for all rows of same employee
            MAX(CONVERT(BIGINT, e.[rowversion]))                    AS [RowVersion],
            @BatchID                                                AS [BatchID]
        FROM [NorthWindOLTP].[dbo].[Employees] e
        LEFT JOIN [NorthWindOLTP].[dbo].[Employees] m
            ON e.[ReportsTo] = m.[EmployeeID]
        LEFT JOIN [NorthWindOLTP].[dbo].[EmployeeTerritories] et
            ON e.[EmployeeID] = et.[EmployeeID]
        LEFT JOIN [NorthWindOLTP].[dbo].[Territories] t
            ON et.[TerritoryID] = t.[TerritoryID]
        LEFT JOIN [NorthWindOLTP].[dbo].[Region] r
            ON t.[RegionID] = r.[RegionID]
        WHERE
            CONVERT(BIGINT, e.[rowversion]) > @StartRow
            AND CONVERT(BIGINT, e.[rowversion]) <= @EndRow
        GROUP BY
            e.[EmployeeID];

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
            @ErrMsg, '[staging].[Employee]'
        );

        UPDATE [dbo].[ETLExecutionLog]
        SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
        WHERE [ExecutionID] = @ExecutionID;

        THROW;
    END CATCH;
END
GO
