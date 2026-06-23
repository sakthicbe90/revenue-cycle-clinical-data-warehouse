--Two main initial steps followed for all files, created a table to import the file in right format and exstracted metadata deatils for preparation of data dcitionary--
--Table 1:Create a table with the exact column order from the "allergies" CSV file
CREATE TABLE [healthcare_dw].[dbo].[stg_allergies] (
    [start]        VARCHAR(50) NULL,
    [stop]         VARCHAR(50) NULL,
    [patient]      VARCHAR(100) NULL,
    [encounter]    VARCHAR(100) NULL,
    [code]         VARCHAR(50) NULL,
    [system]       VARCHAR(100) NULL,
    [description]  VARCHAR(255) NULL,
    [type]         VARCHAR(50) NULL,
    [category]     VARCHAR(50) NULL,
    [reaction1]    VARCHAR(50) NULL,
    [description1] VARCHAR(255) NULL,
    [severity1]    VARCHAR(50) NULL,
    [reaction2]    VARCHAR(50) NULL,
    [description2] VARCHAR(255) NULL,
    [severity2]    VARCHAR(50) NULL
);

--Extracting all column details to add in data catalog 
SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    -- If max_length is -1, it means MAX size (e.g., varchar(max))
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description] -- Left blank for your Excel documentation
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_allergies' -- Filters for your staging table
ORDER BY t.name, c.column_id;

--Table 2: careplans.csv--
CREATE TABLE [healthcare_dw].[dbo].[stg_careplans] (
    [id]           VARCHAR(100) NULL,
    [start]        VARCHAR(50)  NULL,
    [stop]         VARCHAR(50)  NULL,
    [patient]      VARCHAR(100) NULL,
    [encounter]    VARCHAR(100) NULL,
    [code]         VARCHAR(50)  NULL,
    [description]  VARCHAR(255) NULL,
    [reasoncode]   VARCHAR(50)  NULL,
    [reasondescr]  VARCHAR(255) NULL
);

ALTER TABLE [healthcare_dw].[dbo].[stg_careplans] 
ALTER COLUMN [description] VARCHAR(MAX);

ALTER TABLE [healthcare_dw].[dbo].[stg_careplans] 
ALTER COLUMN [reasondescr] VARCHAR(MAX);

---metadat---
SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description] -- For your manual analyst notes
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_careplans' -- Filters specifically for your careplans table
ORDER BY t.name, c.column_id;


---Table 3:claims.csv----
CREATE TABLE [healthcare_dw].[dbo].[stg_claims] (
    [id]                                VARCHAR(100) NULL,
    [patientid]                         VARCHAR(100) NULL,
    [providerid]                        VARCHAR(100) NULL,
    [primarypayer]                      VARCHAR(100) NULL,
    [secondarypayer]                    VARCHAR(100) NULL,
    [departmentid]                        VARCHAR(100) NULL,
    [patientdepartmentid]                 VARCHAR(100) NULL,
    [diagnosis1]                        VARCHAR(50)  NULL,
    [diagnosis2]                        VARCHAR(50)  NULL,
    [diagnosis3]                        VARCHAR(50)  NULL,
    [diagnosis4]                        VARCHAR(50)  NULL,
    [diagnosis5]                        VARCHAR(50)  NULL,
    [diagnosis6]                        VARCHAR(50)  NULL,
    [diagnosis7]                        VARCHAR(50)  NULL,
    [diagnosis8]                        VARCHAR(50)  NULL,
    [referringprovider]                 VARCHAR(100) NULL,
    [appointmentid]                     VARCHAR(100) NULL,
    [currentstatus]                     VARCHAR(50)  NULL,
    [servicedate]                       VARCHAR(50)  NULL,
    [supervisingprovider]               VARCHAR(100) NULL,
    [status1]                           VARCHAR(50)  NULL,
    [status2]                           VARCHAR(50)  NULL,
    [statusp]                           VARCHAR(50)  NULL,
    [outstanding1]                      VARCHAR(100) NULL,
    [outstanding2]                      VARCHAR(100) NULL,
    [outstandingp]                      VARCHAR(100) NULL,
    [lastbilleddate1]                   VARCHAR(50)  NULL,
    [lastbilleddate2]                   VARCHAR(50)  NULL,
    [lastbilleddatep]                   VARCHAR(50)  NULL,
    [healthcareclaimtypeid1]            VARCHAR(50)  NULL,
    [claimtypeid2]                      VARCHAR(50)  NULL
);

