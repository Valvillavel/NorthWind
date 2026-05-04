CREATE PROCEDURE [dbo].[DW_MergeDimProduct]
AS
BEGIN
	-- UPDATE: Registros existentes
	UPDATE dp
	SET 
		dp.[ProductName]          = sp.[ProductName],
		dp.[CategoryName]         = sp.[CategoryName],
		dp.[SupplierCompanyName]  = sp.[SupplierCompanyName],
		dp.[QuantityPerUnit]      = sp.[QuantityPerUnit],
		dp.[UnitPrice]            = sp.[UnitPrice],
		dp.[UnitsInStock]         = sp.[UnitsInStock],
		dp.[UnitsOnOrder]         = sp.[UnitsOnOrder],
		dp.[ReorderLevel]         = sp.[ReorderLevel],
		dp.[Discontinued]         = sp.[Discontinued],
		dp.[ModifiedDate]         = GETDATE()
	FROM [dbo].[DimProduct] dp
	INNER JOIN [staging].[Product] sp ON (dp.[ProductID] = sp.[ProductID])

	-- INSERT: Registros nuevos
	INSERT INTO [dbo].[DimProduct] (
		[ProductID], [ProductName], [CategoryName], [SupplierCompanyName],
		[QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder],
		[ReorderLevel], [Discontinued], [CreatedDate], [ModifiedDate]
	)
	SELECT 
		sp.[ProductID], sp.[ProductName], sp.[CategoryName], sp.[SupplierCompanyName],
		sp.[QuantityPerUnit], sp.[UnitPrice], sp.[UnitsInStock], sp.[UnitsOnOrder],
		sp.[ReorderLevel], sp.[Discontinued], GETDATE(), GETDATE()
	FROM [staging].[Product] sp
	LEFT JOIN [dbo].[DimProduct] dp ON (dp.[ProductID] = sp.[ProductID])
	WHERE dp.[ProductKey] IS NULL
END
GO