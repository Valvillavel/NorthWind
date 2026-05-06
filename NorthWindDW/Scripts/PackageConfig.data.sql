IF NOT EXISTS(SELECT TOP(1) 1
              FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Customer_LastRowVersion')
 BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description]) 
	VALUES ('Customer_LastRowVersion', '0', 'Última rowversion procesada para Customer')
 END
GO

IF NOT EXISTS(SELECT TOP(1) 1
              FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Employee_LastRowVersion')
 BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description]) 
	VALUES ('Employee_LastRowVersion', '0', 'Última rowversion procesada para Employee')
 END
GO

IF NOT EXISTS(SELECT TOP(1) 1
              FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Product_LastRowVersion')
 BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description]) 
	VALUES ('Product_LastRowVersion', '0', 'Última rowversion procesada para Product')
 END
GO

IF NOT EXISTS(SELECT TOP(1) 1
              FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Shipper_LastRowVersion')
 BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description]) 
	VALUES ('Shipper_LastRowVersion', '0', 'Última rowversion procesada para Shipper')
 END
GO

IF NOT EXISTS(SELECT TOP(1) 1
              FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Orders_LastRowVersion')
 BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description]) 
	VALUES ('Orders_LastRowVersion', '0', 'Última rowversion procesada para Orders')
 END
GO

IF NOT EXISTS(SELECT TOP(1) 1
              FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'ETL_Enabled')
 BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description]) 
	VALUES ('ETL_Enabled', '1', 'Habilitar (1) o deshabilitar (0) el proceso ETL')
 END
GO

IF NOT EXISTS(SELECT TOP(1) 1
              FROM [dbo].[PackageConfig]
			  WHERE [ConfigName] = 'Batch_Size')
 BEGIN
	INSERT [dbo].[PackageConfig] ([ConfigName], [ConfigValue], [Description]) 
	VALUES ('Batch_Size', '10000', 'Número de registros por lote en carga masiva')
 END
GO