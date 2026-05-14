CREATE TABLE [staging].[Customer]
(
    [CustomerID]    NCHAR (5)      NOT NULL,
    [CompanyName]   NVARCHAR (40)  NOT NULL,
    [ContactName]   NVARCHAR (30)  NULL,
    [ContactTitle]  NVARCHAR (30)  NULL,
    [Address]       NVARCHAR (60)  NULL,
    [City]          NVARCHAR (15)  NULL,
    [Region]        NVARCHAR (15)  NULL,
    [PostalCode]    NVARCHAR (10)  NULL,
    [Country]       NVARCHAR (15)  NULL,
    [Phone]         NVARCHAR (24)  NULL,
    [Fax]               NVARCHAR (24)   NULL,
    [CustomerDesc]      NVARCHAR (MAX)  NULL,
    [RowVersion]        BIGINT          NULL,
    [BatchID]           INT             NULL,
    [LoadedAt]          DATETIME        NOT NULL CONSTRAINT [DF_stg_Customer_LoadedAt] DEFAULT GETDATE(),
    [IsValid]           BIT             NOT NULL CONSTRAINT [DF_stg_Customer_IsValid] DEFAULT 1,
    [ValidationMessage] NVARCHAR (500)  NULL,
    CONSTRAINT [PK_stg_Customer] PRIMARY KEY CLUSTERED ([CustomerID] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_stg_Customer_CustomerID]
    ON [staging].[Customer] ([CustomerID])
    INCLUDE ([CompanyName], [ContactName], [ContactTitle], [Address],
             [City], [Region], [PostalCode], [Country], [Phone], [Fax]);
GO
