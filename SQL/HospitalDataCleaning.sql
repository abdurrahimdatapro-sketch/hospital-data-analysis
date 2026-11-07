/* =====================================================================
   HOSPITAL DATA ANALYSIS | Data Cleaning: Dim_Patient
   Target: Microsoft SQL Server (T-SQL)
   ===================================================================== */

-- 0) Safety backup before changing anything
SELECT * INTO Dim_Patient_Backup FROM Dim_Patient;
GO

-- 1) Remove patient rows where FirstName is missing
DELETE FROM Dim_Patient
WHERE FirstName IS NULL
   OR TRIM(FirstName) = '';
GO

-- 2) Standardize names to proper case and create FullName
UPDATE p
SET FirstName = UPPER(LEFT(f.v, 1)) + LOWER(SUBSTRING(f.v, 2, LEN(f.v))),
    LastName  = UPPER(LEFT(l.v, 1)) + LOWER(SUBSTRING(l.v, 2, LEN(l.v)))
FROM Dim_Patient p
CROSS APPLY (SELECT TRIM(p.FirstName) AS v) f
CROSS APPLY (SELECT TRIM(p.LastName)  AS v) l;
GO

ALTER TABLE Dim_Patient ADD FullName VARCHAR(101);
GO

UPDATE Dim_Patient
SET FullName = CONCAT_WS(' ', FirstName, LastName);
GO

-- 3) Gender must be Male or Female
UPDATE Dim_Patient
SET Gender = CASE
                 WHEN UPPER(TRIM(Gender)) IN ('M', 'MALE')   THEN 'Male'
                 WHEN UPPER(TRIM(Gender)) IN ('F', 'FEMALE') THEN 'Female'
                 ELSE Gender
             END;
GO

-- 4) Split CityStateCountry into City, State, Country
ALTER TABLE Dim_Patient ADD City VARCHAR(50), State VARCHAR(50), Country VARCHAR(50);
GO

UPDATE p
SET City    = TRIM(LEFT(p.CityStateCountry, x.p1 - 1)),
    State   = TRIM(SUBSTRING(p.CityStateCountry, x.p1 + 1, x.p2 - x.p1 - 1)),
    Country = TRIM(SUBSTRING(p.CityStateCountry, x.p2 + 1, LEN(p.CityStateCountry)))
FROM Dim_Patient p
CROSS APPLY (SELECT CHARINDEX(',', p.CityStateCountry) AS p1,
                    CHARINDEX(',', p.CityStateCountry,
                              CHARINDEX(',', p.CityStateCountry) + 1) AS p2) x
WHERE x.p1 > 0 AND x.p2 > 0;
GO

-- 5) Verify the result
SELECT COUNT(*) AS Total_Rows FROM Dim_Patient;
SELECT Gender, COUNT(*) AS Patients FROM Dim_Patient GROUP BY Gender;
SELECT TOP 10 PatientID, FirstName, LastName, FullName, Gender, City, State, Country FROM Dim_Patient;



-- Data Cleaning (Department Table)
---- Remove departments where DepartmentCategory is missing
---- Drop HOD and DepartmentName columns
---- Use Specialization as DepartmentName column

/* =====================================================================
   HOSPITAL DATA ANALYSIS | Data Cleaning: Dim_Department
   Target: Microsoft SQL Server (T-SQL)
   ===================================================================== */

-- 0) Safety backup before changing anything
SELECT * INTO Dim_Department_Backup FROM Dim_Department;
GO

-- 1) Remove departments where DepartmentCategory is missing
DELETE FROM Dim_Department
WHERE DepartmentCategory IS NULL
   OR TRIM(DepartmentCategory) = '';
GO

-- 2) Drop the HOD and DepartmentName columns
ALTER TABLE Dim_Department DROP COLUMN HOD, DepartmentName;
GO

-- 3) Use Specialization as the DepartmentName column
EXEC sp_rename 'Dim_Department.Specialization', 'DepartmentName', 'COLUMN';
GO

