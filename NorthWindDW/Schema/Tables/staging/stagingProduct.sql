CREATE TABLE [staging].[Product] (
    [ProductID]             INT            NOT NULL,
    [ProductName]           NVARCHAR(40)   NOT NULL,
    [SupplierID]            INT            NULL,
    [CategoryID]            INT            NULL,
    [QuantityPerUnit]       NVARCHAR(20)   NULL,
    [UnitPrice]             MONEY          NULL,
    [UnitsInStock]          SMALLINT       NULL,
    [UnitsOnOrder]          SMALLINT       NULL,
    [ReorderLevel]          SMALLINT       NULL,
    [Discontinued]          BIT            NOT NULL,
    [CategoryName]          NVARCHAR(15)   NULL,
    [SupplierCompanyName]   NVARCHAR(40)   NULL
);