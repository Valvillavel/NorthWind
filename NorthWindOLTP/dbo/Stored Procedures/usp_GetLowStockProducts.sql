CREATE PROCEDURE [dbo].[usp_GetLowStockProducts]
    @ReorderThreshold INT = NULL
AS
/*
================================================================================
 Procedure: usp_GetLowStockProducts
 Purpose:   Returns products at or below reorder level.
            If @ReorderThreshold is NULL, uses each product's own ReorderLevel.
================================================================================
*/
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.[ProductID],
        p.[ProductName],
        cat.[CategoryName],
        sup.[CompanyName]   AS [SupplierName],
        p.[UnitsInStock],
        p.[UnitsOnOrder],
        p.[ReorderLevel],
        p.[Discontinued]
    FROM [dbo].[Products]    p
    LEFT JOIN [dbo].[Categories] cat ON p.[CategoryID]  = cat.[CategoryID]
    LEFT JOIN [dbo].[Suppliers]  sup ON p.[SupplierID]  = sup.[SupplierID]
    WHERE p.[Discontinued] = 0
      AND (
            (@ReorderThreshold IS NULL AND p.[UnitsInStock] <= p.[ReorderLevel])
         OR (@ReorderThreshold IS NOT NULL AND p.[UnitsInStock] <= @ReorderThreshold)
          )
    ORDER BY p.[UnitsInStock] ASC, p.[ProductName];
END
GO
