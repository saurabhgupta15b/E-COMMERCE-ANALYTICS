Question 14:- 1. Identify the top 5 most valuable customers using a composite score that combines three key metrics: (SQL)
				1. Total Revenue (50% weight): The total amount of money spent by the customer.
                2. Order Frequency (30% weight): The number of orders placed by the customer, indicating their loyalty and engagement.
                3. Average Order Value (20% weight): The average value of each order placed by the customer, reflecting the typical transaction size.
USE ecommerce;
WITH CustomerMetrics AS (
    SELECT
        CustomerID,
        SUM(SalePrice) AS TotalRevenue,
        COUNT(DISTINCT OrderID) AS OrderFrequency,
        AVG(SalePrice) AS AverageOrderValue
    FROM Orders
    GROUP BY CustomerID
),

NormalizedMetrics AS (
    SELECT
        CustomerID,
        TotalRevenue,
        OrderFrequency,
        AverageOrderValue,

        (TotalRevenue -
            MIN(TotalRevenue) OVER()) /
        NULLIF(MAX(TotalRevenue) OVER() -
            MIN(TotalRevenue) OVER(),0) AS RevenueScore,

        (OrderFrequency -
            MIN(OrderFrequency) OVER()) /
        NULLIF(MAX(OrderFrequency) OVER() -
            MIN(OrderFrequency) OVER(),0) AS FrequencyScore,

        (AverageOrderValue -
            MIN(AverageOrderValue) OVER()) /
        NULLIF(MAX(AverageOrderValue) OVER() -
            MIN(AverageOrderValue) OVER(),0) AS AOVScore

    FROM CustomerMetrics
)

SELECT
    CustomerID,
    TotalRevenue,
    OrderFrequency,
    ROUND(AverageOrderValue,2) AS AverageOrderValue,

    ROUND(
        (RevenueScore * 0.50) +
        (FrequencyScore * 0.30) +
        (AOVScore * 0.20),
        4
    ) AS CompositeScore,

    RANK() OVER(
        ORDER BY
        (RevenueScore * 0.50) +
        (FrequencyScore * 0.30) +
        (AOVScore * 0.20) DESC
    ) AS CustomerRank

FROM NormalizedMetrics

ORDER BY CompositeScore DESC

LIMIT 5;
   
Question 15:- Calculate the month-over-month growth rate in total revenue across the entire dataset. (SQL)

WITH MonthlyRevenue AS (
    SELECT
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        SUM(SalePrice) AS TotalRevenue
    FROM Orders
    GROUP BY
        YEAR(OrderDate),
        MONTH(OrderDate)
)

SELECT
    Year,
    Month,
    TotalRevenue,
    LAG(TotalRevenue) OVER(
        ORDER BY Year, Month
    ) AS PreviousMonthRevenue,

    ROUND(
        (
            (TotalRevenue -
            LAG(TotalRevenue) OVER(
                ORDER BY Year, Month
            ))
            /
            LAG(TotalRevenue) OVER(
                ORDER BY Year, Month
            )
        ) * 100,
        2
    ) AS MoM_Growth_Percentage

FROM MonthlyRevenue
ORDER BY
    Year,
    Month;

Question 16:-Calculate the rolling 3-month average revenue for each product category. 

WITH MonthlyRevenue AS
(
    SELECT
        ProductCategory,
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        SUM(SalePrice) AS MonthlyRevenue
    FROM Orders
    GROUP BY
        ProductCategory,
        YEAR(OrderDate),
        MONTH(OrderDate)
)

