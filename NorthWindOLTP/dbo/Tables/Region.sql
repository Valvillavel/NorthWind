CREATE TABLE [dbo].[Region] (
    [RegionID]          INT        NOT NULL,
    [RegionDescription] NCHAR (50) NOT NULL,
    [rowversion]        ROWVERSION NULL,
    [CreatedDate]       DATETIME   NOT NULL CONSTRAINT [DF_Region_CreatedDate] DEFAULT GETDATE(),
    [UpdatedDate]       DATETIME   NOT NULL CONSTRAINT [DF_Region_UpdatedDate] DEFAULT GETDATE(),
    CONSTRAINT [PK_Region] PRIMARY KEY NONCLUSTERED ([RegionID] ASC)
);

