-- PackageConfigInit: inicializa las claves de watermark en PackageConfig si no existen.
-- Compatible con el schema HEAD (TableName / LastRowVersion).
IF NOT EXISTS (SELECT 1 FROM [dbo].[PackageConfig] WHERE [TableName] = 'Customer')
	INSERT INTO [dbo].[PackageConfig] ([TableName], [LastRowVersion])
	VALUES ('Customer', 0);

IF NOT EXISTS (SELECT 1 FROM [dbo].[PackageConfig] WHERE [TableName] = 'Employee')
	INSERT INTO [dbo].[PackageConfig] ([TableName], [LastRowVersion])
	VALUES ('Employee', 0);

IF NOT EXISTS (SELECT 1 FROM [dbo].[PackageConfig] WHERE [TableName] = 'Product')
	INSERT INTO [dbo].[PackageConfig] ([TableName], [LastRowVersion])
	VALUES ('Product', 0);

IF NOT EXISTS (SELECT 1 FROM [dbo].[PackageConfig] WHERE [TableName] = 'Shipper')
	INSERT INTO [dbo].[PackageConfig] ([TableName], [LastRowVersion])
	VALUES ('Shipper', 0);

IF NOT EXISTS (SELECT 1 FROM [dbo].[PackageConfig] WHERE [TableName] = 'Orders')
	INSERT INTO [dbo].[PackageConfig] ([TableName], [LastRowVersion])
	VALUES ('Orders', 0);
GO