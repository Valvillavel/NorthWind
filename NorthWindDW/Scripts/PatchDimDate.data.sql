SET IDENTITY_INSERT [dbo].[DimDate] ON;

IF NOT EXISTS(SELECT TOP(1) 1
			  FROM [dbo].[DimDate]
			  WHERE [DateKey] = 0)
BEGIN
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
	VALUES (
		0,
		GETDATE(),
		1900,
		1,
		1,
		1,
		'Unknown',
		'Q1',
		0,
		'Unknown',
		0,
		1,
		1,
		'S1'
	);
END

SET IDENTITY_INSERT [dbo].[DimDate] OFF;
GO