----metadata---
SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description]
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_claims'
ORDER BY t.name, c.column_id;

---Table 4 claims_transactions.csv import stesp-----

IF OBJECT_ID('[healthcare_dw].[dbo].[stg_claims_transactions]', 'U') IS NOT NULL
    DROP TABLE [healthcare_dw].[dbo].[stg_claims_transactions];

-- Create the staging table matching the transaction file structure
CREATE TABLE [healthcare_dw].[dbo].[stg_claims_transactions] (
    [id]                        VARCHAR(100) NULL,
    [claimid]                   VARCHAR(100) NULL,
    [chargeid]                  VARCHAR(100) NULL,
    [patientid]                 VARCHAR(100) NULL,
    [type]                      VARCHAR(50)  NULL,
    [amount]                    VARCHAR(100) NULL,
    [method]                    VARCHAR(50)  NULL,
    [fromdate]                  VARCHAR(50)  NULL,
    [todate]                    VARCHAR(50)  NULL,
    [placeofservice]            VARCHAR(100) NULL,
    [procedure]                 VARCHAR(100) NULL,
    [modifier1]                 VARCHAR(50)  NULL,
    [modifier2]                 VARCHAR(50)  NULL,
    [diagnosisr1]               VARCHAR(50)  NULL,
    [diagnosisr2]               VARCHAR(50)  NULL,
    [diagnosisr3]               VARCHAR(50)  NULL,
    [diagnosisr4]               VARCHAR(50)  NULL,
    [units]                     VARCHAR(50)  NULL,
    [department]                VARCHAR(100) NULL,
    [notes]                     VARCHAR(255) NULL,
    [unitamount]                VARCHAR(100) NULL,
    [transferout]               VARCHAR(100) NULL,
    [transferin]                VARCHAR(100) NULL,
    [paymentin]                 VARCHAR(100) NULL,
    [adjustment]                VARCHAR(100) NULL,
    [transferout2]              VARCHAR(100) NULL,
    [outstanding]               VARCHAR(100) NULL,
    [appointmentid]             VARCHAR(100) NULL,
    [linenumber]                VARCHAR(50)  NULL,
    [patientinsuranceid]        VARCHAR(100) NULL,
    [feeschedule]               VARCHAR(100) NULL,
    [providerid]                VARCHAR(100) NULL,
    [supervisingproviderid]     VARCHAR(100) NULL
);

ALTER TABLE [healthcare_dw].[dbo].[stg_claims_transactions] 
ALTER COLUMN [notes] VARCHAR(MAX);

ALTER TABLE [healthcare_dw].[dbo].[stg_claims_transactions] 
ALTER COLUMN [procedure] VARCHAR(MAX);

TRUNCATE TABLE [healthcare_dw].[dbo].[stg_claims_transactions];

--metadata for table 4---

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description]
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_claims_transactions'
ORDER BY t.name, c.column_id;

---Table 5 conditions.csv import stesp-----

-- Create the staging table matching the conditions file structure
CREATE TABLE [healthcare_dw].[dbo].[stg_conditions] (
    [start]        VARCHAR(50)  NULL,
    [stop]         VARCHAR(50)  NULL,
    [patient]      VARCHAR(100) NULL,
    [encounter]    VARCHAR(100) NULL,
    [code]         VARCHAR(50)  NULL,
    [description]  VARCHAR(MAX) NULL -- Proactively set to MAX to avoid truncation crashes
);

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description] -- For your manual analyst notes
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_conditions'
ORDER BY t.name, c.column_id;

----Table 6:Create the staging table matching the devices file structure
CREATE TABLE [healthcare_dw].[dbo].[stg_devices] (
    [start]        VARCHAR(50)  NULL,
    [stop]         VARCHAR(50)  NULL,
    [patient]      VARCHAR(100) NULL,
    [encounter]    VARCHAR(100) NULL,
    [code]         VARCHAR(50)  NULL,
    [description]  VARCHAR(MAX) NULL, -- Protects against long medical descriptions
    [udi]          VARCHAR(255) NULL  -- Unique Device Identifier barcode strings
);

---data dictionary extraction script---

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description] -- Left blank for your analyst documentation notes
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_devices'
ORDER BY t.name, c.column_id;

