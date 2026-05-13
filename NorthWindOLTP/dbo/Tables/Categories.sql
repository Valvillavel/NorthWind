CREATE TABLE [dbo].[Categories] (
    [CategoryID]   INT            IDENTITY (1, 1) NOT NULL,
    [CategoryName] NVARCHAR (15)  NOT NULL,
    [Description]  NVARCHAR (MAX) NULL,
    [Picture]      IMAGE          NULL,
    [rowversion]   ROWVERSION     NULL,
    [CreatedDate]  DATETIME       NOT NULL CONSTRAINT [DF_Categories_CreatedDate] DEFAULT GETDATE(),
    [UpdatedDate]  DATETIME       NOT NULL CONSTRAINT [DF_Categories_UpdatedDate] DEFAULT GETDATE(),
    CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED ([CategoryID] ASC),
    CONSTRAINT [UQ_Categories_CategoryName] UNIQUE ([CategoryName])
);


GO
CREATE NONCLUSTERED INDEX [IX_Categories_CategoryName]
    ON [dbo].[Categories]([CategoryName] ASC);

