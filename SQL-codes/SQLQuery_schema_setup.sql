-- =========================================================================
-- 1. DIMENSION TABLES (Master Reference Tables)
-- =========================================================================

USE [healthcare_dw];
GO
CREATE SCHEMA [analytics];
GO

CREATE TABLE analytics.dim_patients (
    [patient_key]         VARCHAR(100) NOT NULL PRIMARY KEY,
    [birth_date]          DATE NULL,
    [death_date]          DATE NULL,
    [ssn]                 VARCHAR(50) NULL,
    [first_name]          VARCHAR(255) NULL,
    [last_name]           VARCHAR(255) NULL,
    [marital_status]      VARCHAR(50) NULL,
    [race]                VARCHAR(100) NULL,
    [ethnicity]           VARCHAR(100) NULL,
    [gender]              VARCHAR(50) NULL,
    [income]              DECIMAL(18,2) NULL,
    [city]                VARCHAR(255) NULL,
    [state]               VARCHAR(100) NULL,
    [county]              VARCHAR(255) NULL
);

CREATE TABLE analytics.dim_providers (
    [provider_key]        VARCHAR(100) NOT NULL PRIMARY KEY,
    [organization_id]     VARCHAR(100) NULL,
    [provider_name]       VARCHAR(255) NULL,
    [gender]              VARCHAR(50) NULL,
    [specialty]           VARCHAR(255) NULL
);

CREATE TABLE analytics.dim_organizations (
    [organization_key]    VARCHAR(100) NOT NULL PRIMARY KEY,
    [facility_name]       VARCHAR(255) NULL,
    [city]                VARCHAR(255) NULL,
    [state]               VARCHAR(100) NULL,
    [zip]                 VARCHAR(50) NULL,
    [location_wkt]        VARCHAR(255) NULL
);

CREATE TABLE analytics.dim_payers (
    [payer_key]           VARCHAR(100) NOT NULL PRIMARY KEY,
    [payer_name]          VARCHAR(255) NULL,
    [ownership_type]      VARCHAR(100) NULL,
    [revenue]             DECIMAL(18,2) NULL,
    [unique_customers]    INT NULL
);

CREATE TABLE analytics.dim_medical_codes (
    [code_key]            VARCHAR(50) NOT NULL, 
    [code_type]           VARCHAR(50) NOT NULL, 
    [code_description]    VARCHAR(MAX) NULL,
    CONSTRAINT PK_dim_medical_codes PRIMARY KEY (code_key, code_type)
);


-- =========================================================================
-- 2. FACT TABLES (Central Transactional Tables with Foreign Key Constraints)
-- =========================================================================

CREATE TABLE analytics.fact_clinical_events (
    [event_id]               INT IDENTITY(1,1) PRIMARY KEY,
    [encounter_id]           VARCHAR(100) NOT NULL,
    [patient_key]            VARCHAR(100) NOT NULL,
    [provider_key]           VARCHAR(100) NULL,
    [organization_key]       VARCHAR(100) NULL,
    [event_date]             DATETIME NOT NULL,
    [event_type]             VARCHAR(50) NOT NULL, 
    [medical_code]           VARCHAR(50) NULL,
    [base_cost]              DECIMAL(18,2) DEFAULT 0.00,
    
    CONSTRAINT FK_clinical_patient FOREIGN KEY (patient_key) REFERENCES analytics.dim_patients(patient_key),
    CONSTRAINT FK_clinical_provider FOREIGN KEY (provider_key) REFERENCES analytics.dim_providers(provider_key),
    CONSTRAINT FK_clinical_organization FOREIGN KEY (organization_key) REFERENCES analytics.dim_organizations(organization_key)
);
GO

