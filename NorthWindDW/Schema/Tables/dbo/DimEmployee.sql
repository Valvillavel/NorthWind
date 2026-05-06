CREATE TABLE [dbo].[DimEmployee]
(
    [EmployeeKey]           INT           IDENTITY (1, 1) NOT NULL,
    [EmployeeID]            INT           NOT NULL,
    [LastName]              NVARCHAR (20) NOT NULL,
    [FirstName]             NVARCHAR (10) NOT NULL,
    [FullName]              NVARCHAR (31) NOT NULL,
    [Title]                 NVARCHAR (30) NULL,
    [TitleOfCourtesy]       NVARCHAR (25) NULL,
    [BirthDate]             DATETIME      NULL,
    [HireDate]              DATETIME      NULL,
    [Address]               NVARCHAR (60) NULL,
    [City]                  NVARCHAR (15) NULL,
    [Region]                NVARCHAR (15) NULL,
    [PostalCode]            NVARCHAR (10) NULL,
    [Country]               NVARCHAR (15) NULL,
    [HomePhone]             NVARCHAR (24) NULL,
    [Extension]             NVARCHAR (4)  NULL,
    [ReportsTo]             INT           NULL,
    [ManagerName]           NVARCHAR (31) NULL,
    [TerritoryDescription]  NCHAR (50)    NULL,
    [RegionDescription]     NCHAR (50)    NULL,
    [CreatedDate]           DATETIME      NOT NULL DEFAULT GETDATE(),
    [ModifiedDate]          DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_DimEmployee] PRIMARY KEY CLUSTERED ([EmployeeKey] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_DimEmployee_EmployeeID] 
    ON [dbo].[DimEmployee] ([EmployeeID]);
GO

CREATE NONCLUSTERED INDEX [IX_DimEmployee_Country] 
    ON [dbo].[DimEmployee] ([Country]);
GO

CREATE NONCLUSTERED INDEX [IX_DimEmployee_Region] 
    ON [dbo].[DimEmployee] ([RegionDescription]);
GO