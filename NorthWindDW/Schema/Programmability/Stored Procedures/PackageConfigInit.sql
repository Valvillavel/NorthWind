-- PackageConfigInit: inicializa las claves de watermark en PackageConfig si no existen.
-- Compatible con el schema HEAD (ConfigName / ConfigValue / Description).
IF NOT EXISTS (SELECT 1 FROM [dbo].[PackageConfig] WHERE [ConfigName] = 'Customer_LastRowVersion')
	INSERT INTO [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('Customer_LastRowVersion', '0', 'Last processed rowversion for Customers incremental load');

IF NOT EXISTS (SELECT 1 FROM [dbo].[PackageConfig] WHERE [ConfigName] = 'Employee_LastRowVersion')
	INSERT INTO [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('Employee_LastRowVersion', '0', 'Last processed rowversion for Employees incremental load');

IF NOT EXISTS (SELECT 1 FROM [dbo].[PackageConfig] WHERE [ConfigName] = 'Product_LastRowVersion')
	INSERT INTO [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('Product_LastRowVersion', '0', 'Last processed rowversion for Products incremental load');

IF NOT EXISTS (SELECT 1 FROM [dbo].[PackageConfig] WHERE [ConfigName] = 'Shipper_LastRowVersion')
	INSERT INTO [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('Shipper_LastRowVersion', '0', 'Last processed rowversion for Shippers incremental load');

IF NOT EXISTS (SELECT 1 FROM [dbo].[PackageConfig] WHERE [ConfigName] = 'Orders_LastRowVersion')
	INSERT INTO [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('Orders_LastRowVersion', '0', 'Last processed rowversion for Orders incremental load');
GO