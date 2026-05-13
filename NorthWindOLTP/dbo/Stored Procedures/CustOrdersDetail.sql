
CREATE PROCEDURE CustOrdersDetail @OrderID int
AS
SELECT P.ProductName,
    UnitPrice      = ROUND(Od.UnitPrice, 2),
    Od.Quantity,
    Discount       = CONVERT(int, Od.Discount * 100), 
    ExtendedPrice  = ROUND(CONVERT(money, Od.Quantity * (1 - Od.Discount) * Od.UnitPrice), 2)
FROM [Order Details] AS Od
    INNER JOIN Products AS P ON Od.ProductID = P.ProductID
WHERE Od.OrderID = @OrderID
