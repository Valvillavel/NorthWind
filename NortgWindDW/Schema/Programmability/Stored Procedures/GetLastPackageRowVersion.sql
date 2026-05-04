CREATE PROCEDURE [dbo].[GetLastPackageRowVersion]
	@PackageName NVARCHAR(100)
AS
BEGIN
	SELECT CONVERT(BIGINT, [ConfigValue]) AS LastRowVersion
	FROM [dbo].[PackageConfig]
	WHERE [ConfigName] = @PackageName + '_LastRowVersion'
END
GO