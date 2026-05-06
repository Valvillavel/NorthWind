IF NOT EXISTS(SELECT TOP(1) 1 FROM [dbo].[DimShipper])
BEGIN
    PRINT 'Cargando DimShipper...'
    
    INSERT INTO [dbo].[DimShipper] (
        [ShipperID],
        [CompanyName],
        [Phone],
        [CreatedDate],
        [ModifiedDate]
    )
    SELECT 
        [ShipperID],
        [CompanyName],
        [Phone],
        GETDATE() AS CreatedDate,
        GETDATE() AS ModifiedDate
    FROM [NorthWind].[dbo].[Shippers]
    
    PRINT 'DimShipper cargada exitosamente. Registros: ' + CAST(@@ROWCOUNT AS VARCHAR)
END
GO