-- 4) Verify the result
SELECT * FROM Dim_Department ORDER BY DepartmentID;


-- Data Cleaning (Patient Visits Table)
---- Merge all yearly visit tables (2020–2025) into one consolidated PatientVisits table

/* =====================================================================
   HOSPITAL DATA ANALYSIS | Data Cleaning: merge the yearly visit tables
   Target: Microsoft SQL Server (T-SQL)
   ===================================================================== */

-- 1) Create the consolidated table (same columns, keys and constraints as the yearly tables)
CREATE TABLE PatientVisits (
    VisitID           varchar(20) PRIMARY KEY,
    PatientID         varchar(20),
    DoctorID          varchar(20),
    DepartmentID      varchar(20),
    DiagnosisID       varchar(20),
    TreatmentID       varchar(20),
    PaymentMethodID   varchar(20),
    VisitDate         date,
    VisitTime         time,
    DischargeDate     date,
    BillAmount        decimal(18,2),
    InsuranceAmount   decimal(18,2),
    SatisfactionScore integer,
    WaitTimeMinutes   integer,
    FOREIGN KEY (PatientID)       REFERENCES Dim_Patient(PatientID),
    FOREIGN KEY (DoctorID)        REFERENCES Dim_Doctor(DoctorID),
    FOREIGN KEY (DepartmentID)    REFERENCES Dim_Department(DepartmentID),
    FOREIGN KEY (DiagnosisID)     REFERENCES Dim_Diagnosis(DiagnosisID),
    FOREIGN KEY (TreatmentID)     REFERENCES Dim_Treatment(TreatmentID),
    FOREIGN KEY (PaymentMethodID) REFERENCES Dim_PaymentMethod(PaymentMethodID)
);
GO

-- 2) Load all four yearly tables into it
INSERT INTO PatientVisits
    (VisitID, PatientID, DoctorID, DepartmentID, DiagnosisID, TreatmentID, PaymentMethodID,
     VisitDate, VisitTime, DischargeDate, BillAmount, InsuranceAmount, SatisfactionScore, WaitTimeMinutes)
SELECT VisitID, PatientID, DoctorID, DepartmentID, DiagnosisID, TreatmentID, PaymentMethodID,
       VisitDate, VisitTime, DischargeDate, BillAmount, InsuranceAmount, SatisfactionScore, WaitTimeMinutes
FROM PatientVisits_2020_2021
UNION ALL
SELECT VisitID, PatientID, DoctorID, DepartmentID, DiagnosisID, TreatmentID, PaymentMethodID,
       VisitDate, VisitTime, DischargeDate, BillAmount, InsuranceAmount, SatisfactionScore, WaitTimeMinutes
FROM PatientVisits_2022_2023
UNION ALL
SELECT VisitID, PatientID, DoctorID, DepartmentID, DiagnosisID, TreatmentID, PaymentMethodID,
       VisitDate, VisitTime, DischargeDate, BillAmount, InsuranceAmount, SatisfactionScore, WaitTimeMinutes
FROM PatientVisits_2024
UNION ALL
SELECT VisitID, PatientID, DoctorID, DepartmentID, DiagnosisID, TreatmentID, PaymentMethodID,
       VisitDate, VisitTime, DischargeDate, BillAmount, InsuranceAmount, SatisfactionScore, WaitTimeMinutes
FROM PatientVisits_2025;
GO

-- 3) Verify: the merged row count must equal the sum of the four tables
SELECT (SELECT COUNT(*) FROM PatientVisits) AS Merged_Rows,
       (SELECT COUNT(*) FROM PatientVisits_2020_2021)
     + (SELECT COUNT(*) FROM PatientVisits_2022_2023)
     + (SELECT COUNT(*) FROM PatientVisits_2024)
     + (SELECT COUNT(*) FROM PatientVisits_2025) AS Yearly_Tables_Total;

SELECT YEAR(VisitDate) AS Visit_Year, COUNT(*) AS Visits
FROM PatientVisits
GROUP BY YEAR(VisitDate)
ORDER BY Visit_Year;


