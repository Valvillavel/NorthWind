CREATE OR ALTER PROCEDURE [dbo].[UpdateLastPackageRowVersion]
	@PackageName    NVARCHAR(100),
	@LastRowVersion BIGINT
AS
BEGIN
	SET NOCOUNT ON;

	MERGE [dbo].[PackageConfig] AS tgt
	USING (SELECT @PackageName + '_LastRowVersion' AS ConfigName,
				  CAST(@LastRowVersion AS NVARCHAR(500))  AS ConfigValue) AS src
	ON tgt.[ConfigName] = src.ConfigName
	WHEN MATCHED THEN
		UPDATE SET [ConfigValue]  = src.ConfigValue,
				   [ModifiedDate] = GETDATE()
	WHEN NOT MATCHED THEN
		INSERT ([ConfigName], [ConfigValue], [Description])
		VALUES (src.ConfigName, src.ConfigValue,
				'Watermark – last processed rowversion for ' + @PackageName);
END
GO