--Q1. For each doctor, count how many distinct patients they have treated.


SELECT d.DoctorID,
       CONCAT_WS(' ', d.FirstName, d.LastName) AS Doctor_Name,
       COUNT(DISTINCT v.PatientID)             AS Distinct_Patients
FROM Dim_Doctor d
LEFT JOIN PatientVisits v ON v.DoctorID = d.DoctorID
GROUP BY d.DoctorID, d.FirstName, d.LastName
ORDER BY Distinct_Patients DESC, d.DoctorID;


--Q2. Show the revenue split by each payment method, along with total visits.


SELECT pm.PaymentMethod,
       COUNT(v.VisitID)                                        AS Total_Visits,
       COALESCE(SUM(v.BillAmount), 0)                          AS Total_Revenue,
       CAST(100.0 * SUM(v.BillAmount)
            / SUM(SUM(v.BillAmount)) OVER () AS DECIMAL(5,2))  AS Pct_of_Revenue,
       CAST(AVG(v.BillAmount) AS DECIMAL(18,2))                AS Avg_Bill_Per_Visit
FROM Dim_PaymentMethod pm
LEFT JOIN PatientVisits v ON v.PaymentMethodID = pm.PaymentMethodID
GROUP BY pm.PaymentMethodID, pm.PaymentMethod
ORDER BY Total_Revenue DESC;



--Q3. Categorize patients into age groups and calculate the average bill amount for each age band.(Assume age at time of visit based on VisitDate.)


WITH visit_ages AS (
    SELECT v.VisitID,
           v.BillAmount,
           DATEDIFF(YEAR, p.DOB, v.VisitDate)
             - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, p.DOB, v.VisitDate), p.DOB) > v.VisitDate
                    THEN 1 ELSE 0 END AS Age_At_Visit
    FROM PatientVisits v
    JOIN Dim_Patient p ON p.PatientID = v.PatientID
),
banded AS (
    SELECT BillAmount,
           CASE
               WHEN Age_At_Visit < 18 THEN '0-17'
               WHEN Age_At_Visit < 35 THEN '18-34'
               WHEN Age_At_Visit < 50 THEN '35-49'
               WHEN Age_At_Visit < 65 THEN '50-64'
               ELSE '65+'
           END AS Age_Band,
           CASE
               WHEN Age_At_Visit < 18 THEN 1
               WHEN Age_At_Visit < 35 THEN 2
               WHEN Age_At_Visit < 50 THEN 3
               WHEN Age_At_Visit < 65 THEN 4
               ELSE 5
           END AS Band_Order
    FROM visit_ages
)
SELECT Age_Band,
       COUNT(*)                              AS Total_Visits,
       CAST(AVG(BillAmount) AS DECIMAL(18,2)) AS Avg_Bill_Amount
FROM banded
GROUP BY Age_Band, Band_Order
ORDER BY Band_Order;


--Q4. Find total revenue and number of visits for each department.


SELECT d.DepartmentID,
       d.DepartmentName,
       d.DepartmentCategory,
       COUNT(v.VisitID)                       AS Total_Visits,
       COALESCE(SUM(v.BillAmount), 0)         AS Total_Revenue
FROM Dim_Department d
LEFT JOIN PatientVisits v ON v.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentID, d.DepartmentName, d.DepartmentCategory
ORDER BY Total_Revenue DESC;


--Q5. Rank departments based on their total revenue within each department category.


WITH dept_revenue AS (
    SELECT d.DepartmentID,
           d.DepartmentCategory,
           d.DepartmentName,
           COUNT(v.VisitID)               AS Total_Visits,
           COALESCE(SUM(v.BillAmount), 0) AS Total_Revenue
    FROM Dim_Department d
    LEFT JOIN PatientVisits v ON v.DepartmentID = d.DepartmentID
    GROUP BY d.DepartmentID, d.DepartmentCategory, d.DepartmentName
)
SELECT DepartmentCategory,
       RANK() OVER (PARTITION BY DepartmentCategory
                    ORDER BY Total_Revenue DESC)                 AS Rank_In_Category,
       DepartmentName,
       Total_Visits,
       Total_Revenue,
       CAST(100.0 * Total_Revenue
            / SUM(Total_Revenue) OVER (PARTITION BY DepartmentCategory)
            AS DECIMAL(5,1))                                     AS Pct_of_Category_Revenue
FROM dept_revenue
ORDER BY DepartmentCategory, Rank_In_Category;


