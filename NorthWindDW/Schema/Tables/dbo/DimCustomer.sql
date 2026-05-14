CREATE TABLE [dbo].[DimCustomer]
(
    [CustomerKey]       INT           IDENTITY (1, 1) NOT NULL,
    [CustomerID]        NCHAR (5)     NOT NULL,
    [CompanyName]       NVARCHAR (40) NOT NULL,
    [ContactName]       NVARCHAR (30) NULL,
    [ContactTitle]      NVARCHAR (30) NULL,
    [Address]           NVARCHAR (60) NULL,
    [City]              NVARCHAR (15) NULL,
    [Region]            NVARCHAR (15) NULL,
    [PostalCode]        NVARCHAR (10) NULL,
    [Country]           NVARCHAR (15) NULL,
    [Phone]             NVARCHAR (24) NULL,
    [Fax]               NVARCHAR (24) NULL,
    [CustomerDesc]      NVARCHAR (MAX) NULL,
    [ValidFrom]         DATETIME      NOT NULL DEFAULT GETDATE(),
    [ValidTo]           DATETIME      NULL,
    [IsCurrent]         BIT           NOT NULL DEFAULT 1,
    [CreatedDate]       DATETIME      NOT NULL DEFAULT GETDATE(),
    [ModifiedDate]      DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_DimCustomer] PRIMARY KEY CLUSTERED ([CustomerKey] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_DimCustomer_CustomerID] 
    ON [dbo].[DimCustomer] ([CustomerID]);
GO

CREATE NONCLUSTERED INDEX [IX_DimCustomer_CustomerID_IsCurrent]
    ON [dbo].[DimCustomer] ([CustomerID], [IsCurrent])
    INCLUDE ([CustomerKey]);
GO

CREATE NONCLUSTERED INDEX [IX_DimCustomer_IsCurrent] 
    ON [dbo].[DimCustomer] ([IsCurrent]);
GO

CREATE NONCLUSTERED INDEX [IX_DimCustomer_Country] 
    ON [dbo].[DimCustomer] ([Country]);
GO