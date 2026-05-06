CREATE PROCEDURE [dbo].[DW_MergeDimCustomer]
AS
BEGIN
	-- UPDATE: Registros existentes
	UPDATE dc
	SET 
		dc.[CompanyName]    = sc.[CompanyName],
		dc.[ContactName]    = sc.[ContactName],
		dc.[ContactTitle]   = sc.[ContactTitle],
		dc.[Address]        = sc.[Address],
		dc.[City]           = sc.[City],
		dc.[Region]         = sc.[Region],
		dc.[PostalCode]     = sc.[PostalCode],
		dc.[Country]        = sc.[Country],
		dc.[Phone]          = sc.[Phone],
		dc.[Fax]            = sc.[Fax],
		dc.[CustomerDesc]   = sc.[CustomerDesc],
		dc.[ModifiedDate]   = GETDATE()
	FROM [dbo].[DimCustomer] dc
	INNER JOIN [staging].[Customer] sc ON (dc.[CustomerID] = sc.[CustomerID])

	-- INSERT: Registros nuevos
	INSERT INTO [dbo].[DimCustomer] (
		[CustomerID], [CompanyName], [ContactName], [ContactTitle],
		[Address], [City], [Region], [PostalCode], [Country],
		[Phone], [Fax], [CustomerDesc], [ValidFrom], [ValidTo],
		[IsCurrent], [CreatedDate], [ModifiedDate]
	)
	SELECT 
		sc.[CustomerID], sc.[CompanyName], sc.[ContactName], sc.[ContactTitle],
		sc.[Address], sc.[City], sc.[Region], sc.[PostalCode], sc.[Country],
		sc.[Phone], sc.[Fax], sc.[CustomerDesc], GETDATE(), NULL,
		1, GETDATE(), GETDATE()
	FROM [staging].[Customer] sc
	LEFT JOIN [dbo].[DimCustomer] dc ON (dc.[CustomerID] = sc.[CustomerID])
	WHERE dc.[CustomerKey] IS NULL
END
GO