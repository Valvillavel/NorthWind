IF NOT EXISTS(SELECT TOP(1) 1
              FROM [dbo].[PackageConfig])
 BEGIN
	INSERT INTO [dbo].[PackageConfig] (TableName, LastRowVersion)
VALUES ('Customer', 0),
	   ('Employee', 0),
	   ('Product', 0),
	   ('Shipper', 0),
	   ('Orders', 0);
 END
GO