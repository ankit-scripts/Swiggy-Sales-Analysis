USE [Swiggy Database];

SELECT * FROM swiggy_data;

--Data Cleaning & Validation
--Null Value Check
SELECT 
      SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS "null state",
	  SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS "null city",
	  SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS "null order date",
	  SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS "null resturant name",
	  SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS "null location",
	  SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS "null category",
	  SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS "null dish name",
	  SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS "null price INR",
	  SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS "null rating",
	  SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS "null rating count"
FROM swiggy_data;


--Blank/Empty String Check
SELECT * 
FROM swiggy_data
WHERE 
     State = ' ' OR
	 City = ' ' OR 
	 Restaurant_Name = ' ' OR
	 Location = ' ' OR
	 Category = ' ' OR
	 Dish_Name = ' ';


--Duplicate Detection
SELECT 
      State, City, Order_Date, Restaurant_Name, Location,
	  Category, Dish_Name, Price_INR, Rating, Rating_Count,
	  COUNT(*) AS Duplicate_Count
FROM swiggy_data
GROUP BY 
      State, City, Order_Date, Restaurant_Name, Location,
	  Category, Dish_Name, Price_INR, Rating, Rating_Count
HAVING COUNT(*) > 1;


--Duplicate Removal
WITH CTE AS (
             SELECT *, ROW_NUMBER() OVER (
			 PARTITION BY State, City, Order_Date, Restaurant_Name, Location,
	         Category, Dish_Name, Price_INR, Rating, Rating_Count
			 ORDER BY (SELECT NULL))
AS Row_Num
FROM swiggy_data)
DELETE FROM CTE WHERE Row_Num > 1;


---CREATING SCHEMA
 
--Dimension Table
--Date Table
CREATE TABLE dim_date (
        Date_ID INT IDENTITY(1,1) PRIMARY KEY,
		Full_Date DATE,
		Year INT,
		Month INT,
		Month_Name VARCHAR(30),
		Quarter INT,
		Day INT,
		Week INT
);

--Dimension Location
CREATE TABLE dim_location(
        Location_ID INT IDENTITY(1,1) PRIMARY KEY,
		State VARCHAR(100),
		City VARCHAR(100),
		Location VARCHAR(200)
);

--Dimension Restaurant
CREATE TABLE dim_restaurant(
        Restaurant_ID INT IDENTITY(1,1) PRIMARY KEY,
		Restaurant_Name VARCHAR(200)
);

--Dimension Category
CREATE TABLE dim_category (
        Category_ID INT IDENTITY(1,1) PRIMARY KEY,
		Category_Name VARCHAR(200)
);

--Dimension Category
CREATE TABLE dim_dish (
        Dish_ID INT IDENTITY(1,1) PRIMARY KEY,
		Dish_Name VARCHAR(200)
);

--Fact Table
CREATE TABLE fact_swiggy_orders (
        Order_ID INT IDENTITY(1,1) PRIMARY KEY,

		Date_ID INT,
		Price_INR DECIMAL(10, 2),
		Rating DECIMAL(4,2),
		Rating_Count INT,

		Location_ID INT,
		Restaurant_ID INT,
		Category_ID INT,
		Dish_ID INT,

		FOREIGN KEY (Date_ID) REFERENCES dim_date(Date_ID),
		FOREIGN KEY (Location_ID) REFERENCES dim_location(Location_ID),
		FOREIGN KEY (Restaurant_ID) REFERENCES dim_restaurant(Restaurant_ID),
		FOREIGN KEY (Category_ID) REFERENCES dim_category(Category_ID),
		FOREIGN KEY (Dish_ID) REFERENCES dim_dish(Dish_ID)
);


