CREATE TABLE [dbo].[ETLErrorLog]
(
    [ErrorID]           INT            IDENTITY (1, 1) NOT NULL,
    [BatchID]           INT            NOT NULL,
    [ExecutionID]       INT            NULL,
    [ProcedureName]     NVARCHAR (200) NOT NULL,
    [ErrorTime]         DATETIME       NOT NULL CONSTRAINT [DF_ETLErrorLog_ErrorTime] DEFAULT GETDATE(),
    [ErrorNumber]       INT            NULL,
    [ErrorSeverity]     INT            NULL,
    [ErrorState]        INT            NULL,
    [ErrorLine]         INT            NULL,
    [ErrorMessage]      NVARCHAR (MAX) NOT NULL,
    [SourceSystem]      NVARCHAR (50)  NULL CONSTRAINT [DF_ETLErrorLog_SourceSystem] DEFAULT 'Northwind_OLTP',
    [AffectedObject]    NVARCHAR (200) NULL,
    [InputParameters]   NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_ETLErrorLog] PRIMARY KEY CLUSTERED ([ErrorID] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_ETLErrorLog_BatchID]
    ON [dbo].[ETLErrorLog] ([BatchID]);
GO

CREATE NONCLUSTERED INDEX [IX_ETLErrorLog_ErrorTime]
    ON [dbo].[ETLErrorLog] ([ErrorTime] DESC);
GO
