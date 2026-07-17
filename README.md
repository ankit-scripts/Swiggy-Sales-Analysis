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
- ✅ No NULL values were found in any of the selected columns.
- ✅ The dataset is complete and ready for further data cleaning, transformation, and analysis.
  
<img width="1352" height="144" alt="image" src="https://github.com/user-attachments/assets/a4fad1f4-7a05-4ee2-89c1-31e9366e49e7" />
