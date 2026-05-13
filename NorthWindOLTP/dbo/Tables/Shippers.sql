CREATE TABLE [dbo].[Shippers] (
    [ShipperID]   INT           IDENTITY (1, 1) NOT NULL,
    [CompanyName] NVARCHAR (40) NOT NULL,
    [Phone]       NVARCHAR (24) NULL,
    [rowversion]  ROWVERSION    NULL,
    [CreatedDate] DATETIME      NOT NULL CONSTRAINT [DF_Shippers_CreatedDate] DEFAULT GETDATE(),
    [UpdatedDate] DATETIME      NOT NULL CONSTRAINT [DF_Shippers_UpdatedDate] DEFAULT GETDATE(),
    CONSTRAINT [PK_Shippers] PRIMARY KEY CLUSTERED ([ShipperID] ASC)
);