-- Table 7:Create the staging table matching the encounters file structure
CREATE TABLE [healthcare_dw].[dbo].[stg_encounters] (
    [id]                   VARCHAR(100) NULL,
    [start]                VARCHAR(50)  NULL,
    [stop]                 VARCHAR(50)  NULL,
    [patient]              VARCHAR(100) NULL,
    [organization]         VARCHAR(100) NULL,
    [provider]             VARCHAR(100) NULL,
    [payer]                VARCHAR(100) NULL,
    [encounterclass]       VARCHAR(50)  NULL,
    [code]                 VARCHAR(50)  NULL,
    [description]          VARCHAR(MAX) NULL, -- Protects against long clinical descriptions
    [base_encounter_cost]  VARCHAR(50)  NULL,
    [total_claim_cost]     VARCHAR(50)  NULL,
    [payer_coverage]       VARCHAR(50)  NULL,
    [reasoncode]           VARCHAR(50)  NULL,
    [reasondescription]    VARCHAR(MAX) NULL  -- Protects against long reason descriptions
);

--data dictionary extraction script---

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description] -- For your manual analyst notes
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_encounters'
ORDER BY t.name, c.column_id;

--Table 8: Create the staging table matching your file columns
CREATE TABLE [healthcare_dw].[dbo].[stg_imaging_studies] (
    [id]                 VARCHAR(100) NULL,
    [date]               VARCHAR(50)  NULL,
    [patient]            VARCHAR(100) NULL,
    [encounter]          VARCHAR(100) NULL,
    [series_uid]         VARCHAR(100) NULL,
    [bodysite_code]         VARCHAR(50)  NULL, -- maps to bodysite_code
    [bodysite_desc]         VARCHAR(MAX) NULL, -- maps to bodysite_description
    [modality_code]         VARCHAR(50)  NULL, -- maps to modality_code
    [modality_desc]         VARCHAR(MAX) NULL, -- maps to modality_description
    [instance_uid]         VARCHAR(100) NULL, -- maps to instance_uid
    [sop_code]           VARCHAR(50)  NULL,
    [sop_desc]         VARCHAR(MAX) NULL, -- maps to sop_description
    [procedure_code]     VARCHAR(50)  NULL
);
--data dictionary extraction script---
SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description]
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_imaging_studies'
ORDER BY t.name, c.column_id;

-- Table 9:Create the staging table matching the immunizations file structure
CREATE TABLE [healthcare_dw].[dbo].[stg_immunizations] (
    [date]         VARCHAR(50)  NULL,
    [patient]      VARCHAR(100) NULL,
    [encounter]    VARCHAR(100) NULL,
    [code]         VARCHAR(50)  NULL,
    [description]  VARCHAR(MAX) NULL, -- Protects against long vaccine names
    [base_cost]    VARCHAR(50)  NULL
);

--data dictionary extraction script---
SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description] -- For your manual analyst notes
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_immunizations'
ORDER BY t.name, c.column_id;

-- Table 10:Create the staging table matching your file columns
CREATE TABLE [healthcare_dw].[dbo].[stg_medications] (
    [start]              VARCHAR(50)  NULL,
    [stop]               VARCHAR(50)  NULL,
    [patient]            VARCHAR(100) NULL,
    [payer]              VARCHAR(100) NULL,
    [encounter]          VARCHAR(100) NULL,
    [code]               VARCHAR(50)  NULL,
    [description]        VARCHAR(MAX) NULL, -- maps to descriptio
    [base_cost]          VARCHAR(50)  NULL,
    [payer_coverage]     VARCHAR(50)  NULL, -- maps to payer_cove
    [dispenses]          VARCHAR(50)  NULL,
    [totalcost]          VARCHAR(50)  NULL,
    [reasoncode]         VARCHAR(50)  NULL, -- maps to reasoncod
    [reasondescription]  VARCHAR(MAX) NULL  -- maps to reasondes
);

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description]
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_medications'
ORDER BY t.name, c.column_id;

-- Table 11:Create the staging table matching the observations file structure
CREATE TABLE [healthcare_dw].[dbo].[stg_observations] (
    [date]         VARCHAR(50)  NULL,
    [patient]      VARCHAR(100) NULL,
    [encounter]    VARCHAR(100) NULL,
	[category]	   VARCHAR(50)NULL,
    [code]         VARCHAR(50)  NULL,
    [description]  VARCHAR(MAX) NULL, -- Protects against long laboratory/vital names
    [value]        VARCHAR(MAX) NULL, -- Protects against mixed text/numeric results
    [units]        VARCHAR(50)  NULL, -- e.g., mg/dL, mmHg, %
    [type]         VARCHAR(50)  NULL  -- e.g., numeric vs text
);

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description] -- For your manual analyst notes
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_observations'
ORDER BY t.name, c.column_id;

