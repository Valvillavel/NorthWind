CREATE TABLE [staging].[Shipper]
(
    [ShipperID]     INT            NOT NULL,
    [CompanyName]   NVARCHAR (40)  NOT NULL,
    [Phone]         NVARCHAR (24)  NULL,
    [RowVersion]    BIGINT         NULL,
    [BatchID]       INT            NULL,
    [LoadedAt]      DATETIME       NOT NULL CONSTRAINT [DF_stg_Shipper_LoadedAt] DEFAULT GETDATE(),
    CONSTRAINT [PK_stg_Shipper] PRIMARY KEY CLUSTERED ([ShipperID] ASC)
);
GO
