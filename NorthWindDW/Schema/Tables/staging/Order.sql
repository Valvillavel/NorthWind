CREATE TABLE [staging].[Order]
(
    [OrderID]           INT            NOT NULL,
    [CustomerID]        NCHAR (5)      NULL,
    [EmployeeID]        INT            NULL,
    [ShipperID]         INT            NULL,
    [ProductID]         INT            NOT NULL,
    [OrderDate]         DATETIME       NULL,
    [RequiredDate]      DATETIME       NULL,
    [ShippedDate]       DATETIME       NULL,
    [Freight]           MONEY          NULL,
    [UnitPrice]         MONEY          NOT NULL,
    [Quantity]          SMALLINT       NOT NULL,
    [Discount]          REAL           NOT NULL,
    [OrderTotal]        MONEY          NULL,
    [BatchID]           INT            NULL,
    [LoadedAt]          DATETIME       NOT NULL CONSTRAINT [DF_stg_Order_LoadedAt] DEFAULT GETDATE(),
    CONSTRAINT [PK_stg_Order] PRIMARY KEY CLUSTERED ([OrderID] ASC, [ProductID] ASC)
);
GO
