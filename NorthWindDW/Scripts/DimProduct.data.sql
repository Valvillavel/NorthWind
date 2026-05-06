IF NOT EXISTS(SELECT TOP(1) 1 FROM [dbo].[DimProduct])
BEGIN
    PRINT 'Cargando DimProduct...'
    
    INSERT INTO [dbo].[DimProduct] (
        [ProductID],
        [ProductName],
        [CategoryName],
        [SupplierCompanyName],
        [QuantityPerUnit],
        [UnitPrice],
        [UnitsInStock],
        [UnitsOnOrder],
        [ReorderLevel],
        [Discontinued],
        [CreatedDate],
        [ModifiedDate]
    )
    SELECT 
        p.[ProductID],
        p.[ProductName],
        c.[CategoryName],
        s.[CompanyName] AS SupplierCompanyName,
        p.[QuantityPerUnit],
        p.[UnitPrice],
        p.[UnitsInStock],
        p.[UnitsOnOrder],
        p.[ReorderLevel],
        p.[Discontinued],
        GETDATE() AS CreatedDate,
        GETDATE() AS ModifiedDate
    FROM [NorthWind].[dbo].[Products] p
    INNER JOIN [NorthWind].[dbo].[Categories] c ON p.[CategoryID] = c.[CategoryID]
    INNER JOIN [NorthWind].[dbo].[Suppliers] s ON p.[SupplierID] = s.[SupplierID]
    
    PRINT 'DimProduct cargada exitosamente. Registros: ' + CAST(@@ROWCOUNT AS VARCHAR)
END
GO