# Swiggy Sales Analysis
Designed a dimensional data model (Star Schema) and used CTEs, Window Functions, Aggregate Functions, and Joins to clean data and generate business insights on sales, customer behavior, restaurant performance, and ratings.

## Data Cleaning & Validation

### Null Value Check

**Objective:**  
The first step in the data cleaning process was to verify the dataset for missing (NULL) values across all key columns to ensure data completeness before performing any analysis.

**Approach:**  
Used conditional aggregation with `SUM(CASE WHEN ... IS NULL THEN 1 ELSE 0 END)` to count NULL values in each field, including State, City, Order Date, Restaurant Name, Location, Category, Dish Name, Price, Rating, and Rating Count.

```sql
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
```

**Findings:**  
- No NULL values were found in any of the selected columns.
- The dataset is complete and ready for further data cleaning, transformation, and analysis.
  
<img width="1352" height="144" alt="image" src="https://github.com/user-attachments/assets/a4fad1f4-7a05-4ee2-89c1-31e9366e49e7" />

----------------------------------------

### Blank/Empty String Check

**Objective:**  
Verify all dimension columns for blank or empty string (`' '`) values that could lead to inaccurate reporting, incorrect filtering, or inconsistent analysis. This validation focuses only on **dimension attributes** (State, City, Restaurant Name, Location, Category, and Dish Name).

**Approach:**  
Queried the dataset to identify records where any of the dimension columns contained blank or empty string values using the `WHERE` clause with `OR` conditions.

```sql
SELECT * 
FROM swiggy_data
WHERE 
     State = ' ' OR
	 City = ' ' OR 
	 Restaurant_Name = ' ' OR
	 Location = ' ' OR
	 Category = ' ' OR
	 Dish_Name = ' ';
```
<img width="1080" height="138" alt="image" src="https://github.com/user-attachments/assets/b263f8b9-db4f-4c5e-a88b-cf5b79ab668b" />

**Measure columns** (such as Price, Rating, and Rating Count) are not included in this check because blank string validation is applicable only to text-based fields.

**Findings:**  
- No blank or empty string values were detected in any of the dimension columns.
- All dimension attributes are complete and suitable for accurate filtering, grouping, and analysis.

  ----------------------------------------

### Duplicate Detection

**Objective:**  
Identify duplicate records by comparing all columns to ensure data integrity and prevent duplicate transactions from impacting aggregations, reporting, and analytical results.

**Approach:**  
Grouped the dataset by all key business attributes (`State`, `City`, `Order_Date`, `Restaurant_Name`, `Location`, `Category`, `Dish_Name`, `Price_INR`, `Rating`, and `Rating_Count`) and used `COUNT(*)` with a `HAVING COUNT(*) > 1` clause to detect records appearing more than once.

```sql
SELECT 
      State, City, Order_Date, Restaurant_Name, Location,
	  Category, Dish_Name, Price_INR, Rating, Rating_Count,
	  COUNT(*) AS Duplicate_Count
FROM swiggy_data
GROUP BY 
      State, City, Order_Date, Restaurant_Name, Location,
	  Category, Dish_Name, Price_INR, Rating, Rating_Count
HAVING COUNT(*) > 1;
```
<img width="2374" height="894" alt="image" src="https://github.com/user-attachments/assets/8629f16f-6948-4397-9b7c-5881ced1b59a" />

**Findings:**  
- **29 duplicate records** were identified in the dataset.
- These duplicate records require further investigation to determine whether they represent legitimate repeated orders or unintended duplicate entries before proceeding with data modeling and analysis.

----------------------------------------


### Duplicate Removal

**Objective:**  
Remove redundant duplicate records while preserving a single valid instance of each unique record. This ensures data consistency and prevents duplicate entries from inflating analytical results.

**Approach:**  
Created a Common Table Expression (CTE) and assigned a unique sequence number to each record using the `ROW_NUMBER()` window function. The rows were partitioned by all columns (`State`, `City`, `Order_Date`, `Restaurant_Name`, `Location`, `Category`, `Dish_Name`, `Price_INR`, `Rating`, and `Rating_Count`). Records with `Row_Num > 1` were identified as duplicates and deleted, retaining only the first occurrence of each unique record.

```sql
WITH CTE AS (
             SELECT *, ROW_NUMBER() OVER (
			 PARTITION BY State, City, Order_Date, Restaurant_Name, Location,
	         Category, Dish_Name, Price_INR, Rating, Rating_Count
			 ORDER BY (SELECT NULL))
AS Row_Num
FROM swiggy_data)
DELETE FROM CTE WHERE Row_Num > 1;
```

**Findings:**  
- **29 duplicate rows** were successfully removed from the dataset.
- **One unique record was retained** for each duplicated group, eliminating redundant data while preserving all distinct records.
- The dataset is now free of duplicate entries and ready for reliable data modeling and analysis.

----------------------------------------


## Dimensional Modelling (Star Schema)

**Objective:**  
Design and implement a **Star Schema** to optimize analytical query performance, improve data organization, and support scalable reporting. The model separates descriptive attributes into **dimension tables** and stores measurable business metrics in a centralized **fact table**, reducing data redundancy and enabling efficient joins, aggregations, and dashboard development.

The schema consists of the following tables:

- **Dimension Tables**
  - `dim_date` → Date attributes (Year, Month, Quarter, Week, Day)
  - `dim_location` → State, City, Location
  - `dim_restaurant` → Restaurant Name
  - `dim_category` → Food Category/Cuisine
  - `dim_dish` → Dish Name

- **Fact Table**
  - `fact_swiggy_orders` → Stores business measures (`Price_INR`, `Rating`, `Rating_Count`) along with foreign keys referencing each dimension table.

---

**Approach:**

Created all dimension tables using **IDENTITY(1,1)** to generate surrogate primary keys, ensuring unique identifiers for every dimension record. These surrogate keys are used as foreign keys in the fact table, improving join performance and maintaining referential integrity. The fact table stores transactional measures while linking to the corresponding dimension records through foreign key relationships, forming a complete Star Schema optimized for BI and analytical workloads.

```sql
-- ==========================
-- Dimension Tables
-- ==========================

-- Date Dimension
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

-- Location Dimension
CREATE TABLE dim_location (
    Location_ID INT IDENTITY(1,1) PRIMARY KEY,
    State VARCHAR(100),
    City VARCHAR(100),
    Location VARCHAR(200)
);

-- Restaurant Dimension
CREATE TABLE dim_restaurant (
    Restaurant_ID INT IDENTITY(1,1) PRIMARY KEY,
    Restaurant_Name VARCHAR(200)
);

-- Category Dimension
CREATE TABLE dim_category (
    Category_ID INT IDENTITY(1,1) PRIMARY KEY,
    Category_Name VARCHAR(200)
);

-- Dish Dimension
CREATE TABLE dim_dish (
    Dish_ID INT IDENTITY(1,1) PRIMARY KEY,
    Dish_Name VARCHAR(200)
);

-- ==========================
-- Fact Table
-- ==========================

CREATE TABLE fact_swiggy_orders (
    Order_ID INT IDENTITY(1,1) PRIMARY KEY,

    Date_ID INT,
    Price_INR DECIMAL(10,2),
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
```

**Findings:**

- Implemented a **Star Schema** consisting of **5 dimension tables** and **1 fact table**.
- Generated surrogate keys using `IDENTITY(1,1)` for efficient joins and simplified key management.
- Established foreign key relationships to maintain referential integrity between dimensions and the fact table.
- Created a scalable, normalized data model that improves query performance and supports efficient reporting and dashboard development.
  
  ----------------------------------------