SELECT
    ProductCategory,
    Year,
    Month,
    MonthlyRevenue,

    ROUND(
        AVG(MonthlyRevenue) OVER(
            PARTITION BY ProductCategory
            ORDER BY Year, Month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS Rolling_3_Month_Average

FROM MonthlyRevenue

ORDER BY
ProductCategory,
Year,
Month;

Question 17:-Update the orders table to apply a 15% discount on the `Sale Price` for orders placed by customers who have made at least 10 orders. 
1: Identify Eligible Customers

SELECT 
 CustomerID,
 COUNT(DISTINCT OrderID) AS OrderCount 
FROM Orders 
GROUP BY CustomerID 
HAVING COUNT(DISTINCT OrderID) >= 10;

2: Apply the 15% Discount

UPDATE Orders
SET SalePrice = SalePrice * 0.85
WHERE CustomerID IN
(
    SELECT CustomerID
    FROM
    (
        SELECT
            CustomerID
        FROM Orders
        GROUP BY CustomerID
        HAVING COUNT(DISTINCT OrderID) >= 10
    ) AS EligibleCustomers
);

3: Verify the Updated Records

SELECT
    OrderID,
    CustomerID,
    SalePrice
FROM Orders
WHERE CustomerID IN
(
    SELECT CustomerID
    FROM
    (
        SELECT
            CustomerID
        FROM Orders
        GROUP BY CustomerID
        HAVING COUNT(DISTINCT OrderID) >= 10
    ) AS EligibleCustomers
);

Question 18:- Calculate the average number of days between consecutive orders for customers who have placed at least five orders. 
1: Find customers with at least 5 orders

SELECT
    CustomerID,
    COUNT(DISTINCT OrderID) AS OrderCount
FROM Orders
GROUP BY CustomerID
HAVING COUNT(DISTINCT OrderID) >= 5;

Step 2: Calculate the average days between consecutive orders

WITH EligibleCustomers AS
(
    SELECT
        CustomerID
    FROM Orders
    GROUP BY CustomerID
    HAVING COUNT(DISTINCT OrderID) >= 5
),

ConsecutiveOrders AS
(
    SELECT
        o.CustomerID,
        o.OrderID,
        o.`OrderDate`,
        LAG(o.`OrderDate`) OVER
        (
            PARTITION BY o.CustomerID
            ORDER BY o.`OrderDate`, o.OrderID
        ) AS PreviousOrderDate
    FROM Orders o
    INNER JOIN EligibleCustomers e
        ON o.CustomerID = e.CustomerID
),

OrderGaps AS
(
    SELECT
        CustomerID,
        DATEDIFF(`OrderDate`, PreviousOrderDate) AS DaysBetweenOrders
    FROM ConsecutiveOrders
    WHERE PreviousOrderDate IS NOT NULL
)

SELECT
    CustomerID,
    ROUND(AVG(DaysBetweenOrders), 2) AS AverageDaysBetweenOrders
FROM OrderGaps
GROUP BY CustomerID
ORDER BY AverageDaysBetweenOrders;

Question:19:-Identify customers who have generated revenue that is more than 30 % higher than the average revenue per customer. 

WITH CustomerRevenue AS
(
    SELECT
        CustomerID,
        SUM(`Sale Price`) AS TotalRevenue
    FROM Orders
    GROUP BY CustomerID
)

SELECT
    CustomerID,
    TotalRevenue
FROM CustomerRevenue
WHERE TotalRevenue >
(
    SELECT AVG(TotalRevenue) * 1.30
    FROM CustomerRevenue
)
ORDER BY TotalRevenue DESC;

Question:20:-Determine the top 3 product categories that have shown the highest increase in sales over the past year compared to the previous year. 
SELECT
    ProductCategory,

    SUM(
        CASE
            WHEN YEAR(OrderDate) = 2019
            THEN SalePrice
            ELSE 0
        END
    ) AS Sales_2019,

    SUM(
        CASE
            WHEN YEAR(OrderDate) = 2020
            THEN SalePrice
            ELSE 0
        END
    ) AS Sales_2020,

    SUM(
        CASE
            WHEN YEAR(OrderDate) = 2020
            THEN SalePrice
            ELSE 0
        END
    )
    -
    SUM(
        CASE
            WHEN YEAR(OrderDate) = 2019
            THEN SalePrice
            ELSE 0
        END
    ) AS Sales_Increase

FROM Orders

WHERE YEAR(OrderDate) IN (2019, 2020)

GROUP BY ProductCategory

ORDER BY Sales_Increase DESC

LIMIT 3;





