IF NOT EXISTS(SELECT TOP(1) 1
              FROM [dbo].[DimDate])
 BEGIN
	BEGIN TRAN 
		DECLARE @startdate DATE = '1996-01-01',
				@enddate   DATE = '1999-12-31';
		DECLARE @datelist TABLE(FullDate DATE);

	IF @startdate IS NULL
		BEGIN
			SELECT TOP 1 
				   @startdate = FullDate
			FROM dbo.DimDate 
			ORDER BY DateKey ASC;
		END

	WHILE (@startdate <= @enddate)
	BEGIN 
		INSERT INTO @datelist(FullDate)
		SELECT @startdate

		SET @startdate = DATEADD(dd,1,@startdate);
	END

	 INSERT INTO dbo.DimDate(
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
			DateKey           = CONVERT(INT, CONVERT(VARCHAR, dl.FullDate, 112)),
			FullDate          = dl.FullDate,
			[Year]            = YEAR(dl.FullDate),
			[Quarter]         = DATEPART(QUARTER, dl.FullDate),
			[Month]           = MONTH(dl.FullDate),
			[Day]             = DAY(dl.FullDate),
			[MonthName]       = DATENAME(MONTH, dl.FullDate),
			[QuarterName]     = 'Q' + CAST(DATEPART(QUARTER, dl.FullDate) AS VARCHAR),
			[DayOfWeek]       = DATEPART(WEEKDAY, dl.FullDate) - 1,
			[DayName]         = DATENAME(WEEKDAY, dl.FullDate),
			[IsWeekend]       = CASE WHEN DATEPART(WEEKDAY, dl.FullDate) IN (1, 7) THEN 1 ELSE 0 END,
			[WeekOfYear]      = DATEPART(WEEK, dl.FullDate),
			[Semester]        = CASE WHEN DATEPART(QUARTER, dl.FullDate) <= 2 THEN 1 ELSE 2 END,
			[SemesterName]    = CASE WHEN DATEPART(QUARTER, dl.FullDate) <= 2 THEN 'S1' ELSE 'S2' END
	 FROM @datelist dl 
	 LEFT OUTER JOIN dbo.DimDate dd ON (dl.FullDate = dd.FullDate)
	 WHERE dd.FullDate IS NULL;
	COMMIT TRAN
END
GO