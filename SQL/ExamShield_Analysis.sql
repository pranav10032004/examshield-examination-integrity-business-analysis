-- ExamShield - PostgreSQL analysis script
-- Portfolio case study. Public evidence is source-backed; centre-operations data is synthetic.
-- Import the CSV files before running.

DROP TABLE IF EXISTS public_exam_evidence;
CREATE TABLE public_exam_evidence (
    event_id TEXT PRIMARY KEY,
    event_date DATE,
    geography TEXT,
    exam TEXT,
    event_category TEXT,
    event TEXT,
    pune_link TEXT,
    metric_1 NUMERIC,
    metric_2 NUMERIC,
    evidence_summary TEXT,
    source_id TEXT
);

-- Example COPY statements (adjust the file path for your local machine)
-- COPY public_exam_evidence FROM 'C:/path/ExamShield_Public_Evidence_Register.csv'
-- WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

DROP TABLE IF EXISTS illustrative_centre_operations;
CREATE TABLE illustrative_centre_operations (
    centre_id TEXT,
    city TEXT,
    state TEXT,
    exam_date DATE,
    exam_type TEXT,
    candidates_assigned INT,
    attendance_pct NUMERIC,
    cctv_uptime_pct NUMERIC,
    biometric_exception_pct NUMERIC,
    network_downtime_min INT,
    frisking_compliance_pct NUMERIC,
    chain_of_custody_pct NUMERIC,
    staff_attendance_pct NUMERIC,
    incident_count INT,
    complaint_count INT,
    incident_response_hours NUMERIC,
    proposed_risk_score NUMERIC,
    risk_band TEXT,
    priority_action TEXT,
    data_status TEXT
);

-- COPY illustrative_centre_operations FROM 'C:/path/ExamShield_Illustrative_Centre_Operations.csv'
-- WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- 1. Public evidence by year
SELECT EXTRACT(YEAR FROM event_date) AS year,
       COUNT(*) AS evidence_events
FROM public_exam_evidence
GROUP BY 1
ORDER BY 1;

-- 2. Pune-linked evidence events
SELECT event_date, exam, event_category, event, evidence_summary
FROM public_exam_evidence
WHERE pune_link = 'Yes'
ORDER BY event_date;

-- 3. Documented investigation milestones
SELECT event_date, event, metric_1 AS metric_value
FROM public_exam_evidence
WHERE event_category = 'Investigation'
ORDER BY event_date;

-- 4. Scale and impact metrics (not comparable prevalence rates)
SELECT event, metric_1, metric_2
FROM public_exam_evidence
WHERE event_category IN ('Scale','Operations','Data governance')
ORDER BY event_date;

-- 5. Illustrative centre risk distribution
SELECT risk_band,
       COUNT(*) AS centre_days,
       ROUND(AVG(proposed_risk_score),1) AS avg_risk_score
FROM illustrative_centre_operations
GROUP BY risk_band
ORDER BY CASE risk_band
           WHEN 'Critical' THEN 1
           WHEN 'High' THEN 2
           WHEN 'Watch' THEN 3
           WHEN 'Low' THEN 4
         END;

-- 6. Illustrative control-gap analysis
SELECT
    ROUND(100-AVG(cctv_uptime_pct),2) AS cctv_gap_pct,
    ROUND(AVG(biometric_exception_pct),2) AS biometric_exception_pct,
    ROUND(AVG(network_downtime_min),1) AS avg_network_downtime_min,
    ROUND(100-AVG(frisking_compliance_pct),2) AS frisking_gap_pct,
    ROUND(100-AVG(chain_of_custody_pct),2) AS custody_gap_pct,
    ROUND(100-AVG(staff_attendance_pct),2) AS staffing_gap_pct
FROM illustrative_centre_operations;

-- 7. Illustrative high-priority centres
SELECT centre_id, city, state, exam_date, proposed_risk_score, risk_band,
       incident_count, complaint_count, incident_response_hours
FROM illustrative_centre_operations
WHERE risk_band IN ('Critical','High')
ORDER BY proposed_risk_score DESC
LIMIT 20;

-- 8. Illustrative relationship between incidents and complaints
SELECT incident_count,
       COUNT(*) AS centre_days,
       ROUND(AVG(complaint_count),2) AS avg_complaints
FROM illustrative_centre_operations
GROUP BY incident_count
ORDER BY incident_count;

-- 9. Illustrative SLA watchlist
SELECT centre_id, city, state, incident_response_hours, risk_band
FROM illustrative_centre_operations
WHERE incident_response_hours > 12
ORDER BY incident_response_hours DESC;

-- 10. Data-quality / governance insight:
-- The key portfolio point is that public sources do not provide a complete
-- centre-by-centre dataset linking control status, incidents and candidate impact.

-- Risk-score note: weights and thresholds are proposed portfolio assumptions, not official examination standards.
