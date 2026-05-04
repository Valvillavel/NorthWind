
create view "Order Subtotals" AS
SELECT OrderDetails.OrderID, Sum(CONVERT(money,(OrderDetails.UnitPrice*Quantity*(1-Discount)/100))*100) AS Subtotal
FROM OrderDetails
GROUP BY OrderDetails.OrderID
