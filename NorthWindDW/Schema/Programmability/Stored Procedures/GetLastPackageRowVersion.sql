CREATE PROCEDURE [dbo].[GetLastPackageRowVersion]
	@PackageName    NVARCHAR(100),
	@LastRowVersion BIGINT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT @LastRowVersion = ISNULL(CONVERT(BIGINT, [ConfigValue]), 0)
	FROM [dbo].[PackageConfig]
	WHERE [ConfigName] = @PackageName + '_LastRowVersion';

	-- Default to 0 if no config row found
	IF @LastRowVersion IS NULL
		SET @LastRowVersion = 0;
END
GO
