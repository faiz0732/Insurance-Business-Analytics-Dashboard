/* ============================================================
-- Project: INSURANCE BUSINESS ANALYTICS DASHBOARD
-- Database: insurance_project (MySQL Workbench)
-- Author: Mohammad Faiz
-- Objective: End-to-End Insurance Data Ingestion, Cleaning & KPI Analysis
   ============================================================ */


/* ============================================================
   1. DATABASE CREATION
   ============================================================ */

CREATE DATABASE IF NOT EXISTS insurance_project;
USE insurance_project;

/* ============================================================
   2. DATA VALIDATION (CHECK TABLES)
   ============================================================ */

SELECT * FROM opportunity;
SELECT * FROM brokerage;
SELECT * FROM fees;
SELECT * FROM invoice;
SELECT * FROM meeting;
SELECT * FROM budget;


/* ============================================================
   3. KPI CALCULATIONS
   ============================================================ */

-- KPI 1: Total Invoices
SELECT 
    COUNT(invoice_number) AS total_invoices
FROM invoice;


-- KPI 2: Total Meetings
SELECT 
    COUNT(meeting_date) AS total_meetings
FROM meeting;


-- KPI 3: Total Revenue (Brokerage + Fees)
SELECT 
    SUM(amount) AS total_revenue
FROM (
    SELECT amount FROM brokerage
    UNION ALL
    SELECT amount FROM fees
) AS revenue_data;


-- KPI 4: Total Opportunities
SELECT 
    COUNT(opportunity_id) AS total_opportunities
FROM opportunity;


-- KPI 5: Conversion Ratio
SELECT 
    SUM(CASE WHEN stage = 'Negotiate' THEN 1 ELSE 0 END) * 100.0 
    / COUNT(*) AS conversion_ratio
FROM opportunity;


-- KPI 6: Target vs Achievement

-- Step 1: Achievement Calculation
SELECT 
    b.`Employee Name` AS account_executive,
    SUM(combined.amount) AS achievement
FROM (
    SELECT `Account Exe ID` AS exe_id, Amount AS amount FROM brokerage
    UNION ALL
    SELECT `Account Exe ID` AS exe_id, Amount AS amount FROM fees
) AS combined
JOIN budget b
    ON combined.exe_id = b.`Account Exe ID`
GROUP BY b.`Employee Name`;


-- Step 2: Target Calculation
SELECT 
    `Employee Name` AS account_executive,
    (`New Budget` + `Cross sell bugdet` + `Renewal Budget`) AS target
FROM budget;


-- KPI 7: Top 10 Opportunities
SELECT 
    opportunity_name, 
    revenue_amount
FROM opportunity
ORDER BY revenue_amount DESC
LIMIT 10;


-- KPI 8: Pipeline Analysis
SELECT 
    stage, 
    SUM(revenue_amount) AS total_revenue
FROM opportunity
GROUP BY stage;


/* ============================================================
   4. FINAL DASHBOARD DATA (VIEW CREATION FOR POWER BI)
   ============================================================ */

CREATE OR REPLACE VIEW final_dashboard_data AS
SELECT 
    o.`Account Executive` AS account_executive,
    COUNT(DISTINCT o.opportunity_id) AS total_opportunities,
    SUM(o.revenue_amount) AS total_pipeline_revenue,
    
    SUM(CASE WHEN o.stage = 'Negotiate' THEN 1 ELSE 0 END) AS closed_opportunities,

    SUM(CASE WHEN o.stage = 'Negotiate' THEN 1 ELSE 0 END) * 100.0
        / COUNT(o.opportunity_id) AS conversion_ratio

FROM opportunity o
GROUP BY o.`Account Executive`;


/* ============================================================
   5. REVENUE VIEW (BROKERAGE + FEES)
   ============================================================ */

CREATE OR REPLACE VIEW revenue_data AS
SELECT 
    exe_name, 
    SUM(amount) AS total_revenue
FROM (
    SELECT `Exe Name` AS exe_name, Amount AS amount FROM brokerage
    UNION ALL
    SELECT `Account Executive` AS exe_name, Amount AS amount FROM fees
) AS combined_revenue
GROUP BY exe_name;


/* ============================================================
   6. TARGET VIEW
   ============================================================ */

CREATE OR REPLACE VIEW target_data AS
SELECT 
    `Employee Name` AS account_executive,
    (`New Budget` + `Cross sell bugdet` + `Renewal Budget`) AS target
FROM budget;


/* ============================================================
   7. FINAL KPI VIEW (TARGET VS ACHIEVEMENT)
   ============================================================ */

CREATE OR REPLACE VIEW final_kpi AS
SELECT 
    r.exe_name AS account_executive,
    r.total_revenue,
    t.target,
    
    CASE 
        WHEN t.target = 0 OR t.target IS NULL THEN 0
        ELSE (r.total_revenue / t.target) * 100
    END AS achievement_percent

FROM revenue_data r
LEFT JOIN target_data t
    ON r.exe_name = t.account_executive;


/* ============================================================
   END OF THE QUERIES
   ============================================================ */