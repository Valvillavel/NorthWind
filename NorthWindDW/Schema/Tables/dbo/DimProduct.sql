CREATE TABLE [dbo].[DimProduct]
(
    [ProductKey]            INT           IDENTITY (1, 1) NOT NULL,
    [ProductID]             INT           NOT NULL,
    [ProductName]           NVARCHAR (40) NOT NULL,
    [CategoryName]          NVARCHAR (15) NOT NULL,
    [SupplierCompanyName]   NVARCHAR (40) NOT NULL,
    [QuantityPerUnit]       NVARCHAR (20) NULL,
    [UnitPrice]             MONEY         NULL,
    [UnitsInStock]          SMALLINT      NULL,
    [UnitsOnOrder]          SMALLINT      NULL,
    [ReorderLevel]          SMALLINT      NULL,
    [Discontinued]          BIT           NOT NULL,
    [CreatedDate]           DATETIME      NOT NULL DEFAULT GETDATE(),
    [ModifiedDate]          DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_DimProduct] PRIMARY KEY CLUSTERED ([ProductKey] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_DimProduct_ProductID] 
    ON [dbo].[DimProduct] ([ProductID])
    INCLUDE ([ProductKey]);
GO

CREATE NONCLUSTERED INDEX [IX_DimProduct_Category] 
    ON [dbo].[DimProduct] ([CategoryName]);
GO

CREATE NONCLUSTERED INDEX [IX_DimProduct_Supplier] 
    ON [dbo].[DimProduct] ([SupplierCompanyName]);
GO