CREATE OR ALTER PROCEDURE [dbo].[DW_MergeDimEmployee]
	@BatchID    INT = NULL,
	@ExecutionID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ProcName     NVARCHAR(200) = OBJECT_NAME(@@PROCID);
	DECLARE @RowsInserted INT = 0;
	DECLARE @RowsUpdated  INT = 0;

	BEGIN TRY
		BEGIN TRANSACTION;

		UPDATE de
		SET
			de.[LastName]             = se.[LastName],
			de.[FirstName]            = se.[FirstName],
			de.[FullName]             = se.[FirstName] + ' ' + se.[LastName],
			de.[Title]                = se.[Title],
			de.[TitleOfCourtesy]      = se.[TitleOfCourtesy],
			de.[BirthDate]            = se.[BirthDate],
			de.[HireDate]             = se.[HireDate],
			de.[Address]              = se.[Address],
			de.[City]                 = se.[City],
			de.[Region]               = se.[Region],
			de.[PostalCode]           = se.[PostalCode],
			de.[Country]              = se.[Country],
			de.[HomePhone]            = se.[HomePhone],
			de.[Extension]            = se.[Extension],
			de.[ReportsTo]            = se.[ReportsTo],
			de.[ManagerName]          = se.[ManagerName],
			de.[TerritoryDescription] = se.[TerritoryDescription],
			de.[RegionDescription]    = se.[RegionDescription],
			de.[ModifiedDate]         = GETDATE()
		FROM [dbo].[DimEmployee] de
		INNER JOIN [staging].[Employee] se ON de.[EmployeeID] = se.[EmployeeID];

		SET @RowsUpdated = @@ROWCOUNT;

		INSERT INTO [dbo].[DimEmployee] (
			[EmployeeID], [LastName], [FirstName], [FullName], [Title],
			[TitleOfCourtesy], [BirthDate], [HireDate], [Address], [City],
			[Region], [PostalCode], [Country], [HomePhone], [Extension],
			[ReportsTo], [ManagerName], [TerritoryDescription], [RegionDescription],
			[CreatedDate], [ModifiedDate]
		)
		SELECT
			se.[EmployeeID], se.[LastName], se.[FirstName],
			se.[FirstName] + ' ' + se.[LastName],
			se.[Title], se.[TitleOfCourtesy], se.[BirthDate], se.[HireDate],
			se.[Address], se.[City], se.[Region], se.[PostalCode], se.[Country],
			se.[HomePhone], se.[Extension], se.[ReportsTo], se.[ManagerName],
			se.[TerritoryDescription], se.[RegionDescription],
			GETDATE(), GETDATE()
		FROM [staging].[Employee] se
		LEFT JOIN [dbo].[DimEmployee] de ON de.[EmployeeID] = se.[EmployeeID]
		WHERE de.[EmployeeKey] IS NULL;

		SET @RowsInserted = @@ROWCOUNT;

		COMMIT TRANSACTION;

		UPDATE [dbo].[ETLExecutionLog]
		SET [Status] = 'SUCCESS', [EndTime] = GETDATE(),
			[RowsInserted] = @RowsInserted, [RowsUpdated] = @RowsUpdated
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
			@ErrMsg, '[dbo].[DimEmployee]'
		);

		UPDATE [dbo].[ETLExecutionLog]
		SET [Status] = 'FAILED', [EndTime] = GETDATE(), [ErrorMessage] = @ErrMsg
		WHERE [ExecutionID] = @ExecutionID;

		THROW;
	END CATCH;
END
GO
