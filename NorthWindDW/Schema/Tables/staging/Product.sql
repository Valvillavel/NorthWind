CREATE TABLE [staging].[Product]
(
    [ProductID]             INT            NOT NULL,
    [ProductName]           NVARCHAR (40)  NOT NULL,
    [CategoryName]          NVARCHAR (15)  NOT NULL,
    [SupplierCompanyName]   NVARCHAR (40)  NOT NULL,
    [QuantityPerUnit]       NVARCHAR (20)  NULL,
    [UnitPrice]             MONEY          NULL,
    [UnitsInStock]          SMALLINT       NULL,
    [UnitsOnOrder]          SMALLINT       NULL,
    [ReorderLevel]          SMALLINT       NULL,
    [Discontinued]          BIT            NOT NULL,
    [RowVersion]            BIGINT         NULL,
    [BatchID]               INT            NULL,
    [LoadedAt]              DATETIME       NOT NULL CONSTRAINT [DF_stg_Product_LoadedAt] DEFAULT GETDATE(),
    CONSTRAINT [PK_stg_Product] PRIMARY KEY CLUSTERED ([ProductID] ASC)
);
GO
