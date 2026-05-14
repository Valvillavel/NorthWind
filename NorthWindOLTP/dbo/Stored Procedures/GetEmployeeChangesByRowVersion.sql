
CREATE   PROCEDURE [dbo].[GetEmployeeChangesByRowVersion]
(
   @startRow BIGINT 
   ,@endRow  BIGINT 
)
AS
BEGIN

  SELECT e.[EmployeeID]
      ,e.[LastName]
      ,e.[FirstName]
      ,e.[FirstName] + ' ' + e.[LastName] AS FullName
      ,e.[Title]
      ,e.[TitleOfCourtesy]
      ,e.[BirthDate]
      ,e.[HireDate]
      ,e.[Address]
      ,e.[City]
      ,e.[Region]
      ,e.[PostalCode]
      ,e.[Country]
      ,e.[HomePhone]
      ,e.[Extension]
      ,e.[Photo]
      ,e.[Notes]
      ,e.[ReportsTo]
      ,m.[FirstName] + ' ' + m.[LastName] AS ManagerName
      ,e.[PhotoPath]
    ,t.[TerritoryDescription]
    ,r.[RegionDescription]
  FROM 
  [dbo].[Employees] e
  LEFT JOIN [dbo].[Employees] m ON e.ReportsTo = m.EmployeeID
  INNER JOIN [dbo].[EmployeeTerritories] et ON e.EmployeeID=et.EmployeeID
  INNER JOIN [dbo].[Territories] t ON et.TerritoryID=t.TerritoryID
  INNER JOIN [dbo].[Region] r ON t.RegionID=r.RegionID
  WHERE 
  (e.[rowversion] > CONVERT(ROWVERSION,@startRow) AND e.[rowversion] <= CONVERT(ROWVERSION,@endRow))
  OR (et.[rowversion] > CONVERT(ROWVERSION,@startRow) AND et.[rowversion] <= CONVERT(ROWVERSION,@endRow))
  OR (t.[rowversion] > CONVERT(ROWVERSION,@startRow) AND t.[rowversion] <= CONVERT(ROWVERSION,@endRow))
  OR (r.[rowversion] > CONVERT(ROWVERSION,@startRow) AND r.[rowversion] <= CONVERT(ROWVERSION,@endRow))
END
