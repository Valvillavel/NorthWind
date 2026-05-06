IF NOT EXISTS(SELECT TOP(1) 1 FROM [dbo].[DimCustomer])
BEGIN
    PRINT 'Cargando DimCustomer...'
    
    INSERT INTO [dbo].[DimCustomer] (
        [CustomerID],
        [CompanyName],
        [ContactName],
        [ContactTitle],
        [Address],
        [City],
        [Region],
        [PostalCode],
        [Country],
        [Phone],
        [Fax],
        [CustomerDesc],
        [ValidFrom],
        [ValidTo],
        [IsCurrent],
        [CreatedDate],
        [ModifiedDate]
    )
    SELECT 
        c.[CustomerID],
        c.[CompanyName],
        c.[ContactName],
        c.[ContactTitle],
        c.[Address],
        c.[City],
        c.[Region],
        c.[PostalCode],
        c.[Country],
        c.[Phone],
        c.[Fax],
        g.[CustomerDesc],
        GETDATE() AS ValidFrom,
        NULL AS ValidTo,
        1 AS IsCurrent,
        GETDATE() AS CreatedDate,
        GETDATE() AS ModifiedDate
    FROM [NorthWind].[dbo].[Customers] c
    LEFT JOIN [NorthWind].[dbo].[CustomerCustomerDemo] d ON c.[CustomerID] = d.[CustomerID]
    LEFT JOIN [NorthWind].[dbo].[CustomerDemographics] g ON d.[CustomerTypeID] = g.[CustomerTypeID]
    
    PRINT 'DimCustomer cargada exitosamente. Registros: ' + CAST(@@ROWCOUNT AS VARCHAR)
END
GO