CREATE PROCEDURE [dbo].[DW_MergeDimShipper]
AS
BEGIN
	-- UPDATE: Registros existentes
	UPDATE ds
	SET 
		ds.[CompanyName]    = ss.[CompanyName],
		ds.[Phone]          = ss.[Phone],
		ds.[ModifiedDate]   = GETDATE()
	FROM [dbo].[DimShipper] ds
	INNER JOIN [staging].[Shipper] ss ON (ds.[ShipperID] = ss.[ShipperID])

	-- INSERT: Registros nuevos
	INSERT INTO [dbo].[DimShipper] (
		[ShipperID], [CompanyName], [Phone], [CreatedDate], [ModifiedDate]
	)
	SELECT 
		ss.[ShipperID], ss.[CompanyName], ss.[Phone], GETDATE(), GETDATE()
	FROM [staging].[Shipper] ss
	LEFT JOIN [dbo].[DimShipper] ds ON (ds.[ShipperID] = ss.[ShipperID])
	WHERE ds.[ShipperKey] IS NULL
END
GO