IF NOT EXISTS(SELECT TOP(1) 1 FROM [dbo].[DimEmployee])
BEGIN
    PRINT 'Cargando DimEmployee...'
    
    INSERT INTO [dbo].[DimEmployee] (
        [EmployeeID],
        [LastName],
        [FirstName],
        [FullName],
        [Title],
        [TitleOfCourtesy],
        [BirthDate],
        [HireDate],
        [Address],
        [City],
        [Region],
        [PostalCode],
        [Country],
        [HomePhone],
        [Extension],
        [ReportsTo],
        [ManagerName],
        [TerritoryDescription],
        [RegionDescription],
        [CreatedDate],
        [ModifiedDate]
    )
    SELECT DISTINCT
        e.[EmployeeID],
        e.[LastName],
        e.[FirstName],
        e.[FirstName] + ' ' + e.[LastName] AS FullName,
        e.[Title],
        e.[TitleOfCourtesy],
        e.[BirthDate],
        e.[HireDate],
        e.[Address],
        e.[City],
        e.[Region],
        e.[PostalCode],
        e.[Country],
        e.[HomePhone],
        e.[Extension],
        e.[ReportsTo],
        m.[FirstName] + ' ' + m.[LastName] AS ManagerName,
        t.[TerritoryDescription],
        r.[RegionDescription],
        GETDATE() AS CreatedDate,
        GETDATE() AS ModifiedDate
    FROM [NorthWind].[dbo].[Employees] e
    LEFT JOIN [NorthWind].[dbo].[Employees] m ON e.[ReportsTo] = m.[EmployeeID]
    INNER JOIN [NorthWind].[dbo].[EmployeeTerritories] et ON e.[EmployeeID] = et.[EmployeeID]
    INNER JOIN [NorthWind].[dbo].[Territories] t ON et.[TerritoryID] = t.[TerritoryID]
    INNER JOIN [NorthWind].[dbo].[Region] r ON t.[RegionID] = r.[RegionID]
    
    PRINT 'DimEmployee cargada exitosamente. Registros: ' + CAST(@@ROWCOUNT AS VARCHAR)
END
GO