CREATE PROCEDURE [dbo].[GetLastPackageRowVersion]
	@PackageName NVARCHAR(100)
AS
BEGIN
	SELECT CONVERT(BIGINT, [LastRowVersion]) AS LastRowVersion
	FROM [dbo].[PackageConfig]
	WHERE [TableName] = @PackageName
END
GO