--Insert Data in Tables
INSERT INTO dim_date (Full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT
           Order_Date,
		   YEAR(Order_Date),
		   MONTH(Order_Date),
		   DATENAME(MONTH, Order_Date),
		   DATEPART(QUARTER, Order_Date),
		   DAY(Order_Date),
		   DATEPART(WEEK, Order_Date)
FROM swiggy_data
WHERE Order_Date IS NOT NULL;

SELECT * FROM swiggy_data;

--Dim Location
INSERT INTO dim_location(State, City, Location)
SELECT DISTINCT
           State,
		   City,
		   Location
FROM swiggy_data;


--Dimension Restaurant
INSERT INTO dim_restaurant(Restaurant_Name)
SELECT DISTINCT
           Restaurant_Name
FROM swiggy_data;


--Dimension Category
INSERT INTO dim_category (Category_Name)
SELECT DISTINCT
    Category       
FROM swiggy_data;


--Dimension Dish
INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT
       Dish_Name    
FROM swiggy_data;

--Fact Table
INSERT INTO fact_swiggy_orders(
		Date_ID,
		Price_INR,
		Rating,
		Rating_Count,
		Location_ID,
		Restaurant_ID,
		Category_ID,
		Dish_ID
)
SELECT 
      dd.Date_ID,
	  s.Price_INR,
	  s.Rating,
	  s.Rating_Count,

	  dl.Location_ID,
      dr.Restaurant_ID,
      dc.Category_ID,
      dsh.Dish_ID
FROM swiggy_data AS s

JOIN dim_date  AS dd
     ON dd.Full_Date = s.Order_Date

JOIN dim_location AS dl
     ON dl.State = s.State
     AND dl.City = s.City
     AND dl.Location = s.Location

JOIN dim_restaurant AS dr
     ON dr.Restaurant_Name = s.Restaurant_Name

JOIN dim_category AS dc
     ON dc.Category_Name = s.Category

JOIN dim_dish AS dsh
     ON dsh.Dish_Name = s.Dish_Name;


SELECT * FROM fact_swiggy_orders AS f
  JOIN dim_date AS d ON f.Date_ID = d.Date_ID
  JOIN dim_location AS l ON f.Location_ID = l.Location_ID
  JOIN dim_restaurant AS r ON f.Restaurant_ID = r.Restaurant_ID
  JOIN dim_category AS c ON f.Category_ID = c.Category_ID
  JOIN dim_dish AS di ON f.Dish_ID = di.Dish_ID;


--KPI's

--Total Orders
SELECT COUNT(*) AS Total_Orders
FROM fact_swiggy_orders;


--Total Revenue (INR Million)
SELECT 
  FORMAT(SUM(CONVERT(FLOAT,Price_INR))/1000000, 'N2') + ' ' + 'INR Million' 
  AS Total_Revenue
FROM fact_swiggy_orders;


--Average Dish Price
SELECT 
  FORMAT(AVG(CONVERT(FLOAT,Price_INR)), 'N2') + ' ' + 'INR' 
  AS Average_Dish_Price
FROM fact_swiggy_orders;


--Average Rating
SELECT AVG(Rating) AS Average_Rating
FROM fact_swiggy_orders;


--Deep Dive Business Analysis
--Date Based Analysis

--Monthly order trends
SELECT
      d.Year,
      d.Month,
      d.Month_Name,
      COUNT(*) AS Total_Monthly_Orders
FROM fact_swiggy_orders f
  JOIN dim_date d ON f.date_id = d.date_id
GROUP BY 
      d.Year,
      d.Month,
      d.Month_Name
ORDER BY COUNT(*) DESC;


--Quarterly order trends
SELECT
      d.Year,
      d.Quarter,
      COUNT(*) AS Total_Quarterly_Orders
FROM fact_swiggy_orders f
  JOIN dim_date d ON f.date_id = d.date_id
GROUP BY 
      d.Year,
      d.Quarter
ORDER BY COUNT(*) DESC;


--Year-wise growth
SELECT
      d.Year,
      COUNT(*) AS Total_Yearly_Orders
FROM fact_swiggy_orders f
  JOIN dim_date d ON f.date_id = d.date_id
GROUP BY 
      d.Year
ORDER BY COUNT(*) DESC;


--Day of week patterns (Mon-Sun)
SELECT
      DATENAME(WEEKDAY, d.Full_date) AS Day_Name,
      COUNT(*) AS Orders_BY_Day_of_week
FROM fact_swiggy_orders f
  JOIN dim_date d ON f.date_id = d.date_id
GROUP BY 
      DATENAME(WEEKDAY, d.Full_date), 
	  DATEPART(WEEKDAY, d.Full_date) 
ORDER BY DATENAME(WEEKDAY, d.Full_date);


--Location-Based Analysis
--Top 10 cities by order volume
SELECT TOP 10
       dl.City,
	   COUNT(*) AS Top_Cities_by_Orders
FROM fact_swiggy_orders AS f
JOIN dim_location AS dl
ON dl.Location_ID = f.Location_ID
GROUP BY dl.City
ORDER BY COUNT(*) DESC; 


--Revenue contribution by states
SELECT
       dl.State,
	   SUM(f.Price_INR) AS Top_Revenue_States
FROM fact_swiggy_orders AS f
JOIN dim_location AS dl
ON dl.Location_ID = f.Location_ID
GROUP BY dl.State
ORDER BY SUM(f.Price_INR) DESC; 


--Food Performance
--Top 10 restaurants by orders
SELECT TOP 10
       r.Restaurant_Name,
	   SUM(f.Price_INR) AS Top_Restaurants_by_Orders
FROM fact_swiggy_orders AS f
JOIN dim_restaurant AS r
ON r.Restaurant_ID = f.Restaurant_ID
GROUP BY r.Restaurant_Name
ORDER BY SUM(f.Price_INR) DESC; 


--Top categories (Indian, Chinese, etc.)
SELECT 
       c.Category_Name,
	   COUNT(*) AS Top_Categories 
FROM fact_swiggy_orders AS f
JOIN dim_category AS c
ON c.Category_ID = f.Category_ID
GROUP BY  c.Category_Name
ORDER BY Top_Categories  DESC; 


--Most ordered dishes
SELECT 
       d.Dish_Name,
	   COUNT(*) AS Order_Count
FROM fact_swiggy_orders AS f
JOIN dim_dish AS d
ON d.Dish_ID = f.Dish_ID
GROUP BY  d.Dish_Name
ORDER BY Order_Count  DESC;


--Cuisine performance → Orders + Avg Rating
SELECT
    c.Category_ID,
    COUNT(*) AS total_orders,
    AVG(f.rating) AS avg_rating
FROM fact_swiggy_orders AS f
JOIN dim_category AS c 
ON f.Category_ID = c.Category_ID
GROUP BY c.Category_ID
ORDER BY total_orders DESC;


--Total Orders by Price Range
SELECT 
     CASE 
	     WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Under 100'
		 WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100 - 199'
		 WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200 - 299'
		 WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300 - 499'
		 ELSE '500+'
     END AS Price_Range,
     COUNT(*) AS Total_Orders
FROM fact_swiggy_orders
GROUP BY 
     CASE 
	     WHEN CONVERT(FLOAT, Price_INR) < 100 THEN 'Under 100'
		 WHEN CONVERT(FLOAT, Price_INR) BETWEEN 100 AND 199 THEN '100 - 199'
		 WHEN CONVERT(FLOAT, Price_INR) BETWEEN 200 AND 299 THEN '200 - 299'
		 WHEN CONVERT(FLOAT, Price_INR) BETWEEN 300 AND 499 THEN '300 - 499'
		 ELSE '500+'
    END
ORDER BY Total_Orders DESC; 


--Ratings Count Distribution (1–5)
SELECT
      Rating,
	  COUNT(*) AS Total_Ratings
FROM fact_swiggy_orders
GROUP BY Rating
ORDER BY Rating DESC;

