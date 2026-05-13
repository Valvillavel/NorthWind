IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Customer_LastRowVersion')
BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('Customer_LastRowVersion', '0', 'Last processed rowversion for Customers incremental load')
END
GO

IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Employee_LastRowVersion')
BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('Employee_LastRowVersion', '0', 'Last processed rowversion for Employees incremental load')
END
GO

IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Product_LastRowVersion')
BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('Product_LastRowVersion', '0', 'Last processed rowversion for Products incremental load')
END
GO

IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Shipper_LastRowVersion')
BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('Shipper_LastRowVersion', '0', 'Last processed rowversion for Shippers incremental load')
END
GO

IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Orders_LastRowVersion')
BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('Orders_LastRowVersion', '0', 'Last processed rowversion for Orders incremental load')
END
GO

IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'ETL_Enabled')
BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('ETL_Enabled', '1', 'Enable (1) or disable (0) the ETL pipeline')
END
GO

IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Batch_Size')
BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description])
	VALUES ('Batch_Size', '10000', 'Number of records per batch during bulk loads')
END
GO
