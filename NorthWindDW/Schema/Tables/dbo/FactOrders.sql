CREATE TABLE [dbo].[FactOrders]
(
    [OrderKey]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [OrderID]               INT           NOT NULL,
    [CustomerKey]           INT           NOT NULL,
    [EmployeeKey]           INT           NOT NULL,
    [ProductKey]            INT           NOT NULL,
    [ShipperKey]            INT           NOT NULL,
    [DateKeyOrder]          INT           NOT NULL,
    [DateKeyRequired]       INT           NOT NULL,
    [DateKeyShipped]        INT           NOT NULL,

    [Quantity]              DECIMAL (18,4) NOT NULL,
    [UnitPrice]             MONEY         NOT NULL,
    [Discount]              REAL          NOT NULL,
    [Freight]               MONEY         NOT NULL,

    [LineTotal]             AS (CONVERT(MONEY, [Quantity] * [UnitPrice] * (1 - [Discount]))),
    [OrderTotal]            MONEY         NULL,

    [CreatedDate]           DATETIME      NOT NULL DEFAULT GETDATE(),
    [ETLBatchID]            INT           NULL,
    [SourceSystem]          NVARCHAR (50) DEFAULT ('Northwind_OLTP'),
    CONSTRAINT [PK_FactOrders] PRIMARY KEY CLUSTERED ([OrderKey] ASC),
    CONSTRAINT [FK_FactOrders_DimCustomer]
        FOREIGN KEY ([CustomerKey]) REFERENCES [dbo].[DimCustomer] ([CustomerKey]),
    CONSTRAINT [FK_FactOrders_DimEmployee]
        FOREIGN KEY ([EmployeeKey]) REFERENCES [dbo].[DimEmployee] ([EmployeeKey]),
    CONSTRAINT [FK_FactOrders_DimProduct]
        FOREIGN KEY ([ProductKey])  REFERENCES [dbo].[DimProduct]  ([ProductKey]),
    CONSTRAINT [FK_FactOrders_DimShipper]
        FOREIGN KEY ([ShipperKey])  REFERENCES [dbo].[DimShipper]  ([ShipperKey]),
    CONSTRAINT [FK_FactOrders_DimDate_Order]
        FOREIGN KEY ([DateKeyOrder])    REFERENCES [dbo].[DimDate] ([DateKey]),
    CONSTRAINT [FK_FactOrders_DimDate_Required]
        FOREIGN KEY ([DateKeyRequired]) REFERENCES [dbo].[DimDate] ([DateKey]),
    CONSTRAINT [FK_FactOrders_DimDate_Shipped]
        FOREIGN KEY ([DateKeyShipped])  REFERENCES [dbo].[DimDate] ([DateKey])
);
GO

CREATE NONCLUSTERED INDEX [IX_FactOrders_CustomerKey] 
    ON [dbo].[FactOrders] ([CustomerKey]);
GO

CREATE NONCLUSTERED INDEX [IX_FactOrders_EmployeeKey] 
    ON [dbo].[FactOrders] ([EmployeeKey]);
GO

CREATE NONCLUSTERED INDEX [IX_FactOrders_ProductKey] 
    ON [dbo].[FactOrders] ([ProductKey]);
GO

CREATE NONCLUSTERED INDEX [IX_FactOrders_ShipperKey] 
    ON [dbo].[FactOrders] ([ShipperKey]);
GO

CREATE NONCLUSTERED INDEX [IX_FactOrders_DateKeyOrder] 
    ON [dbo].[FactOrders] ([DateKeyOrder]);
GO

CREATE NONCLUSTERED INDEX [IX_FactOrders_DateKeyShipped] 
    ON [dbo].[FactOrders] ([DateKeyShipped]);
GO

CREATE NONCLUSTERED COLUMNSTORE INDEX [CCI_FactOrders] 
    ON [dbo].[FactOrders] (
        [OrderKey], [CustomerKey], [EmployeeKey], 
        [ProductKey], [DateKeyOrder], [Quantity], 
        [UnitPrice], [Discount]
    );
GO

