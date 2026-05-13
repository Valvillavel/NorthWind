CREATE TABLE [staging].[Employee]
(
    [EmployeeID]            INT            NOT NULL,
    [LastName]              NVARCHAR (20)  NOT NULL,
    [FirstName]             NVARCHAR (10)  NOT NULL,
    [Title]                 NVARCHAR (30)  NULL,
    [TitleOfCourtesy]       NVARCHAR (25)  NULL,
    [BirthDate]             DATETIME       NULL,
    [HireDate]              DATETIME       NULL,
    [Address]               NVARCHAR (60)  NULL,
    [City]                  NVARCHAR (15)  NULL,
    [Region]                NVARCHAR (15)  NULL,
    [PostalCode]            NVARCHAR (10)  NULL,
    [Country]               NVARCHAR (15)  NULL,
    [HomePhone]             NVARCHAR (24)  NULL,
    [Extension]             NVARCHAR (4)   NULL,
    [ReportsTo]             INT            NULL,
    [ManagerName]           NVARCHAR (31)  NULL,
    [TerritoryDescription]  NCHAR (50)     NULL,
    [RegionDescription]     NCHAR (50)     NULL,
    [RowVersion]            BIGINT         NULL,
    [BatchID]               INT            NULL,
    [LoadedAt]              DATETIME       NOT NULL CONSTRAINT [DF_stg_Employee_LoadedAt] DEFAULT GETDATE(),
    CONSTRAINT [PK_stg_Employee] PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);
GO

-- Index for DW_MergeDimEmployee join on EmployeeID
CREATE NONCLUSTERED INDEX [IX_stg_Employee_EmployeeID]
    ON [staging].[Employee] ([EmployeeID])
    INCLUDE ([LastName], [FirstName], [RowVersion]);
GO
