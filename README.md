# Revenue-cycle-clinical-data-warehouse
A comprehensive 5-day professional simulation mimicking an enterprise Healthcare Data Analyst role. Transitions banking ETL data discipline into healthcare data governance, clinical diagnostics, and Revenue Cycle Management (RCM).

📌 Project Overview:

This project simulates a realistic, high-pressure five-day work week for a Healthcare Data Analyst working within a provider hospital network. Instead of focusing on a single, isolated dashboard, this portfolio piece demonstrates the end-to-end execution of structured sprint goals, urgent ad-hoc business requests, data quality auditing, and executive clinical storytelling.
Transitioning from a background in Banking ETL Development, this project bridges the gap between backend data pipeline architecture and frontline healthcare business intelligence. It applies rigorous financial reconciliation principles to clinical, operational, and billing data structures.

🛠️ The Business Scenario
You are the primary Data Analyst assigned to a regional healthcare system. Throughout the week, you receive cross-functional tickets from the Chief Medical Officer (CMO), Director of Hospital Operations, and the Revenue Cycle Finance Team.
The project utilizes a 18-table relational enterprise schema containing synthetic electronic health records (EHR), patient encounter lifecycles, clinical diagnosis codes (SNOMED/ICD-10), and insurance claims ledgers.

📅 The 5-Day Sprint Itinerary
• Day 1 Execution: Enterprise Data Ingestion & Governance
Bypassed standard spreadsheet formatting limitations (e.g., Excel corrupting alphanumeric clinical keys into scientific notation) by establishing a local SQL staging layer. Developed a comprehensive Enterprise Data Dictionary.
• Day 2: Dimensional Modeling & Schema Architecture
Design and deploy an optimized relational Star Schema (analytics schema) in SQL Server to separate transactional processes from contextual lookup data.
• Day 3: Revenue Cycle & Claims Leakage Analysis
Identified financial data leaks by cross-referencing completed patient encounters with insurance claim payouts to pinpoint unbilled medical procedures.
• Day 4: Automated Data Quality & Reconciliation Audit
Applied banking-grade audit practices to the data pipeline. Wrote an exception-reporting script to catch invalid medical codes and financial imbalances where Billed_Amount \(\ne \) Insurance_Paid + Patient_Responsibility.
• Day 5: Executive Clinical Dashboard & Presentation
Translated backend query outputs into a high-impact, interactive visual dashboard for non-technical hospital administrators, concluding with strategic recommendations to reduce 30-day patient readmission rates.