CREATE TABLE analytics.fact_claims_financials (
    [transaction_id]         VARCHAR(100) NOT NULL PRIMARY KEY,
    [claim_id]               VARCHAR(100) NOT NULL,
    [patient_key]            VARCHAR(100) NOT NULL,
    [provider_key]           VARCHAR(100) NULL,
    [payer_key]              VARCHAR(100) NULL,
    [service_date]           DATE NULL,
    [transaction_type]       VARCHAR(50) NULL,  -- e.g., 'CHARGE', 'PAYMENT', 'ADJUSTMENT'
    [transaction_amount]     DECIMAL(18,2) DEFAULT 0.00,
    [outstanding_balance]    DECIMAL(18,2) DEFAULT 0.00,
    
    -- Relationships (Foreign Key constraints)
    CONSTRAINT FK_claims_patient FOREIGN KEY (patient_key) REFERENCES analytics.dim_patients(patient_key),
    CONSTRAINT FK_claims_provider FOREIGN KEY (provider_key) REFERENCES analytics.dim_providers(provider_key),
    CONSTRAINT FK_claims_payer FOREIGN KEY (payer_key) REFERENCES analytics.dim_payers(payer_key)
);

CREATE TABLE analytics.fact_observations (
    [observation_id]         INT IDENTITY(1,1) PRIMARY KEY,
    [encounter_id]           VARCHAR(100) NOT NULL,
    [patient_key]            VARCHAR(100) NOT NULL,
    [observation_date]       DATETIME NOT NULL,
    [observation_code]       VARCHAR(50) NOT NULL,
    [result_value]           VARCHAR(MAX) NULL, -- Raw mixed alpha-numeric text result
    [result_numeric]         DECIMAL(18,4) NULL, -- Purified numeric value for calculations
    [measurement_units]      VARCHAR(50) NULL,
    
    -- Relationships (Foreign Key constraints)
    CONSTRAINT FK_obs_patient FOREIGN KEY (patient_key) REFERENCES analytics.dim_patients(patient_key),
    CONSTRAINT FK_obs_code FOREIGN KEY (observation_code) REFERENCES analytics.dim_medical_codes(code_key)
);
GO

-- 1. Populate dim_patients
INSERT INTO analytics.dim_patients
SELECT 
    Id, TRY_CAST(BIRTHDATE AS DATE), TRY_CAST(DEATHDATE AS DATE), SSN, FIRST, LAST, MARITAL, RACE, ETHNICITY, GENDER,
    TRY_CAST(income AS DECIMAL(18,2)), CITY, STATE, COUNTY
FROM [healthcare_dw].[dbo].[stg_patients];

-- 2. Populate dim_providers
INSERT INTO analytics.dim_providers
SELECT id, organization, name, gender, specialty
FROM [healthcare_dw].[dbo].[stg_providers];

-- 3. Populate dim_organizations
INSERT INTO analytics.dim_organizations
SELECT Id, NAME, CITY, STATE, ZIP, location
FROM [healthcare_dw].[dbo].[stg_organizations];

-- 4. Populate dim_payers
INSERT INTO analytics.dim_payers
SELECT id, name, ownership, TRY_CAST(revenue AS DECIMAL(18,2)), TRY_CAST(unique_customers AS INT)
FROM [healthcare_dw].[dbo].[stg_payers];

-- 5. Populate dim_medical_codes (Consolidating reference codes from across files)
INSERT INTO analytics.dim_medical_codes (code_key, code_type, code_description)
SELECT raw_code, code_type, MIN(raw_description) AS code_description
FROM (
    -- Conditions Table Mapping
    SELECT DISTINCT [code] AS raw_code, 'DIAGNOSIS' AS code_type, [description] AS raw_description 
    FROM [healthcare_dw].[dbo].[stg_conditions] 
    WHERE [code] IS NOT NULL

    UNION ALL

    -- Procedures Table Mapping
    SELECT DISTINCT [code] AS raw_code, 'PROCEDURE' AS code_type, [description] AS raw_description 
    FROM [healthcare_dw].[dbo].[stg_procedures] 
    WHERE [code] IS NOT NULL

    UNION ALL

    -- Medications Table Mapping
    SELECT DISTINCT [code] AS raw_code, 'MEDICATION' AS code_type, [description] AS raw_description 
    FROM [healthcare_dw].[dbo].[stg_medications] 
    WHERE [code] IS NOT NULL

    UNION ALL

    -- Immunizations Table Mapping
    SELECT DISTINCT [code] AS raw_code, 'VACCINE' AS code_type, [description] AS raw_description 
    FROM [healthcare_dw].[dbo].[stg_immunizations] 
    WHERE [code] IS NOT NULL
) AS unified_source
GROUP BY raw_code, code_type;
GO
-- 6. Populate fact_clinical_events (Merging and stacking timelines)

