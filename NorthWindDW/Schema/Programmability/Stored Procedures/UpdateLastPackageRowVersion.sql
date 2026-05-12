CREATE PROCEDURE [dbo].[UpdateLastPackageRowVersion]
	@PackageName NVARCHAR(100),
	@LastRowVersion BIGINT
AS
BEGIN
	UPDATE [dbo].[PackageConfig]
	SET [LastRowVersion] = CAST(@LastRowVersion AS NVARCHAR(500))
	WHERE [TableName] = @PackageName
END
GO