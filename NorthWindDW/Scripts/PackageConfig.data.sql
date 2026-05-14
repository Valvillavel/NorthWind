IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [TableName] = 'Customer')
BEGIN
	INSERT [dbo].[PackageConfig] ([TableName], [LastRowVersion])
	VALUES ('Customer', 0)
END
GO

IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [TableName] = 'Employee')
BEGIN
	INSERT [dbo].[PackageConfig] ([TableName], [LastRowVersion])
	VALUES ('Employee', 0)
END
GO

IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [TableName] = 'Product')
BEGIN
	INSERT [dbo].[PackageConfig] ([TableName], [LastRowVersion])
	VALUES ('Product', 0)
END
GO

IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [TableName] = 'Shipper')
BEGIN
	INSERT [dbo].[PackageConfig] ([TableName], [LastRowVersion])
	VALUES ('Shipper', 0)
END
GO

IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[PackageConfig]
			  WHERE [TableName] = 'Orders')
BEGIN
	INSERT [dbo].[PackageConfig] ([TableName], [LastRowVersion])
	VALUES ('Orders', 0)
END
GO
