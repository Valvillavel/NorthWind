CREATE OR ALTER PROCEDURE [dbo].[DW_LoadStagingShippers]
    @BatchID     INT    = NULL,
    @ExecutionID INT    = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProcName      NVARCHAR(200) = OBJECT_NAME(@@PROCID);
    DECLARE @RowsExtracted INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        TRUNCATE TABLE [staging].[Shipper];

        INSERT INTO [staging].[Shipper] (
            [ShipperID], [CompanyName], [Phone], [RowVersion], [BatchID]
        )
        SELECT
            s.[ShipperID],
            s.[CompanyName],
            s.[Phone],
            CONVERT(BIGINT, s.[rowversion]),
            @BatchID
        FROM [NorthWind].[dbo].[Shippers] s;

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
            @ErrMsg, '[staging].[Shipper]'
        );

        UPDATE [dbo].[ETLExecutionLog]
        SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
        WHERE [ExecutionID] = @ExecutionID;

        THROW;
    END CATCH;
END
GO