--Q6. For each department, find the average satisfaction score and average wait time.


SELECT d.DepartmentID,
       d.DepartmentName,
       COUNT(v.VisitID)                                         AS Total_Visits,
       CAST(AVG(CAST(v.SatisfactionScore AS DECIMAL(10,2))) AS DECIMAL(5,2)) AS Avg_Satisfaction_Score,
       CAST(AVG(CAST(v.WaitTimeMinutes   AS DECIMAL(10,2))) AS DECIMAL(6,1)) AS Avg_Wait_Time_Minutes
FROM Dim_Department d
LEFT JOIN PatientVisits v ON v.DepartmentID = d.DepartmentID
GROUP BY d.DepartmentID, d.DepartmentName
ORDER BY Avg_Satisfaction_Score DESC;


--Q7. Compare the total number of hospital visits on weekdays vs weekends.


WITH classified AS (
    SELECT VisitID,
           VisitDate,
           CASE WHEN DATENAME(WEEKDAY, VisitDate) IN ('Saturday', 'Sunday')
                THEN 'Weekend' ELSE 'Weekday' END AS Day_Type
    FROM PatientVisits
)
SELECT Day_Type,
       COUNT(*)                                                      AS Total_Visits,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS Pct_of_Visits,
       COUNT(DISTINCT VisitDate)                                     AS Days_With_Visits,
       CAST(1.0 * COUNT(*) / COUNT(DISTINCT VisitDate) AS DECIMAL(5,2)) AS Avg_Visits_Per_Day
FROM classified
GROUP BY Day_Type
ORDER BY Day_Type;


--Q8. For each month, calculate total visits and a running cumulative total of visits.


WITH monthly AS (
    SELECT DATEFROMPARTS(YEAR(VisitDate), MONTH(VisitDate), 1) AS Month_Start,
           COUNT(*) AS Total_Visits
    FROM PatientVisits
    GROUP BY DATEFROMPARTS(YEAR(VisitDate), MONTH(VisitDate), 1)
)
SELECT FORMAT(Month_Start, 'yyyy-MM') AS Visit_Month,
       Total_Visits,
       SUM(Total_Visits) OVER (ORDER BY Month_Start
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Cumulative_Visits
FROM monthly
ORDER BY Month_Start;


--Q9. Find the doctors with the highest average satisfaction score (minimum 100 visits).


SELECT RANK() OVER (ORDER BY AVG(CAST(v.SatisfactionScore AS DECIMAL(10,2))) DESC) AS Rank_No,
       d.DoctorID,
       CONCAT_WS(' ', d.FirstName, d.LastName)                                       AS Doctor_Name,
       COUNT(*)                                                                      AS Total_Visits,
       CAST(AVG(CAST(v.SatisfactionScore AS DECIMAL(10,2))) AS DECIMAL(4,2))         AS Avg_Satisfaction_Score
FROM Dim_Doctor d
JOIN PatientVisits v ON v.DoctorID = d.DoctorID
GROUP BY d.DoctorID, d.FirstName, d.LastName
HAVING COUNT(*) >= 100
ORDER BY Avg_Satisfaction_Score DESC;


--Q10. Identify the most commonly prescribed treatment for each diagnosis.


WITH treatment_counts AS (
    SELECT dg.DiagnosisID,
           dg.DiagnosisName,
           t.TreatmentID,
           t.TreatmentName,
           COUNT(*) AS Times_Prescribed
    FROM PatientVisits v
    JOIN Dim_Diagnosis dg ON dg.DiagnosisID = v.DiagnosisID
    JOIN Dim_Treatment t  ON t.TreatmentID  = v.TreatmentID
    GROUP BY dg.DiagnosisID, dg.DiagnosisName, t.TreatmentID, t.TreatmentName
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY DiagnosisID ORDER BY Times_Prescribed DESC) AS rnk,
           SUM(Times_Prescribed) OVER (PARTITION BY DiagnosisID)                 AS Diagnosis_Visits
    FROM treatment_counts
)
SELECT DiagnosisID,
       DiagnosisName,
       TreatmentName AS Most_Common_Treatment,
       Times_Prescribed,
       CAST(100.0 * Times_Prescribed / Diagnosis_Visits AS DECIMAL(5,1)) AS Pct_of_Diagnosis_Visits
FROM ranked
WHERE rnk = 1
ORDER BY DiagnosisID, Most_Common_Treatment;