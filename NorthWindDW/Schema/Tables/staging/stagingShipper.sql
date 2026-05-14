CREATE TABLE [staging].[Shipper]
(
    [ShipperID]   INT           NOT NULL,
    [CompanyName] NVARCHAR (40) NOT NULL,
    [Phone]       NVARCHAR (24) NULL,
    [rowversion]  ROWVERSION    NULL,
);
