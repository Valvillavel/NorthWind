CREATE TABLE [dbo].[PackageConfig]
(
    [ConfigID]      INT            IDENTITY (1, 1) NOT NULL,
    [ConfigName]    NVARCHAR (100) NOT NULL,
    [ConfigValue]   NVARCHAR (500) NOT NULL,
    [Description]   NVARCHAR (500) NULL,
    [CreatedDate]   DATETIME       NOT NULL CONSTRAINT [DF_PackageConfig_CreatedDate] DEFAULT GETDATE(),
    [ModifiedDate]  DATETIME       NOT NULL CONSTRAINT [DF_PackageConfig_ModifiedDate] DEFAULT GETDATE(),
    CONSTRAINT [PK_PackageConfig] PRIMARY KEY CLUSTERED ([ConfigID] ASC),
    CONSTRAINT [UQ_PackageConfig_ConfigName] UNIQUE ([ConfigName])
);
GO

CREATE NONCLUSTERED INDEX [IX_PackageConfig_ConfigName]
    ON [dbo].[PackageConfig] ([ConfigName]);
GO