📂 Day 1 Execution: Enterprise Data Ingestion & Governance
1. The Strategy: Staging Area Architecture
To mimic an enterprise Data Warehouse environment, a dedicated Staging Layer (dbo / staging) was established inside SQL Server. All raw CSV files were imported using a "Blind Copy" methodology:
• Every column was intentionally mapped as a nullable text field (VARCHAR) with NULL constraints enabled.
• The Technical Reason: This safeguards the ingestion pipeline. Forcing strict data formats (like DATE or INT) during a raw file dump causes immediate data truncation and load failures when encountering empty fields (such as missing stop dates for active allergies) or complex text delimiters. By dumping raw data cleanly first, data validation can happen safely inside the database engine. [1]
2. Overcoming Data Corruption (Excel vs. SQL Server)
Initial exploratory data profiling in spreadsheet software revealed significant formatting corruption:
• Standard spreadsheet engines truncated long alphanumeric strings and converted critical medical taxonomy keys (such as SNOMED diagnosis codes) into unreadable scientific notation (e.g., 2.64E+08).
• To preserve absolute data integrity, the ingestion pipeline bypassed spreadsheet tools entirely. A custom text qualifier layout using double quotes (") and comma delimiters (,) was configured inside the database engine. This successfully aligned shifted rows and allowed long healthcare UUID tracking tokens (for patient and encounter IDs) to load without truncation.
3. Automated Data Dictionary Extraction
To establish data governance before building analytics, a professional Data Dictionary was generated. Instead of manual data entry, schema metadata was extracted directly from the SQL Server system tables (sys.tables, sys.columns, and sys.types) using a dynamic extraction query.
This automated layout was exported to Excel to serve as the project's Master Data Catalog, mapping out field names, system data types, byte lengths, and nullable properties alongside analyst notes defining their specific healthcare business meanings.

📂 Day 2 : Schema Design & Dimensional Modeling
1. The Strategy: The Analytical Star Schema
To optimize our multi-table database for High-Performance Business Intelligence (Power BI/Tableau) and rapid analytical reporting, the 18 separate uncleaned staging tables were mapped into an optimized Star Schema data architecture.

This structural shift provides major advantages over flat files or transactional normalization (3NF):
• Query Performance Optimization: Separating high-frequency operational metrics from contextual data attributes eliminates heavy relational scan-loops and optimizes memory usage during massive calculations.
• Dashboard Speed: Direct 1-to-many star configurations completely eliminate performance-killing many-to-many lookup relationships or complex nested table logic inside Power BI.
• The Transaction Ledger Mindset: Drawing on my foundational background in Banking ETL Architecture, this mirrors a standard accounting system ledger. Central fact logs capture structural numeric changes (debits/credits/vitals), while the surrounding reference tables control master lookup descriptors.

2. The Architecture Components
📊 Central Fact Tables (The Process Metrics)
• analytics.fact_clinical_events (The Inpatient Operations Ledger): Stacks and unifies discrete event tracking timelines across encounters, medical diagnoses, surgical actions, and vaccine distributions into a single sequential table.
• analytics.fact_claims_financials (The Revenue Cycle Engine): Holds granular, itemized transaction balances tracking gross charges, insurance payouts, claims adjustments, and patient liability amounts.
• analytics.fact_observations (The Clinical Value Log): Captures multi-row clinical attributes like lab results and biometric vital sign tracks.

🗂️ Surrounding Dimension Tables (The Contextual Metadata)
• analytics.dim_patients: The single source of truth for patient demographics, master record keys, and financial baseline values.
• analytics.dim_providers & analytics.dim_organizations: Tracks hospital networks, treating clinician metrics, specialties, and geographic facility tags.
• analytics.dim_payers: Evaluates commercial and governmental insurance configurations alongside aggregated membership numbers.
• analytics.dim_medical_codes: Houses standardized international classifications (SNOMED, CPT, CVX, RxNorm).

3. Data Integrity & Constraint Engineering
Rather than leaving the data model unconstrained, strict enterprise database engineering standards were applied via pure T-SQL pipelines:

1. Data Type Purifications: Raw, volatile text files (VARCHAR) were cast into mathematically calculable data structures (DECIMAL(18,2)) and indexed calendar values (DATE/DATETIME) utilizing defensive TRY_CAST exception routing.
2. Composite Primary Key Resolution: Discovery of cross-functional code overlaps (e.g., identical numeric strings utilized for both clinical conditions and medical procedures) was managed by implementing a custom Composite Primary Key constraint combining (code_key, code_type). This safeguarded the warehouse from key collision pipeline failures.
3. Referential Integrity Constraints: Foreign Key constraints (FK) were established across all relational table bridges, locking in parent-child relationship structures and keeping dirty or unlinked orphan records from skewing corporate revenue reports.
 4. Automated Data Quality Ingestion & Reconciliation Audit
Before exposing an analytics environment to frontend dashboards, an enterprise-grade Data Quality (DQ) Profiling Script was executed. This automated warehouse audit validates row metrics, verifies primary key uniqueness, and catches structural anomalies.

<img width="1446" height="1520" alt="schema_diagram" src="https://github.com/user-attachments/assets/9c6896d7-fba7-4d67-b98d-a988d17c6238" />


📂 Day 3 : Tickets 
🎟️ Ticket 1: 30-Day Hospital Readmission Velocity Diagnostic
1. The Business Ticket Question (The Request)
	From: Chief Medical Officer (CMO)
	To: Lead Healthcare Data Analyst
	Subject: Urgent: High-Priority 30-Day Readmission Analysis
	"We are tracking a noticeable surge in patients returning to our hospital network shortly after being discharged. This pattern threatens our quality-of-care scores and exposes us to heavy regulatory financial penalties. I need a clear diagnostic report detailing our global 30-Day Readmission Rate. Please isolate the exact volume of repeat encounters occurring within a strict 30-day post-discharge window so we can evaluate the performance of our transitional outpatient care."

2. Analytical & Technical Approach
To calculate this healthcare quality metric efficiently without crushing database performance, the solution bypassed expensive, resource-heavy self-joins on a multi-thousand-row transaction table.
Instead, the pipeline was engineered using an advanced T-SQL Analytic Window Function:
4. LAG() OVER (PARTITION BY patient_key ORDER BY event_date): This function isolates every individual patient's treatment timeline, scans chronological visits sequentially, and pulls the exact timestamp of their previous encounter onto the current record row.
5. DATEDIFF(day, previous, current): Measures the exact day intervals between consecutive medical visits.
6. Conditional Logic (CASE): Automatically flags any record with a gap interval of ≤ 30 days as a clinical readmission anomaly (1 else 0).
7. Aggregation Pass: Divides the total volume of 30-day readmissions by the absolute baseline encounter count to deliver a definitive corporate KPI percentage.

3. Executed Query Output (Data Artifact)
The analytical query processed the full transactional warehouse history and generated the following validated executive summary:
• Total Active Hospital Encounters: 5,227
• Total Documented 30-Day Readmissions: 2,051
• Global Readmission Rate: 39.24%




🎟️ Ticket 2: Revenue Cycle Financial Leakage & Collection Method Analysis
1. The Business Ticket Question (The Request)
	From: Director of Revenue Cycle Management
	To: Lead Healthcare Data Analyst
	Subject: High-Priority Financial Bottleneck Analysis
	"Our net collection rates are dropping, and outstanding patient/payer liabilities are accumulating in our accounts receivable ledger. I need an itemized diagnostic summary of our Claims Transactions Log. Aggregate our gross transactional volumes, average line-item values, and total outstanding balances grouped by Collection Method and Transaction Type. I need to isolate exactly which collection channels are failing to settle their accounts so we can optimize our billing workflows."

2. Analytical & Technical Approach
To provide clear insights for the finance team, the query scans the line-item transactional history inside the database warehouse layer:
1. Financial Type Purification: Leveraged defensive TRY_CAST routing to map raw text-based financial attributes cleanly into high-precision DECIMAL(18,2) currency fields. This prevents rounding errors when processing thousands of transaction entries.
2. Text Standardization: Utilized UPPER() and conditional string handling (CASE WHEN) to catch empty, blank, or improperly formatted data rows, consolidating disparate records into clean administrative buckets.
3. Multi-Field Aggregation: Grouped data simultaneously by transaction method and type to evaluate collection efficiency, sorting results by total remaining outstanding balances to put the highest financial leak right at the top of the report.

3. 📊 Executed Financial Ledger Output (Data Artifact)
The analytical query processed all 61,399 transaction ledger lines and generated the following prioritized collection efficiency summary:


<img width="1199" height="302" alt="tikcet2" src="https://github.com/user-attachments/assets/64268a0b-58a6-4e7b-8630-4463c0dd23af" />