INSERT INTO analytics.fact_clinical_events (
    encounter_id, 
    patient_key, 
    provider_key, 
    organization_key, 
    event_date, 
    event_type, 
    medical_code, 
    base_cost
)

-- SECTION A: Ingest core operational encounters
SELECT 
    [id] AS encounter_id,
    [patient] AS patient_key,
    [provider] AS provider_key,
    [organization] AS organization_key,
    TRY_CAST([start] AS DATETIME) AS event_date,
    'ENCOUNTER' AS event_type,
    [code] AS medical_code,
    TRY_CAST([base_encounter_cost] AS DECIMAL(18,2)) AS base_cost
FROM [healthcare_dw].[dbo].[stg_encounters]
WHERE [id] IS NOT NULL

UNION ALL

-- SECTION B: Ingest diagnosed clinical conditions
SELECT 
    [encounter] AS encounter_id,
    [patient] AS patient_key,
    NULL AS provider_key,      -- Inherited from the parent encounter table during reporting
    NULL AS organization_key,  -- Inherited from the parent encounter table during reporting
    TRY_CAST([start] AS DATETIME) AS event_date,
    'CONDITION' AS event_type,
    [code] AS medical_code,
    0.00 AS base_cost          -- Clinical conditions do not carry individual item costs
FROM [healthcare_dw].[dbo].[stg_conditions]
WHERE [encounter] IS NOT NULL 
  AND [patient] IS NOT NULL

UNION ALL

-- SECTION C: Ingest surgical and medical procedures
SELECT 
    [encounter] AS encounter_id,
    [patient] AS patient_key,
    NULL AS provider_key,
    NULL AS organization_key,
    TRY_CAST([start] AS DATETIME) AS event_date,
    'PROCEDURE' AS event_type,
    [code] AS medical_code,
    TRY_CAST([base_cost] AS DECIMAL(18,2)) AS base_cost
FROM [healthcare_dw].[dbo].[stg_procedures]
WHERE [encounter] IS NOT NULL 
  AND [patient] IS NOT NULL

UNION ALL

-- SECTION D: Ingest administered immunizations/vaccines
SELECT 
    [encounter] AS encounter_id,
    [patient] AS patient_key,
    NULL AS provider_key,
    NULL AS organization_key,
    TRY_CAST([date] AS DATETIME) AS event_date,
    'IMMUNIZATION' AS event_type,
    [code] AS medical_code,
    TRY_CAST([base_cost] AS DECIMAL(18,2)) AS base_cost
FROM [healthcare_dw].[dbo].[stg_immunizations]
WHERE [encounter] IS NOT NULL 
  AND [patient] IS NOT NULL;
GO

-- 7. Populate fact_claims_financials

INSERT INTO analytics.fact_claims_financials (
    [transaction_id],
    [claim_id],
    [patient_key],
    [provider_key],
    [payer_key],
    [service_date],
    [transaction_type],
    [transaction_amount],
    [outstanding_balance]
)
SELECT 
    [id] AS transaction_id,
    [claimid] AS claim_id,
    [patientid] AS patient_key,
    [providerid] AS provider_key,
    NULL AS payer_key, -- Left NULL here; will be populated from stg_claims during optimization step
    TRY_CAST([fromdate] AS DATE) AS service_date,
    UPPER([type]) AS transaction_type, -- Standardizes text (e.g., 'CHARGE', 'PAYMENT')
    TRY_CAST([amount] AS DECIMAL(18,2)) AS transaction_amount,
    TRY_CAST([outstanding] AS DECIMAL(18,2)) AS outstanding_balance
FROM [healthcare_dw].[dbo].[stg_claims_transactions]
-- Data Integrity Filter: Prevents blank entries from breaking your relational model
WHERE [id] IS NOT NULL 
  AND [claimid] IS NOT NULL
  AND [patientid] IS NOT NULL;
GO

