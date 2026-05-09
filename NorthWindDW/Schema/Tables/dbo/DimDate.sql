CREATE TABLE [dbo].[DimDate]
(
    [DateKey]           INT           IDENTITY(1,1) NOT NULL,
    [FullDate]          DATE          NOT NULL,
    [Year]              INT           NOT NULL,
    [Quarter]           INT           NOT NULL,
    [Month]             INT           NOT NULL,
    [Day]               INT           NOT NULL,
    [MonthName]         NVARCHAR (20) NOT NULL,
    [QuarterName]       NVARCHAR (10) NOT NULL,
    [DayOfWeek]         INT           NOT NULL,
    [DayName]           NVARCHAR (20) NOT NULL,
    [IsWeekend]         BIT           NOT NULL DEFAULT 0,
    [WeekOfYear]        INT           NOT NULL,
    [Semester]          INT           NOT NULL,
    [SemesterName]      NVARCHAR (10) NOT NULL,
    [IsHoliday]         BIT           NOT NULL DEFAULT 0,
    [HolidayName]       NVARCHAR (100) NULL,
    CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED ([DateKey] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_DimDate_Year_Month] 
    ON [dbo].[DimDate] ([Year], [Month]);
GO

CREATE NONCLUSTERED INDEX [IX_DimDate_FullDate] 
    ON [dbo].[DimDate] ([FullDate]);
GO