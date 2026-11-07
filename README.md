# Hospital Data Analysis | SQL Server

## Project Overview

This project focuses on analyzing hospital operational and financial data using Microsoft SQL Server (T-SQL).

The objective is to transform raw healthcare data into meaningful insights through data cleaning, data consolidation, SQL analysis, and business-focused queries.

The analysis explores patient visits, doctor performance, department revenue, treatment patterns, payment methods, and patient satisfaction.

## Business Objectives

- Clean and standardize patient and department records.
- Consolidate yearly patient visit datasets into one table.
- Analyze patient demographics and visit patterns.
- Evaluate revenue by department and payment method.
- Measure doctor performance and patient satisfaction.
- Identify common treatments for different diagnoses.
- Generate insights to support hospital operational and financial decisions.

## Database Structure

The project uses the following main tables:

| Table | Description |
|---|---|
| Dim_Patient | Patient demographic information |
| Dim_Doctor | Doctor information and experience |
| Dim_Department | Hospital department information |
| Dim_Diagnosis | Diagnosis categories |
| Dim_Treatment | Treatment information |
| Dim_PaymentMethod | Payment method categories |
| PatientVisits | Consolidated patient visit records |

The original patient visit data was provided across four tables covering 2020–2025:

- PatientVisits_2020_2021
- PatientVisits_2022_2023
- PatientVisits_2024
- PatientVisits_2025

These datasets were consolidated into a single PatientVisits table using UNION ALL.

## Data Cleaning & Preparation

Data cleaning was performed using SQL Server.

Key activities included:

### Patient Data Cleaning
- Removed patient records with missing first names.
- Standardized first and last names.
- Created a FullName column.
- Standardized gender values into Male and Female.
- Split CityStateCountry into City, State, and Country columns.

### Department Data Cleaning
- Removed departments with missing DepartmentCategory.
- Removed the HOD and original DepartmentName columns.
- Renamed Specialization to DepartmentName.

### Patient Visits Consolidation
- Merged four yearly patient visit tables into one consolidated PatientVisits table.
- Used UNION ALL to preserve all source records.

## SQL Analysis – Business Questions

The project addresses the following 10 business questions:

1. **Doctor Patient Volume:** How many distinct patients has each doctor treated?

2. **Revenue by Payment Method:** What is the revenue contribution and number of visits for each payment method?

3. **Patient Age Group Analysis:** What is the average bill amount for each patient age group, calculated at the time of visit?

4. **Department Revenue Analysis:** Which departments generate the highest revenue and handle the most visits?

5. **Department Revenue Ranking:** How do departments rank by total revenue within each department category?

6. **Patient Satisfaction & Waiting Time:** What are the average satisfaction scores and waiting times for each department?

7. **Weekday vs Weekend Visits:** How does hospital visit volume differ between weekdays and weekends?

8. **Monthly Visits & Cumulative Trends:** How many visits occur each month, and what is the running cumulative total?

9. **Doctor Satisfaction Ranking:** Which doctors have the highest average satisfaction scores, considering a minimum of 100 visits?

10. **Treatment Pattern Analysis:** What is the most commonly prescribed treatment for each diagnosis?

## Key Findings

The following findings are based on the SQL query results captured during the project:

### Patient Data Cleaning
- 2,431 patient records remained after cleaning.
- 1,402 Male patients.
- 1,029 Female patients.
- Patient names and location fields were standardized.

### Department Revenue
- Nuclear Medicine ranked first in total department revenue.
- Reported revenue: approximately 9.43 million.

### Doctor Satisfaction
- Dr. Kavita Malhotra ranked first among doctors meeting the minimum 100-visit requirement.
- Average satisfaction score: 3.75.
- Total visits: 102.

### Treatment Patterns
- Treatment frequency was analyzed for each diagnosis.
- Some diagnoses had multiple treatments tied for the highest frequency.

## SQL Skills Demonstrated

- Data Cleaning and Transformation
- SELECT, WHERE, GROUP BY, and HAVING
- INNER JOIN and LEFT JOIN
- UNION ALL
- Common Table Expressions (CTEs)
- Aggregate Functions: COUNT, SUM, AVG
- Window Functions: RANK, ROW_NUMBER, SUM OVER
- CASE WHEN Statements
- Date Functions: DATEDIFF, DATEADD, YEAR, MONTH, DATENAME
- Data Consolidation
- Business Intelligence and Healthcare Analytics

## Project Files

**SQL/**

Contains the database creation scripts, source data insertion scripts, data cleaning queries, and analysis queries.

**Screenshots/**

Contains screenshots of SQL Server query execution and selected analysis results.

## Tools Used

- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- T-SQL
- GitHub

## Project Repository

GitHub: https://github.com/abdurrahimdatapro-sketch/hospital-data-analysis

## Conclusion

This project demonstrates the application of SQL Server for healthcare data preparation and business analysis.

By combining data cleaning, data consolidation, relational joins, aggregations, and window functions, the project transforms raw hospital records into structured information that can support operational performance monitoring and data-driven decision-making.
