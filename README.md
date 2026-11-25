# Loan Portfolio Performance & Risk Analysis

## Project Name
**Loan Portfolio Performance & Risk Analysis**

---

## Project Idea

A retail lender needs a clear view of how its loan book is performing and where the risk sits. This project takes raw operational data (loan applications, installment collections, customer complaints, field visits and customer documents) and turns it into a clean data model, SQL analysis, statistical charts and an interactive dashboard.

The analysis answers four business questions:

1. **Portfolio** – How many applications do we receive, how many are approved, how much is disbursed, and how do branches, products, sales officers, genders and age groups compare?
2. **Collections** – What share of installments is actually paid? Which branches, products and officers have the weakest collection? Which customers owe the most?
3. **Customer service** – What do customers complain about, how many complaints are still open, and which branches generate the most?
4. **Customer risk** – Can late payments, unresolved complaints and missing documents be combined into one simple risk score to flag high-risk customers?

### Dataset (`Sales_KPIs.xlsx`)

| Sheet | Type | Content |
|---|---|---|
| Loan Details | Fact | ~1,000 loan applications (2023–2024): product, branch, officer, requested / approved amount, approval status, tenure, dates |
| Collection Status | Fact | ~6,500 monthly installments with status `Paid`, `Missed` or `Overdue` |
| Customer Complaints | Fact | 150 complaints with type, date and resolution status |
| Customer Details | Dimension | 100 customers (gender, date of birth) |
| Sales Officer | Dimension | 19 sales officers |
| Branch | Dimension | 10 branches |
| Complaint Type | Dimension | 6 complaint types (Service Delay, Incorrect Charges, Rude Staff, Technical Issue, System Error, Document Delay) |
| Visit Outcome | Dimension | 200 field visits with outcome codes VO1–VO3 |
| Document Details | Dimension | Documents per customer: ID copy, salary proof, address proof |

### Data model (Power BI)
Star schema built on `Loan Details` and `Collection Status` as the main fact tables, connected to the dimensions Customers, Officers, Branch, Products, Complaint Types, Documents, Visits and a Calendar table. All DAX measures are kept in a dedicated `Dax_Measures` table.

### Data quality notes
- Collection data also exists for loans that were **not approved**; collection KPIs are therefore calculated on **approved loans only**.
- Officer **EMP4** appears in Loan Details but is missing from the Sales Officer table (shown as "Unknown officer").
- Some complaints have no Transaction ID, so they cannot be linked to a branch.

---

## Team Members

| Name | Role |
|---|---|
| Engy | Data Model & Dashboard (Power BI, Excel) |
| Mina | Python Analysis & DAX |
| Youssef | SQL Analysis & tableau |
| Amal| Data Cleaning (Power Query) |

> Replace the names with full names if required by the instructor.

---

## Work Plan

| Phase | Task | Owner |
|---|---|---|
| 1 | Understand the dataset and define business questions and KPIs | Whole team |
| 2 | Clean and transform the data in Power Query (types, blanks, header rows, duplicates) | *[Your name]* |
| 3 | Build the data model (relationships, star schema, Calendar table) | Engy |
| 4 | Write DAX measures for the KPIs | Mina |
| 5 | Answer business questions with SQL (sections A–E) | Youssef |
| 6 | Statistical exploration and box plots in Python | Mina |
| 7 | Build the Power BI dashboard and Excel report | Engy |
| 8 | Review, document (this README) and present | Whole team |

> Add the dates for each phase if the instructor asks for a timeline.

---

## Roles & Responsibilities

**Engy – Data Model & Dashboard**
- Designed the data model in Power BI (tables, relationships, star schema).
- Built the interactive Power BI dashboard.
- Built the Excel work and report.

**Mina – Python & DAX**
- Created box plots in Python to study distributions and outliers.
- Wrote the DAX measures in Power BI (in the `Dax_Measures` table).

**Youssef – SQL Analysis**
- Defined the business questions and answered them in SQL Server (T-SQL) in `Sales_KPIs_queries.sql`.
- Queries are organised in five sections:
  - **A. Loan Portfolio** – summary, branch, product, officer ranking, monthly trend, processing time, gender and age analysis (A1–A8)
  - **B. Collections** – overall rate, by branch / product / officer, monthly trend, top 10 customers by unpaid amount (B1–B6)
  - **C. Complaints** – by type and status, resolution KPIs, by branch, monthly trend, top complainers (C1–C5)
  - **D. Visits & Documents** – visit outcomes, missing documents, documents vs approval rate (D1–D3)
  - **E. Customer Risk** – risk scorecard and customers per risk level (E1–E2)

**[Your name] – Data Cleaning**
- Cleaned and prepared the raw data with Power Query inside Power BI before modelling.

---

## KPIs

**Loan portfolio**
- Total applications, approved and rejected loans
- Approval rate (%)
- Total requested amount vs total disbursed amount
- Average approved loan and average tenure
- Average days from application to disbursement
- Performance by branch, product, sales officer (ranked), gender and age group

**Collections**
- Collection rate by count (% of installments `Paid`)
- Collection rate by amount (% of money collected)
- Amount due, amount collected and amount not collected
- Missed vs Overdue installments
- Collection rate by branch, product and officer; monthly collection trend
- Top 10 customers by unpaid amount

**Complaints**
- Total complaints and complaints per 100 loans by branch
- Resolution rate and open rate (Pending + Escalated)
- Complaints by type; monthly trend; customers with most complaints

**Visits & documents**
- Visits by outcome and customers visited
- Missing documents (ID copy, salary proof, address proof) and % of fully documented customers
- Approval rate by number of documents submitted

**Customer risk score**
- 0–3 points for late-payment rate (≥75%: 3, ≥60%: 2, ≥45%: 1)
- +1 point for any unresolved complaint
- +1 point if two or more documents are missing
- Risk level: **High** ≥ 4, **Medium** 2–3, **Low** 0–1

---

## Instructor
*[Instructor name]*

---

## Project Files

| File | Description |
|---|---|
| `Sales_KPIs.xlsx` | Source dataset (9 sheets: 3 facts, 6 dimensions) |
| `project_2.pbix` | Power BI file: Power Query cleaning, data model, DAX measures and dashboard |
| `Sales_KPIs_queries.sql` | T-SQL analysis queries (sections A–E). Requires the `seleskpis` database and the setup script `Sales_KPIs_setup.sql` to be run first |
| Python notebook / script | Box-plot analysis *(add the file name)* |
| `README.md` | This file |

### How to use
1. Open `Sales_KPIs.xlsx` to review the raw data.
2. Open `project_2.pbix` in Power BI Desktop to explore the model, measures and dashboard.
3. Run `Sales_KPIs_setup.sql`, then `Sales_KPIs_queries.sql` in SQL Server Management Studio (select a query and press Execute, or run the whole file).
4. Run the Python file to reproduce the box plots.

### Tools
Power Query · Power BI (data model, DAX, dashboard) · Excel · SQL Server (T-SQL) · Python
