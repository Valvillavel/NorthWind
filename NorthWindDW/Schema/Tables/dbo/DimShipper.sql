CREATE TABLE [dbo].[DimShipper]
(
    [ShipperKey]            INT           IDENTITY (1, 1) NOT NULL,
    [ShipperID]             INT           NOT NULL,
    [CompanyName]           NVARCHAR (40) NOT NULL,
    [Phone]                 NVARCHAR (24) NULL,
    [CreatedDate]           DATETIME      NOT NULL DEFAULT GETDATE(),
    [ModifiedDate]          DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_DimShipper] PRIMARY KEY CLUSTERED ([ShipperKey] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_DimShipper_ShipperID] 
    ON [dbo].[DimShipper] ([ShipperID])
    INCLUDE ([ShipperKey]);
GO