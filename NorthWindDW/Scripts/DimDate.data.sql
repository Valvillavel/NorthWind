-- ================================================================================
-- DimDate Calendar Seed — 1990-01-01 through 2030-12-31
-- ================================================================================
-- FIX (CRITICAL-04): Original script only covered 1996–1999.  Any OLTP date
-- outside that range mapped to DateKey = 0 (Unknown), silently corrupting all
-- date-based analytics.  Extended to 1990–2030 to cover historical data plus
-- a safe forward buffer for current and future transactions.
--
-- Guard: IF NOT EXISTS on the first expected calendar row (19900101) makes this
-- script safely re-runnable; it skips population if already seeded.
-- The inner LEFT JOIN / WHERE dd.FullDate IS NULL also handles partial re-runs.
-- ================================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[DimDate] WHERE [DateKey] = 19900101)
BEGIN
	SET IDENTITY_INSERT [dbo].[DimDate] ON;

	BEGIN TRANSACTION;

	DECLARE @startdate DATE = '1990-01-01';
	DECLARE @enddate   DATE = '2030-12-31';
	DECLARE @datelist TABLE (FullDate DATE);

	WHILE (@startdate <= @enddate)
	BEGIN
		INSERT INTO @datelist (FullDate) VALUES (@startdate);
		SET @startdate = DATEADD(DAY, 1, @startdate);
	END

	INSERT INTO [dbo].[DimDate] (
		[DateKey],
		[FullDate],
		[Year],
		[Quarter],
		[Month],
		[Day],
		[MonthName],
		[QuarterName],
		[DayOfWeek],
		[DayName],
		[IsWeekend],
		[WeekOfYear],
		[Semester],
		[SemesterName]
	)
	SELECT
		CONVERT(INT, CONVERT(VARCHAR(8), dl.FullDate, 112)) AS [DateKey],
		dl.FullDate                                          AS [FullDate],
		YEAR(dl.FullDate)                                    AS [Year],
		DATEPART(QUARTER, dl.FullDate)                       AS [Quarter],
		MONTH(dl.FullDate)                                   AS [Month],
		DAY(dl.FullDate)                                     AS [Day],
		DATENAME(MONTH, dl.FullDate)                         AS [MonthName],
		'Q' + CAST(DATEPART(QUARTER, dl.FullDate) AS VARCHAR) AS [QuarterName],
		DATEPART(WEEKDAY, dl.FullDate) - 1                   AS [DayOfWeek],
		DATENAME(WEEKDAY, dl.FullDate)                       AS [DayName],
		CASE WHEN DATEPART(WEEKDAY, dl.FullDate) IN (1, 7) THEN 1 ELSE 0 END AS [IsWeekend],
		DATEPART(WEEK, dl.FullDate)                          AS [WeekOfYear],
		CASE WHEN DATEPART(QUARTER, dl.FullDate) <= 2 THEN 1 ELSE 2 END AS [Semester],
		CASE WHEN DATEPART(QUARTER, dl.FullDate) <= 2 THEN 'S1' ELSE 'S2' END AS [SemesterName]
	FROM @datelist dl
	LEFT JOIN [dbo].[DimDate] dd ON dl.FullDate = dd.[FullDate]
	WHERE dd.[FullDate] IS NULL;

	COMMIT TRANSACTION;

	SET IDENTITY_INSERT [dbo].[DimDate] OFF;
END
GO