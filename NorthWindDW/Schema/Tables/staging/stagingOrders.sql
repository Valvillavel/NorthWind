CREATE TABLE [staging].[Orders]
(
    [OrderID]           INT             NOT NULL,
    [ProductID]         INT             NOT NULL,
    [Quantity]          DECIMAL (18,4)  NOT NULL,
    [UnitPrice]         MONEY           NOT NULL,
    [Discount]          REAL            NOT NULL,
    [LineTotal]         AS (CONVERT(MONEY, [Quantity] * [UnitPrice] * (1 - [Discount]))),
    [OrderTotal]        MONEY           NULL,
    [CustomerID]        NCHAR (5)       NULL,
    [EmployeeID]        INT             NULL,
    [OrderDate]         DATETIME        NULL,
    [RequiredDate]      DATETIME        NULL,
    [ShippedDate]       DATETIME        NULL,
    [ShipVia]           INT             NULL,
    [Freight]           MONEY           NULL,
    [ShipName]          NVARCHAR (40)   NULL,
    [ShipAddress]       NVARCHAR (60)   NULL,
    [ShipCity]          NVARCHAR (15)   NULL,
    [ShipRegion]        NVARCHAR (15)   NULL,
    [ShipPostalCode]    NVARCHAR (10)   NULL,
    [ShipCountry]       NVARCHAR (15)   NULL,
    [RowVersion]        BIGINT          NULL,

    [BatchID]           INT             NULL,
    [LoadedAt]          DATETIME        NOT NULL CONSTRAINT [DF_stg_Order_LoadedAt] DEFAULT GETDATE(),
    [IsValid]           BIT             NOT NULL CONSTRAINT [DF_stg_Order_IsValid] DEFAULT 1,
    [ValidationMessage] NVARCHAR (500)  NULL,
);
GO

CREATE NONCLUSTERED INDEX [IX_stg_Order_CustomerID]
    ON [staging].[Orders] ([CustomerID]);
GO

CREATE NONCLUSTERED INDEX [IX_stg_Order_EmployeeID]
    ON [staging].[Orders] ([EmployeeID]);
GO

CREATE NONCLUSTERED INDEX [IX_stg_Order_OrderDate]
    ON [staging].[Orders] ([OrderDate]);
GO