--Table 12 : Create the staging table matching all 12 columns from your file layout
CREATE TABLE [healthcare_dw].[dbo].[stg_organizations] (
    [Id]          VARCHAR(100) NULL,
    [NAME]        VARCHAR(255) NULL,
    [ADDRESS]     VARCHAR(MAX) NULL,
    [CITY]        VARCHAR(255) NULL,
    [STATE]       VARCHAR(100) NULL,
    [ZIP]         VARCHAR(50)  NULL,
    [LAT]         VARCHAR(100) NULL,
    [LON]         VARCHAR(100) NULL,
    [PHONE]       VARCHAR(50)  NULL,
    [REVENUE]     VARCHAR(100) NULL,
    [UTILIZATION] VARCHAR(100) NULL,
    [location]    VARCHAR(255) NULL -- Added to capture the spatial WKT POINT text
);

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description]
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_organizations'
ORDER BY t.name, c.column_id;

--Table 13: Create the staging table matching all 27 columns from your exact file layout
CREATE TABLE [healthcare_dw].[dbo].[stg_patients] (
    [Id]                   VARCHAR(100) NULL,
    [BIRTHDATE]            VARCHAR(50)  NULL,
    [DEATHDATE]            VARCHAR(50)  NULL,
    [SSN]                  VARCHAR(50)  NULL,
    [DRIVERS]              VARCHAR(100) NULL,
    [PASSPORT]             VARCHAR(100) NULL,
    [PREFIX]               VARCHAR(50)  NULL,
    [FIRST]                VARCHAR(255) NULL,
    [LAST]                 VARCHAR(255) NULL,
    [SUFFIX]               VARCHAR(50)  NULL,
    [MAIDEN]               VARCHAR(255) NULL,
    [MARITAL]              VARCHAR(50)  NULL,
    [RACE]                 VARCHAR(100) NULL,
    [ETHNICITY]            VARCHAR(100) NULL,
    [GENDER]               VARCHAR(50)  NULL,
    [BIRTHPLACE]           VARCHAR(MAX) NULL,
    [ADDRESS]              VARCHAR(MAX) NULL,
    [CITY]                 VARCHAR(255) NULL,
    [STATE]                VARCHAR(100) NULL,
    [COUNTY]               VARCHAR(255) NULL,
    [fips]                 VARCHAR(50)  NULL, -- Added to capture FIPS county codes
    [ZIP]                  VARCHAR(50)  NULL,
    [LAT]                  VARCHAR(100) NULL,
    [LON]                  VARCHAR(100) NULL,
    [healthcare]           VARCHAR(100) NULL, -- Tracks cumulative expenses
    [healthcare_coverage]  VARCHAR(100) NULL, -- Second 'healthcare' column mapped cleanly
    [income]               VARCHAR(100) NULL, -- Added to track patient income brackets
    [location]             VARCHAR(255) NULL  -- Added to capture spatial WKT POINT text
);

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description]
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_patients'
ORDER BY t.name, c.column_id;


--Table 14: Create the staging table matching all 8 columns from your exact file layout
CREATE TABLE [healthcare_dw].[dbo].[stg_payer_transitions] (
    [patient]        VARCHAR(100) NULL,
    [memberid]       VARCHAR(100) NULL,
    [start_date]     VARCHAR(50)  NULL,
    [end_date]       VARCHAR(50)  NULL,
    [payer]          VARCHAR(100) NULL,
    [secondary]      VARCHAR(100) NULL,
    [plan_ownership] VARCHAR(100) NULL, -- Maps to plan_owne
    [owner_name]     VARCHAR(255) NULL  -- Maps to owner_nam
);

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description]
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_payer_transitions'
ORDER BY t.name, c.column_id;

