CREATE TABLE [dbo].[ETLExecutionLog]
(
    [ExecutionID]       INT            IDENTITY (1, 1) NOT NULL,
    [BatchID]           INT            NOT NULL,
    [ProcedureName]     NVARCHAR (200) NOT NULL,
    [StartTime]         DATETIME       NOT NULL CONSTRAINT [DF_ETLExecutionLog_StartTime] DEFAULT GETDATE(),
    [EndTime]           DATETIME       NULL,
    [DurationSeconds]   AS (DATEDIFF(SECOND, [StartTime], [EndTime])) PERSISTED,
    [Status]            NVARCHAR (20)  NOT NULL CONSTRAINT [DF_ETLExecutionLog_Status] DEFAULT 'RUNNING',
    [RowsExtracted]     INT            NULL,
    [RowsInserted]      INT            NULL,
    [RowsUpdated]       INT            NULL,
    [RowsRejected]      INT            NULL,
    [ErrorMessage]      NVARCHAR (MAX) NULL,
    [SourceSystem]      NVARCHAR (50)  NULL CONSTRAINT [DF_ETLExecutionLog_SourceSystem] DEFAULT 'Northwind_OLTP',
    [TargetObject]      NVARCHAR (200) NULL,
    [Notes]             NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_ETLExecutionLog] PRIMARY KEY CLUSTERED ([ExecutionID] ASC),
    CONSTRAINT [CK_ETLExecutionLog_Status]
        CHECK ([Status] IN ('RUNNING', 'SUCCESS', 'FAILED', 'WARNING', 'SKIPPED'))
);
GO

CREATE NONCLUSTERED INDEX [IX_ETLExecutionLog_BatchID]
    ON [dbo].[ETLExecutionLog] ([BatchID]);
GO

CREATE NONCLUSTERED INDEX [IX_ETLExecutionLog_StartTime]
    ON [dbo].[ETLExecutionLog] ([StartTime] DESC);
GO

CREATE NONCLUSTERED INDEX [IX_ETLExecutionLog_Status]
    ON [dbo].[ETLExecutionLog] ([Status]);
GO