-- 8. Populate fact_observations
INSERT INTO analytics.fact_observations (
    [encounter_id],
    [patient_key],
    [observation_date],
    [observation_code],
    [result_value],
    [result_numeric],
    [measurement_units]
)
SELECT 
    [encounter] AS encounter_id,
    [patient] AS patient_key,
    TRY_CAST([date] AS DATETIME) AS observation_date,
    [code] AS observation_code,
    [value] AS result_value, -- Keeps the original raw text/numeric result intact
    CASE 
        WHEN [type] = 'numeric' THEN TRY_CAST([value] AS DECIMAL(18,4)) 
        ELSE NULL 
    END AS result_numeric, -- Purifies numeric results to 4 decimal places for math
    [units] AS measurement_units
FROM [healthcare_dw].[dbo].[stg_observations]
-- Data Integrity Filter: Bypasses unlinked or incomplete observation logs
WHERE [encounter] IS NOT NULL
  AND [patient] IS NOT NULL
  AND [code] IS NOT NULL;
GO

USE [healthcare_dw];
GO


--audit query to check the size and health of our new warehouse tables
SELECT 
    'dim_patients' AS [Table Name], COUNT(*) AS [Row Count], COUNT(DISTINCT patient_key) AS [Unique Keys] FROM analytics.dim_patients
UNION ALL
SELECT 'dim_providers', COUNT(*), COUNT(DISTINCT provider_key) FROM analytics.dim_providers
UNION ALL
SELECT 'dim_organizations', COUNT(*), COUNT(DISTINCT organization_key) FROM analytics.dim_organizations
UNION ALL
SELECT 'dim_payers', COUNT(*), COUNT(DISTINCT payer_key) FROM analytics.dim_payers
UNION ALL
SELECT 'dim_medical_codes', COUNT(*), COUNT(*) FROM analytics.dim_medical_codes
UNION ALL
SELECT 'fact_clinical_events', COUNT(*), NULL FROM analytics.fact_clinical_events
UNION ALL
SELECT 'fact_claims_financials', COUNT(*), NULL FROM analytics.fact_claims_financials
UNION ALL
SELECT 'fact_observations', COUNT(*), NULL FROM analytics.fact_observations;
GO

USE [healthcare_dw];
GO

-- Step 1: Create a temporary storage table to hold our data quality profiling metrics
IF OBJECT_ID('tempdb..#NullProfileResults') IS NOT NULL
    DROP TABLE #NullProfileResults;

CREATE TABLE #NullProfileResults (
    [Schema Name]   VARCHAR(100),
    [Table Name]    VARCHAR(100),
    [Column Name]   VARCHAR(100),
    [Total Rows]    INT,
    [Null Count]    INT,
    [Null Pct (%)]  DECIMAL(18,2)
);

-- Step 2: Use a cursor to dynamically loop through the columns of our analytics warehouse layer
DECLARE @SchemaName VARCHAR(100), @TableName VARCHAR(100), @ColumnName VARCHAR(100);
DECLARE @SQL NVARCHAR(MAX);

DECLARE ColumnCursor CURSOR FOR
SELECT s.name, t.name, c.name
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON t.object_id = c.object_id
WHERE s.name = 'analytics' -- Focuses strictly on our clean analytical star schema
ORDER BY t.name, c.column_id;

OPEN ColumnCursor;
FETCH NEXT FROM ColumnCursor INTO @SchemaName, @TableName, @ColumnName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Construct a dynamic SQL statement to calculate counts and percentages for each field
    SET @SQL = '
        INSERT INTO #NullProfileResults
        SELECT 
            ''' + @SchemaName + ''',
            ''' + @TableName + ''',
            ''' + @ColumnName + ''',
            COUNT(*),
            SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + ' IS NULL THEN 1 ELSE 0 END),
            CAST(CAST(SUM(CASE WHEN ' + QUOTENAME(@ColumnName) + ' IS NULL THEN 1 ELSE 0 END) AS DECIMAL(18,2)) / COUNT(*) * 100 AS DECIMAL(18,2))
        FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ';';
        
    EXEC sp_executesql @SQL;
    
    FETCH NEXT FROM ColumnCursor INTO @SchemaName, @TableName, @ColumnName;
END;

CLOSE ColumnCursor;
DEALLOCATE ColumnCursor;

-- Step 3: Return the complete data profiling matrix, sorted by the highest data quality risk
SELECT * 
FROM #NullProfileResults
WHERE [Null Count] > 0 -- Filters to show columns that contain missing fields
ORDER BY [Null Pct (%)] DESC, [Table Name];
GO