--Table 15: Create the staging table matching all 23 columns from your exact file layout
CREATE TABLE [healthcare_dw].[dbo].[stg_payers] (
    [id]                        VARCHAR(100) NULL,
    [name]                      VARCHAR(255) NULL,
    [ownership]                 VARCHAR(100) NULL, -- e.g., GOVERNMENT vs COMMERCIAL
    [address]                   VARCHAR(MAX) NULL,
    [city]                      VARCHAR(255) NULL,
    [state_headquarters]        VARCHAR(100) NULL, -- Maps to state_head
    [zip]                       VARCHAR(50)  NULL,
    [phone]                     VARCHAR(50)  NULL,
    [amount_contracted]         VARCHAR(100) NULL, -- Maps to amount_ct
    [amount_unreimbursed]       VARCHAR(100) NULL, -- Maps to amount_ur
    [revenue]                   VARCHAR(100) NULL,
    [covered_encounters]        VARCHAR(100) NULL, -- Maps to covered_e
    [uncovered_encounters]      VARCHAR(100) NULL, -- Maps to uncovered_
    [covered_medications]       VARCHAR(100) NULL, -- Maps to covered_m
    [uncovered_medications]     VARCHAR(100) NULL, -- Maps to uncovered_m
    [covered_procedures]        VARCHAR(100) NULL, -- Maps to covered_p
    [uncovered_procedures]      VARCHAR(100) NULL, -- Maps to uncovered_p
    [covered_immunizations]     VARCHAR(100) NULL, -- Maps to covered_im
    [uncovered_immunizations]   VARCHAR(100) NULL, -- Maps to uncovered_i
    [unique_customers]          VARCHAR(100) NULL, -- Maps to unique_cus
    [qols_avg]                  VARCHAR(50)  NULL, -- Quality of Life Score Average
    [member_months]             VARCHAR(50)  NULL
);

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description]
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_payers'
ORDER BY t.name, c.column_id;

--Table 16: Create the staging table matching the procedures file structure
CREATE TABLE [healthcare_dw].[dbo].[stg_procedures] (
    [start]              VARCHAR(50)  NULL,
    [stop]               VARCHAR(50)  NULL,
    [patient]            VARCHAR(100) NULL,
    [encounter]          VARCHAR(100) NULL,
    [code]               VARCHAR(50)  NULL,
    [description]        VARCHAR(MAX) NULL, -- Protects against long surgical/diagnostic terms
    [base_cost]          VARCHAR(50)  NULL,
    [reasoncode]         VARCHAR(50)  NULL,
    [reasondescription]  VARCHAR(MAX) NULL  -- Protects against long reason descriptions
);

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description] -- For your manual analyst notes
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_procedures'
ORDER BY t.name, c.column_id;

--Table 17: Create the staging table matching all 14 columns from your exact file layout
CREATE TABLE [healthcare_dw].[dbo].[stg_providers] (
    [id]            VARCHAR(100) NULL,
    [organization]  VARCHAR(100) NULL, -- Maps to organizatio
    [name]          VARCHAR(255) NULL,
    [gender]        VARCHAR(50)  NULL,
    [specialty]     VARCHAR(255) NULL, -- Maps to speciality
    [address]       VARCHAR(MAX) NULL,
    [city]          VARCHAR(255) NULL,
    [state]         VARCHAR(100) NULL,
    [zip]           VARCHAR(50)  NULL,
    [lat]           VARCHAR(100) NULL,
    [lon]           VARCHAR(100) NULL,
    [utilization]   VARCHAR(100) NULL, -- Encounters handled by this provider
    [location]      VARCHAR(255) NULL  -- Added to capture spatial WKT POINT text
);

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description]
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_providers'
ORDER BY t.name, c.column_id;

--Table 18: Create the staging table matching the supplies file headers
CREATE TABLE [healthcare_dw].[dbo].[stg_supplies] (
    [date]         VARCHAR(50)  NULL,
    [patient]      VARCHAR(100) NULL,
    [encounter]    VARCHAR(100) NULL,
    [code]         VARCHAR(50)  NULL,
    [description]  VARCHAR(MAX) NULL, -- Protects against long medical device/supply names
    [quantity]     VARCHAR(50)  NULL
);

SELECT 
    t.name AS [Table Name],
    c.name AS [Column Name],
    ty.name AS [Data Type],
    CASE 
        WHEN ty.name IN ('varchar', 'char', 'nvarchar') THEN CAST(c.max_length AS VARCHAR)
        ELSE 'N/A'
    END AS [Max Length (Bytes)],
    CASE 
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS [Allows NULLs],
    '' AS [Healthcare Meaning / Description] -- For your manual analyst notes
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name = 'stg_supplies'
ORDER BY t.name, c.column_id;