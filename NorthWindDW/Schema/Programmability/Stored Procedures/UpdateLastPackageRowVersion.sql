CREATE PROCEDURE [dbo].[UpdateLastPackageRowVersion]
	@PackageName NVARCHAR(100),
	@LastRowVersion BIGINT
AS
BEGIN
	UPDATE [dbo].[PackageConfig]
	SET [ConfigValue] = CAST(@LastRowVersion AS NVARCHAR(500)),
		[ModifiedDate] = GETDATE()
	WHERE [ConfigName] = @PackageName + '_LastRowVersion'
END
GO