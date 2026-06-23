USE [healthcare_dw];
GO

WITH PatientEncounters AS (
    -- Step 1: Filter out core encounter events and pull their timeline logs
    SELECT 
        [patient_key],
        [encounter_id],
        [event_date] AS [current_visit_date],
        -- LAG looks backward to pull the patient's previous hospital visit timestamp
        LAG([event_date]) OVER (PARTITION BY [patient_key] ORDER BY [event_date]) AS [previous_visit_date]
    FROM [analytics].[fact_clinical_events]
    WHERE [event_type] = 'ENCOUNTER'
),
ReadmissionIntervals AS (
    -- Step 2: Measure day intervals between sequential visits
    SELECT 
        [patient_key],
        [encounter_id],
        [current_visit_date],
        [previous_visit_date],
        DATEDIFF(day, [previous_visit_date], [current_visit_date]) AS [days_between_visits]
    FROM PatientEncounters
    WHERE [previous_visit_date] IS NOT NULL
),
FlaggedReadmissions AS (
    -- Step 3: Flag any repeat encounter that occurs within the critical 30-day clinical window
    SELECT 
        [encounter_id],
        [days_between_visits],
        CASE WHEN [days_between_visits] <= 30 THEN 1 ELSE 0 END AS [is_readmission]
    FROM ReadmissionIntervals
)
-- Step 4: Final corporate metric aggregation
SELECT 
    (SELECT COUNT(*) FROM analytics.fact_clinical_events WHERE event_type = 'ENCOUNTER') AS [Total Hospital Encounters],
    SUM(r.[is_readmission]) AS [Total 30-Day Readmissions],
    CAST(CAST(SUM(r.[is_readmission]) AS DECIMAL(18,2)) / 
        (SELECT COUNT(*) FROM analytics.fact_clinical_events WHERE event_type = 'ENCOUNTER') * 100 AS DECIMAL(18,2)) AS [Global Readmission Rate (%)]
FROM FlaggedReadmissions r;
GO


--Ticket 2: Revenue Cycle Financial Leakage Diagnostic

USE [healthcare_dw];
GO

SELECT 
    -- Clean up text formatting and handle empty/blank method entries smoothly
    CASE 
        WHEN [method] IS NULL OR [method] = '' THEN 'UNSPECIFIED / RECONCILING'
        ELSE UPPER([method]) 
    END AS [Collection Method],
    UPPER([type]) AS [Transaction Type],
    COUNT(*) AS [Total Line Items Processed],
    
    -- Calculate aggregate financial summaries
    SUM(TRY_CAST([amount] AS DECIMAL(18,2))) AS [Gross Transaction Volume ($)],
    AVG(TRY_CAST([amount] AS DECIMAL(18,2))) AS [Average Line Item Value ($)],
    SUM(TRY_CAST([outstanding] AS DECIMAL(18,2))) AS [Remaining Outstanding Balance ($)]
FROM [healthcare_dw].[dbo].[stg_claims_transactions]
WHERE [id] IS NOT NULL
GROUP BY [method], [type]
ORDER BY [Remaining Outstanding Balance ($)] DESC, [Gross Transaction Volume ($)] DESC;
GO