CREATE PROCEDURE GetDates
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON

    SELECT [FullDate],
        YEAR(FullDate) as [Year],
        DATEPART(QUARTER, FullDate) as [Quarter],
        MONTH(FullDate) as [Month],
        DAY(FullDate) as [Day],
        DATENAME(MONTH, FullDate) as [MonthName],
        'Q' + CAST(DATEPART(QUARTER, FullDate) AS NVARCHAR(10)) as [QuarterName],
        DATEPART(WEEKDAY, FullDate) as [DayOfWeek],
        CAST(DATENAME(WEEKDAY, FullDate) AS NVARCHAR(20)) as [DayName],
        CASE WHEN DATEPART(WEEKDAY, FullDate) IN (1, 7) THEN 1 ELSE 0 END as [IsWeekend],
        DATEPART(WEEK, FullDate) as [WeekOfYear],
        CASE WHEN DATEPART(MONTH, FullDate) <= 6 THEN 1 ELSE 2 END as [Semester],
        CASE WHEN DATEPART(MONTH, FullDate) <= 6 THEN CAST('H1' AS NVARCHAR(10)) ELSE CAST('H2' AS NVARCHAR(10)) END as [SemesterName],
        0 as [IsHoliday],
        NULL as [HolidayName]
    FROM (
	    SELECT DISTINCT CAST(t.OrderDate AS DATE) as [FullDate]
	    FROM [dbo].[Orders] t
	    UNION
	    SELECT DISTINCT CAST(t.RequiredDate AS DATE) as [FullDate]
	    FROM [dbo].[Orders] t
	    UNION
	    SELECT DISTINCT CAST(t.ShippedDate AS DATE) as [FullDate]
	    FROM [dbo].[Orders] t
    ) AS Dates
    WHERE [FullDate] IS NOT NULL
    ORDER BY [FullDate];
END