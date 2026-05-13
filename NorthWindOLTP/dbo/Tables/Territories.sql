CREATE TABLE [dbo].[Territories] (
    [TerritoryID]          NVARCHAR (20) NOT NULL,
    [TerritoryDescription] NCHAR (50)    NOT NULL,
    [RegionID]             INT           NOT NULL,
    [rowversion]           ROWVERSION    NULL,
    [CreatedDate]          DATETIME      NOT NULL CONSTRAINT [DF_Territories_CreatedDate] DEFAULT GETDATE(),
    [UpdatedDate]          DATETIME      NOT NULL CONSTRAINT [DF_Territories_UpdatedDate] DEFAULT GETDATE(),
    CONSTRAINT [PK_Territories] PRIMARY KEY NONCLUSTERED ([TerritoryID] ASC),
    CONSTRAINT [FK_Territories_Region] FOREIGN KEY ([RegionID]) REFERENCES [dbo].[Region] ([RegionID])
);

