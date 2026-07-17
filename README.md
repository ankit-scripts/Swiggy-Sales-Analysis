# Swiggy-Sales-Analysis
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
