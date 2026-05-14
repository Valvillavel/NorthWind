CREATE OR ALTER PROCEDURE [dbo].[GetLastPackageRowVersion]
	@PackageName    NVARCHAR(100),
	@LastRowVersion BIGINT OUTPUT
AS
BEGIN
	SELECT CONVERT(BIGINT, [LastRowVersion]) AS LastRowVersion
	FROM [dbo].[PackageConfig]
	WHERE [TableName] = @PackageName
END
GO
