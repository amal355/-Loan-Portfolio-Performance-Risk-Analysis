/* =====================================================================
   Sales KPIs - analysis queries (SQL Server / T-SQL)
   Database : seleskpis
   Run first: Sales_KPIs_setup.sql  (creates and fills the tables)
   Sections : A Loan portfolio | B Collections | C Complaints
              D Visits and documents | E Customer risk
   How to run: select a query and press Execute, or run the whole file.
   Data notes:
     - Collection KPIs use approved loans only (Collection_Status also has
       installments for loans that were not approved).
     - Officer EMP4 exists in Loan_Details but not in Sales_Officers.
     - Complaints without a Transaction_ID cannot be tied to a branch.
   ===================================================================== */
USE seleskpis;
GO


/* ################################################################
   A. LOAN PORTFOLIO
   ################################################################ */

-- A1  Portfolio summary
-- One-row overview of the whole loan book: volumes, approval rate, amounts, average tenure and processing time.
SELECT
    COUNT(*)                                                        AS Total_Applications,
    SUM(CASE WHEN Approval_Status = 'Yes' THEN 1 ELSE 0 END)        AS Approved,
    SUM(CASE WHEN Approval_Status = 'No'  THEN 1 ELSE 0 END)        AS Rejected,
    ROUND(100.0 * SUM(CASE WHEN Approval_Status = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Approval_Rate_Pct,
    SUM(Requested_Amount)                                           AS Total_Requested,
    SUM(Loan_Amount)                                                AS Total_Disbursed,
    ROUND(AVG(CASE WHEN Approval_Status = 'Yes' THEN Loan_Amount END), 2) AS Avg_Approved_Loan,
    ROUND(AVG(1.0 * Tenure_Months), 1)                                    AS Avg_Tenure_Months,
    ROUND(AVG(1.0 * DATEDIFF(day, Application_Date, Disbursement_Date)), 1) AS Avg_Days_To_Disburse
FROM Loan_Details;
GO

-- A2  Approval rate and amounts by branch
-- Which branches get the most approvals and disburse the most money.
SELECT
    Branch_Name,
    COUNT(*)                                                        AS Applications,
    SUM(CASE WHEN Approval_Status = 'Yes' THEN 1 ELSE 0 END)        AS Approved,
    ROUND(100.0 * SUM(CASE WHEN Approval_Status = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Approval_Rate_Pct,
    SUM(Requested_Amount)                                           AS Total_Requested,
    SUM(Loan_Amount)                                                AS Total_Disbursed,
    ROUND(AVG(CASE WHEN Approval_Status = 'Yes' THEN Loan_Amount END), 2) AS Avg_Approved_Loan
FROM Loan_Details
GROUP BY Branch_Name
ORDER BY Total_Disbursed DESC;
GO

-- A3  Approval rate and amounts by product
-- Performance of each loan product (Personal, Auto, Home, Education, Business).
SELECT
    Product_Name,
    COUNT(*)                                                        AS Applications,
    SUM(CASE WHEN Approval_Status = 'Yes' THEN 1 ELSE 0 END)        AS Approved,
    ROUND(100.0 * SUM(CASE WHEN Approval_Status = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Approval_Rate_Pct,
    SUM(Requested_Amount)                                           AS Total_Requested,
    SUM(Loan_Amount)                                                AS Total_Disbursed,
    ROUND(AVG(1.0 * Tenure_Months), 1)                                    AS Avg_Tenure_Months
FROM Loan_Details
GROUP BY Product_Name
ORDER BY Total_Disbursed DESC;
GO

-- A4  Sales officer performance and ranking
-- Applications, approvals and disbursed amount per sales officer, ranked by disbursed amount. Note: officer EMP4 appears in Loan_Details but is missing from the Sales_Officers table, so it is shown as "Unknown officer".
SELECT
    RANK() OVER (ORDER BY SUM(l.Loan_Amount) DESC)                  AS Rank_By_Disbursed,
    l.Officer_ID,
    COALESCE(o.Sales_Officer, 'Unknown officer')                    AS Sales_Officer,
    COUNT(*)                                                        AS Applications,
    SUM(CASE WHEN l.Approval_Status = 'Yes' THEN 1 ELSE 0 END)      AS Approved,
    ROUND(100.0 * SUM(CASE WHEN l.Approval_Status = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Approval_Rate_Pct,
    SUM(l.Loan_Amount)                                              AS Total_Disbursed
FROM Loan_Details l
LEFT JOIN Sales_Officers o ON o.Officer_ID = l.Officer_ID
GROUP BY l.Officer_ID, o.Sales_Officer
ORDER BY Rank_By_Disbursed;
GO

-- A5  Monthly trend of applications and disbursements
-- Applications, approvals and disbursed amount per month (by application date).
SELECT
    YEAR(Application_Date)                                          AS Yr,
    MONTH(Application_Date)                                         AS Mth,
    COUNT(*)                                                        AS Applications,
    SUM(CASE WHEN Approval_Status = 'Yes' THEN 1 ELSE 0 END)        AS Approved,
    ROUND(100.0 * SUM(CASE WHEN Approval_Status = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Approval_Rate_Pct,
    SUM(Loan_Amount)                                                AS Total_Disbursed
FROM Loan_Details
GROUP BY YEAR(Application_Date), MONTH(Application_Date)
ORDER BY Yr, Mth;
GO

-- A6  Processing time (application to disbursement) by product
-- Average, fastest and slowest number of days between application and disbursement.
SELECT
    Product_Name,
    COUNT(*)                                                        AS Loans,
    ROUND(AVG(1.0 * DATEDIFF(day, Application_Date, Disbursement_Date)), 1) AS Avg_Days,
    MIN(DATEDIFF(day, Application_Date, Disbursement_Date))         AS Min_Days,
    MAX(DATEDIFF(day, Application_Date, Disbursement_Date))         AS Max_Days
FROM Loan_Details
GROUP BY Product_Name
ORDER BY Avg_Days;
GO

-- A7  Approval rate by gender
-- Approval rate split by customer gender.
SELECT
    c.Gender,
    COUNT(*)                                                        AS Applications,
    SUM(CASE WHEN l.Approval_Status = 'Yes' THEN 1 ELSE 0 END)      AS Approved,
    ROUND(100.0 * SUM(CASE WHEN l.Approval_Status = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Approval_Rate_Pct,
    SUM(l.Loan_Amount)                                              AS Total_Disbursed
FROM Loan_Details l
JOIN Customers c ON c.Customer_ID = l.Customer_ID
GROUP BY c.Gender
ORDER BY Applications DESC;
GO

-- A8  Approval rate by customer age group
-- Approval rate by the customer age at application date.
WITH x AS (
    SELECT l.*,
           DATEDIFF(year, c.Date_of_Birth, l.Application_Date) AS Age
    FROM Loan_Details l
    JOIN Customers c ON c.Customer_ID = l.Customer_ID
)
SELECT
    CASE WHEN Age < 30 THEN '1) Under 30'
         WHEN Age < 40 THEN '2) 30-39'
         WHEN Age < 50 THEN '3) 40-49'
         WHEN Age < 60 THEN '4) 50-59'
         ELSE '5) 60+' END                                          AS Age_Group,
    COUNT(*)                                                        AS Applications,
    SUM(CASE WHEN Approval_Status = 'Yes' THEN 1 ELSE 0 END)        AS Approved,
    ROUND(100.0 * SUM(CASE WHEN Approval_Status = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Approval_Rate_Pct,
    SUM(Loan_Amount)                                                AS Total_Disbursed
FROM x
GROUP BY CASE WHEN Age < 30 THEN '1) Under 30'
              WHEN Age < 40 THEN '2) 30-39'
              WHEN Age < 50 THEN '3) 40-49'
              WHEN Age < 60 THEN '4) 50-59'
              ELSE '5) 60+' END
ORDER BY Age_Group;
GO


/* ################################################################
   B. COLLECTIONS
   ################################################################ */

-- B1  Overall collection summary (approved loans only)
-- Installment counts and amounts by status, and the collection rate. Note: Collection_Status also contains installments for loans that were NOT approved; they are excluded here because no money was disbursed on them.
SELECT
    COUNT(*)                                                        AS Total_Installments,
    SUM(CASE WHEN c.Status = 'Paid'    THEN 1 ELSE 0 END)           AS Paid,
    SUM(CASE WHEN c.Status = 'Missed'  THEN 1 ELSE 0 END)           AS Missed,
    SUM(CASE WHEN c.Status = 'Overdue' THEN 1 ELSE 0 END)           AS Overdue,
    ROUND(100.0 * SUM(CASE WHEN c.Status = 'Paid' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Collection_Rate_Pct,
    ROUND(SUM(c.Installment_Amount), 2)                             AS Amount_Due,
    ROUND(SUM(CASE WHEN c.Status = 'Paid' THEN c.Installment_Amount ELSE 0 END), 2) AS Amount_Collected,
    ROUND(SUM(CASE WHEN c.Status <> 'Paid' THEN c.Installment_Amount ELSE 0 END), 2) AS Amount_Not_Collected,
    ROUND(100.0 * SUM(CASE WHEN c.Status = 'Paid' THEN c.Installment_Amount ELSE 0 END) / SUM(c.Installment_Amount), 1) AS Collection_Rate_By_Amount_Pct
FROM Collection_Status c
JOIN Loan_Details l ON l.Transaction_ID = c.Transaction_ID
WHERE l.Approval_Status = 'Yes';
GO

-- B2  Collection rate by branch
-- Which branches collect best and which have the most unpaid installments.
SELECT
    l.Branch_Name,
    COUNT(*)                                                        AS Installments,
    SUM(CASE WHEN c.Status = 'Paid' THEN 1 ELSE 0 END)              AS Paid,
    SUM(CASE WHEN c.Status <> 'Paid' THEN 1 ELSE 0 END)             AS Not_Paid,
    ROUND(100.0 * SUM(CASE WHEN c.Status = 'Paid' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Collection_Rate_Pct,
    ROUND(SUM(CASE WHEN c.Status <> 'Paid' THEN c.Installment_Amount ELSE 0 END), 2) AS Amount_Not_Collected
FROM Collection_Status c
JOIN Loan_Details l ON l.Transaction_ID = c.Transaction_ID
WHERE l.Approval_Status = 'Yes'
GROUP BY l.Branch_Name
ORDER BY Collection_Rate_Pct DESC;
GO

-- B3  Collection rate by product
-- Collection performance for each loan product.
SELECT
    l.Product_Name,
    COUNT(*)                                                        AS Installments,
    SUM(CASE WHEN c.Status = 'Paid'    THEN 1 ELSE 0 END)           AS Paid,
    SUM(CASE WHEN c.Status = 'Missed'  THEN 1 ELSE 0 END)           AS Missed,
    SUM(CASE WHEN c.Status = 'Overdue' THEN 1 ELSE 0 END)           AS Overdue,
    ROUND(100.0 * SUM(CASE WHEN c.Status = 'Paid' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Collection_Rate_Pct,
    ROUND(SUM(CASE WHEN c.Status <> 'Paid' THEN c.Installment_Amount ELSE 0 END), 2) AS Amount_Not_Collected
FROM Collection_Status c
JOIN Loan_Details l ON l.Transaction_ID = c.Transaction_ID
WHERE l.Approval_Status = 'Yes'
GROUP BY l.Product_Name
ORDER BY Collection_Rate_Pct DESC;
GO

-- B4  Collection rate by sales officer
-- Collection quality of the loans each officer originated (officer EMP4 is missing from Sales_Officers and shown as "Unknown officer").
SELECT
    l.Officer_ID,
    COALESCE(o.Sales_Officer, 'Unknown officer')                    AS Sales_Officer,
    COUNT(*)                                                        AS Installments,
    SUM(CASE WHEN c.Status = 'Paid' THEN 1 ELSE 0 END)              AS Paid,
    ROUND(100.0 * SUM(CASE WHEN c.Status = 'Paid' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Collection_Rate_Pct,
    ROUND(SUM(CASE WHEN c.Status <> 'Paid' THEN c.Installment_Amount ELSE 0 END), 2) AS Amount_Not_Collected
FROM Collection_Status c
JOIN Loan_Details l ON l.Transaction_ID = c.Transaction_ID
LEFT JOIN Sales_Officers o ON o.Officer_ID = l.Officer_ID
WHERE l.Approval_Status = 'Yes'
GROUP BY l.Officer_ID, o.Sales_Officer
ORDER BY Collection_Rate_Pct DESC;
GO

-- B5  Monthly collection trend
-- Installments due, collected and the collection rate per month.
SELECT
    YEAR(c.Collection_Date)                                         AS Yr,
    MONTH(c.Collection_Date)                                        AS Mth,
    COUNT(*)                                                        AS Installments,
    SUM(CASE WHEN c.Status = 'Paid' THEN 1 ELSE 0 END)              AS Paid,
    ROUND(100.0 * SUM(CASE WHEN c.Status = 'Paid' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Collection_Rate_Pct,
    ROUND(SUM(c.Installment_Amount), 2)                             AS Amount_Due,
    ROUND(SUM(CASE WHEN c.Status = 'Paid' THEN c.Installment_Amount ELSE 0 END), 2) AS Amount_Collected
FROM Collection_Status c
JOIN Loan_Details l ON l.Transaction_ID = c.Transaction_ID
WHERE l.Approval_Status = 'Yes'
GROUP BY YEAR(c.Collection_Date), MONTH(c.Collection_Date)
ORDER BY Yr, Mth;
GO

-- B6  Top 10 customers by unpaid amount
-- Customers with the largest amount of Missed or Overdue installments (collection priority list).
SELECT TOP 10
    cu.Customer_ID,
    cu.Customer_Name,
    COUNT(*)                                                        AS Installments,
    SUM(CASE WHEN c.Status <> 'Paid' THEN 1 ELSE 0 END)             AS Late_Installments,
    ROUND(100.0 * SUM(CASE WHEN c.Status <> 'Paid' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Late_Rate_Pct,
    ROUND(SUM(CASE WHEN c.Status <> 'Paid' THEN c.Installment_Amount ELSE 0 END), 2) AS Amount_Not_Collected
FROM Collection_Status c
JOIN Loan_Details l  ON l.Transaction_ID = c.Transaction_ID
JOIN Customers cu    ON cu.Customer_ID = l.Customer_ID
WHERE l.Approval_Status = 'Yes'
GROUP BY cu.Customer_ID, cu.Customer_Name
ORDER BY Amount_Not_Collected DESC;
GO


/* ################################################################
   C. COMPLAINTS
   ################################################################ */

-- C1  Complaints by type and resolution status
-- Number of complaints per type, split by Resolved / Pending / Escalated.
SELECT
    t.Complaint_Type,
    COUNT(*)                                                        AS Complaints,
    SUM(CASE WHEN c.Resolution_Status = 'Resolved'  THEN 1 ELSE 0 END) AS Resolved,
    SUM(CASE WHEN c.Resolution_Status = 'Pending'   THEN 1 ELSE 0 END) AS Pending,
    SUM(CASE WHEN c.Resolution_Status = 'Escalated' THEN 1 ELSE 0 END) AS Escalated,
    ROUND(100.0 * SUM(CASE WHEN c.Resolution_Status = 'Resolved' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Resolution_Rate_Pct
FROM Customer_Complaints c
JOIN Complaint_Types t ON t.Complaint_Type_ID = c.Complaint_Type_ID
GROUP BY t.Complaint_Type
ORDER BY Complaints DESC;
GO

-- C2  Overall complaint resolution KPIs
-- One-row summary: total complaints, resolution rate, share still open.
SELECT
    COUNT(*)                                                        AS Total_Complaints,
    SUM(CASE WHEN Resolution_Status = 'Resolved'  THEN 1 ELSE 0 END) AS Resolved,
    SUM(CASE WHEN Resolution_Status = 'Pending'   THEN 1 ELSE 0 END) AS Pending,
    SUM(CASE WHEN Resolution_Status = 'Escalated' THEN 1 ELSE 0 END) AS Escalated,
    ROUND(100.0 * SUM(CASE WHEN Resolution_Status = 'Resolved' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Resolution_Rate_Pct,
    ROUND(100.0 * SUM(CASE WHEN Resolution_Status <> 'Resolved' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Open_Rate_Pct,
    COUNT(DISTINCT Customer_ID)                                     AS Customers_Complaining
FROM Customer_Complaints;
GO

-- C3  Complaints by branch (complaints linked to a loan)
-- Complaints per branch and complaints per 100 loan applications. Only complaints that have a Transaction_ID can be tied to a branch; complaints without one are excluded.
WITH loans AS (
    SELECT Branch_Name, COUNT(*) AS Applications
    FROM Loan_Details
    GROUP BY Branch_Name
),
cmp AS (
    SELECT l.Branch_Name,
           COUNT(*) AS Complaints,
           SUM(CASE WHEN c.Resolution_Status <> 'Resolved' THEN 1 ELSE 0 END) AS Open_Complaints
    FROM Customer_Complaints c
    JOIN Loan_Details l ON l.Transaction_ID = c.Transaction_ID
    GROUP BY l.Branch_Name
)
SELECT
    loans.Branch_Name,
    loans.Applications,
    COALESCE(cmp.Complaints, 0)                                     AS Complaints,
    COALESCE(cmp.Open_Complaints, 0)                                AS Open_Complaints,
    ROUND(100.0 * COALESCE(cmp.Complaints, 0) / loans.Applications, 1) AS Complaints_Per_100_Loans
FROM loans
LEFT JOIN cmp ON cmp.Branch_Name = loans.Branch_Name
ORDER BY Complaints DESC;
GO

-- C4  Monthly complaint trend
-- Number of complaints and how many are still open, per month.
SELECT
    YEAR(Complaint_Date)                                            AS Yr,
    MONTH(Complaint_Date)                                           AS Mth,
    COUNT(*)                                                        AS Complaints,
    SUM(CASE WHEN Resolution_Status <> 'Resolved' THEN 1 ELSE 0 END) AS Open_Complaints
FROM Customer_Complaints
GROUP BY YEAR(Complaint_Date), MONTH(Complaint_Date)
ORDER BY Yr, Mth;
GO

-- C5  Top 10 customers by number of complaints
-- Customers who complain most often.
SELECT TOP 10
    cu.Customer_ID,
    cu.Customer_Name,
    COUNT(*)                                                        AS Complaints,
    SUM(CASE WHEN c.Resolution_Status <> 'Resolved' THEN 1 ELSE 0 END) AS Open_Complaints
FROM Customer_Complaints c
JOIN Customers cu ON cu.Customer_ID = c.Customer_ID
GROUP BY cu.Customer_ID, cu.Customer_Name
ORDER BY Complaints DESC, Open_Complaints DESC, cu.Customer_ID;
GO


/* ################################################################
   D. VISITS AND DOCUMENTS
   ################################################################ */

-- D1  Field visits by outcome
-- Number and share of customer visits per outcome code (the workbook has no description table for VO1-VO3).
SELECT
    Visit_Outcome_ID,
    COUNT(*)                                                        AS Visits,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)              AS Share_Pct,
    COUNT(DISTINCT Customer_ID)                                     AS Customers_Visited
FROM Visits
GROUP BY Visit_Outcome_ID
ORDER BY Visit_Outcome_ID;
GO

-- D2  Missing documents by type
-- How many customers are missing each required document.
SELECT
    COUNT(*)                                                        AS Customers,
    SUM(CASE WHEN ID_Copy = 'No'       THEN 1 ELSE 0 END)           AS Missing_ID_Copy,
    SUM(CASE WHEN Salary_Proof = 'No'  THEN 1 ELSE 0 END)           AS Missing_Salary_Proof,
    SUM(CASE WHEN Address_Proof = 'No' THEN 1 ELSE 0 END)           AS Missing_Address_Proof,
    SUM(CASE WHEN ID_Copy = 'Yes' AND Salary_Proof = 'Yes' AND Address_Proof = 'Yes' THEN 1 ELSE 0 END) AS Fully_Documented,
    ROUND(100.0 * SUM(CASE WHEN ID_Copy = 'Yes' AND Salary_Proof = 'Yes' AND Address_Proof = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Fully_Documented_Pct
FROM Documents;
GO

-- D3  Document completeness vs loan approval rate
-- Does having more documents on file lead to a higher approval rate? Customers grouped by number of documents submitted (0 to 3).
WITH d AS (
    SELECT Customer_ID,
           (CASE WHEN ID_Copy = 'Yes' THEN 1 ELSE 0 END
          + CASE WHEN Salary_Proof = 'Yes' THEN 1 ELSE 0 END
          + CASE WHEN Address_Proof = 'Yes' THEN 1 ELSE 0 END) AS Docs_Submitted
    FROM Documents
)
SELECT
    d.Docs_Submitted,
    COUNT(DISTINCT d.Customer_ID)                                   AS Customers,
    COUNT(*)                                                        AS Applications,
    SUM(CASE WHEN l.Approval_Status = 'Yes' THEN 1 ELSE 0 END)      AS Approved,
    ROUND(100.0 * SUM(CASE WHEN l.Approval_Status = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 1) AS Approval_Rate_Pct
FROM d
JOIN Loan_Details l ON l.Customer_ID = d.Customer_ID
GROUP BY d.Docs_Submitted
ORDER BY d.Docs_Submitted;
GO


/* ################################################################
   E. CUSTOMER RISK
   ################################################################ */

-- E1  Customer risk scorecard (top 20)
-- Combines late-payment rate, unresolved complaints and missing documents into one simple score per customer. Score = 0-3 points for late rate (>=75%: 3, >=60%: 2, >=45%: 1) + 1 if any unresolved complaint + 1 if two or more documents are missing. Risk level: High >= 4, Medium 2-3, Low 0-1. Only customers with at least one approved loan are scored.
WITH pay AS (
    SELECT l.Customer_ID,
           COUNT(*) AS Installments,
           SUM(CASE WHEN c.Status <> 'Paid' THEN 1 ELSE 0 END) AS Late_Installments,
           SUM(CASE WHEN c.Status <> 'Paid' THEN c.Installment_Amount ELSE 0 END) AS Amount_Not_Collected
    FROM Collection_Status c
    JOIN Loan_Details l ON l.Transaction_ID = c.Transaction_ID
    WHERE l.Approval_Status = 'Yes'
    GROUP BY l.Customer_ID
),
cmp AS (
    SELECT Customer_ID,
           COUNT(*) AS Complaints,
           SUM(CASE WHEN Resolution_Status <> 'Resolved' THEN 1 ELSE 0 END) AS Open_Complaints
    FROM Customer_Complaints
    GROUP BY Customer_ID
),
doc AS (
    SELECT Customer_ID,
           (CASE WHEN ID_Copy = 'No' THEN 1 ELSE 0 END
          + CASE WHEN Salary_Proof = 'No' THEN 1 ELSE 0 END
          + CASE WHEN Address_Proof = 'No' THEN 1 ELSE 0 END) AS Missing_Docs
    FROM Documents
),
scored AS (
    SELECT cu.Customer_ID,
           cu.Customer_Name,
           pay.Installments,
           pay.Late_Installments,
           ROUND(100.0 * pay.Late_Installments / pay.Installments, 1) AS Late_Rate_Pct,
           ROUND(pay.Amount_Not_Collected, 2)                         AS Amount_Not_Collected,
           COALESCE(cmp.Open_Complaints, 0)                           AS Open_Complaints,
           COALESCE(doc.Missing_Docs, 0)                              AS Missing_Docs,
           (CASE WHEN 100.0 * pay.Late_Installments / pay.Installments >= 75 THEN 3
                 WHEN 100.0 * pay.Late_Installments / pay.Installments >= 60 THEN 2
                 WHEN 100.0 * pay.Late_Installments / pay.Installments >= 45 THEN 1
                 ELSE 0 END
          + CASE WHEN COALESCE(cmp.Open_Complaints, 0) > 0 THEN 1 ELSE 0 END
          + CASE WHEN COALESCE(doc.Missing_Docs, 0) >= 2 THEN 1 ELSE 0 END) AS Risk_Score
    FROM Customers cu
    JOIN pay ON pay.Customer_ID = cu.Customer_ID
    LEFT JOIN cmp ON cmp.Customer_ID = cu.Customer_ID
    LEFT JOIN doc ON doc.Customer_ID = cu.Customer_ID
)
SELECT TOP 20
    Customer_ID, Customer_Name, Installments, Late_Installments, Late_Rate_Pct,
    Amount_Not_Collected, Open_Complaints, Missing_Docs, Risk_Score,
    CASE WHEN Risk_Score >= 4 THEN 'High'
         WHEN Risk_Score >= 2 THEN 'Medium'
         ELSE 'Low' END                                             AS Risk_Level
FROM scored
ORDER BY Risk_Score DESC, Amount_Not_Collected DESC;
GO

-- E2  Customers per risk level
-- How many customers fall in each risk level, using the same scoring rules as E1.
WITH pay AS (
    SELECT l.Customer_ID,
           COUNT(*) AS Installments,
           SUM(CASE WHEN c.Status <> 'Paid' THEN 1 ELSE 0 END) AS Late_Installments,
           SUM(CASE WHEN c.Status <> 'Paid' THEN c.Installment_Amount ELSE 0 END) AS Amount_Not_Collected
    FROM Collection_Status c
    JOIN Loan_Details l ON l.Transaction_ID = c.Transaction_ID
    WHERE l.Approval_Status = 'Yes'
    GROUP BY l.Customer_ID
),
cmp AS (
    SELECT Customer_ID,
           SUM(CASE WHEN Resolution_Status <> 'Resolved' THEN 1 ELSE 0 END) AS Open_Complaints
    FROM Customer_Complaints
    GROUP BY Customer_ID
),
doc AS (
    SELECT Customer_ID,
           (CASE WHEN ID_Copy = 'No' THEN 1 ELSE 0 END
          + CASE WHEN Salary_Proof = 'No' THEN 1 ELSE 0 END
          + CASE WHEN Address_Proof = 'No' THEN 1 ELSE 0 END) AS Missing_Docs
    FROM Documents
),
scored AS (
    SELECT pay.Customer_ID,
           pay.Amount_Not_Collected,
           (CASE WHEN 100.0 * pay.Late_Installments / pay.Installments >= 75 THEN 3
                 WHEN 100.0 * pay.Late_Installments / pay.Installments >= 60 THEN 2
                 WHEN 100.0 * pay.Late_Installments / pay.Installments >= 45 THEN 1
                 ELSE 0 END
          + CASE WHEN COALESCE(cmp.Open_Complaints, 0) > 0 THEN 1 ELSE 0 END
          + CASE WHEN COALESCE(doc.Missing_Docs, 0) >= 2 THEN 1 ELSE 0 END) AS Risk_Score
    FROM pay
    LEFT JOIN cmp ON cmp.Customer_ID = pay.Customer_ID
    LEFT JOIN doc ON doc.Customer_ID = pay.Customer_ID
)
SELECT
    CASE WHEN Risk_Score >= 4 THEN 'High'
         WHEN Risk_Score >= 2 THEN 'Medium'
         ELSE 'Low' END                                             AS Risk_Level,
    COUNT(*)                                                        AS Customers,
    ROUND(SUM(Amount_Not_Collected), 2)                             AS Amount_Not_Collected
FROM scored
GROUP BY CASE WHEN Risk_Score >= 4 THEN 'High'
              WHEN Risk_Score >= 2 THEN 'Medium'
              ELSE 'Low' END
ORDER BY Customers DESC;
GO
