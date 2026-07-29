-- ============================================================================
-- LedgerLink — Audit Trail & Scheduled Tasks
-- ============================================================================
-- Sets up:
--   1. Audit trail procedures for logging agent actions
--   2. Snowflake Task for scheduled anomaly scanning
--   3. Stream on INVOICES for near-real-time detection
-- ============================================================================

USE DATABASE SUPPLY_CHAIN_FINOPS;
USE WAREHOUSE FINOPS_WH;
USE SCHEMA AUDIT;

-- ============================================================================
-- 1. AUDIT TRAIL LOGGING PROCEDURE
-- ============================================================================

CREATE OR REPLACE PROCEDURE AUDIT.SP_LOG_ACTION(
    P_ACTION_TYPE VARCHAR,
    P_ACTION_CATEGORY VARCHAR,
    P_ANOMALY_ID VARCHAR,
    P_RECORD_ID VARCHAR,
    P_DETAILS VARCHAR,
    P_OUTCOME VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_audit_id VARCHAR;
BEGIN
    v_audit_id := 'AUD-' || TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISS') || '-' || UNIFORM(1000, 9999, RANDOM());
    
    INSERT INTO AUDIT.AUDIT_TRAIL (
        AUDIT_ID, ACTION_TYPE, ACTION_CATEGORY, 
        RELATED_ANOMALY_ID, RELATED_RECORD_ID,
        DETAILS, OUTCOME, EXECUTED_BY
    ) VALUES (
        :v_audit_id, :P_ACTION_TYPE, :P_ACTION_CATEGORY,
        :P_ANOMALY_ID, :P_RECORD_ID,
        :P_DETAILS, :P_OUTCOME, 'FINOPS_AGENT'
    );
    
    RETURN CONCAT('Audit entry created: ', :v_audit_id);
END;
$$;

-- ============================================================================
-- 2. PAYMENT HOLD PROCEDURE
-- ============================================================================

CREATE OR REPLACE PROCEDURE AUDIT.SP_HOLD_PAYMENT(
    P_PAYMENT_ID VARCHAR,
    P_REASON VARCHAR,
    P_ANOMALY_ID VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_amount NUMBER;
    v_result VARCHAR;
BEGIN
    -- Get payment amount
    SELECT AMOUNT INTO v_amount
    FROM CORE.PAYMENTS WHERE PAYMENT_ID = :P_PAYMENT_ID;
    
    -- Update payment status to ON_HOLD
    UPDATE CORE.PAYMENTS 
    SET STATUS = 'ON_HOLD',
        IS_FLAGGED = TRUE,
        FLAG_REASON = :P_REASON
    WHERE PAYMENT_ID = :P_PAYMENT_ID;
    
    -- Log the action
    CALL AUDIT.SP_LOG_ACTION(
        'HOLD_PAYMENT', 'AUTO_EXECUTED', :P_ANOMALY_ID, :P_PAYMENT_ID,
        CONCAT('Payment $', v_amount::VARCHAR, ' placed on hold. Reason: ', :P_REASON),
        'SUCCESS'
    );
    
    v_result := CONCAT('✅ Payment ', :P_PAYMENT_ID, ' ($', v_amount::VARCHAR, ') placed ON HOLD. Reason: ', :P_REASON);
    RETURN v_result;
END;
$$;

-- ============================================================================
-- 3. SUPPLIER RISK TIER UPDATE PROCEDURE
-- ============================================================================

CREATE OR REPLACE PROCEDURE AUDIT.SP_UPDATE_SUPPLIER_RISK(
    P_SUPPLIER_ID VARCHAR,
    P_NEW_RISK_TIER VARCHAR,
    P_REASON VARCHAR,
    P_ANOMALY_ID VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_old_tier VARCHAR;
    v_result VARCHAR;
BEGIN
    -- Get current risk tier
    SELECT RISK_TIER INTO v_old_tier
    FROM CORE.SUPPLIERS WHERE SUPPLIER_ID = :P_SUPPLIER_ID;
    
    -- Update risk tier
    UPDATE CORE.SUPPLIERS
    SET RISK_TIER = :P_NEW_RISK_TIER
    WHERE SUPPLIER_ID = :P_SUPPLIER_ID;
    
    -- Log the action
    CALL AUDIT.SP_LOG_ACTION(
        'UPDATE_RISK_TIER', 'AUTO_EXECUTED', :P_ANOMALY_ID, :P_SUPPLIER_ID,
        CONCAT('Risk tier changed from ', v_old_tier, ' to ', :P_NEW_RISK_TIER, '. Reason: ', :P_REASON),
        'SUCCESS'
    );
    
    v_result := CONCAT('✅ Supplier ', :P_SUPPLIER_ID, ' risk tier updated: ', v_old_tier, ' → ', :P_NEW_RISK_TIER);
    RETURN v_result;
END;
$$;

-- ============================================================================
-- 4. STREAM ON INVOICES (Near-Real-Time Detection)
-- ============================================================================

-- Create a stream to capture new/changed invoices for real-time monitoring
CREATE OR REPLACE STREAM CORE.INVOICE_CHANGES 
ON TABLE CORE.INVOICES
APPEND_ONLY = FALSE
COMMENT = 'Captures new and modified invoices for real-time anomaly detection';

-- Create a stream on payments
CREATE OR REPLACE STREAM CORE.PAYMENT_CHANGES
ON TABLE CORE.PAYMENTS
APPEND_ONLY = FALSE
COMMENT = 'Captures new and modified payments for real-time monitoring';

-- ============================================================================
-- 5. SCHEDULED TASK: Periodic Anomaly Scan
-- ============================================================================

-- Task: Run anomaly detection every 6 hours
-- NOTE: Requires EXECUTE TASK privilege. Uncomment when ready to deploy.

CREATE OR REPLACE TASK ANALYTICS.TASK_PERIODIC_ANOMALY_SCAN
    WAREHOUSE = FINOPS_WH
    SCHEDULE = 'USING CRON 0 */6 * * * America/New_York'
    COMMENT = 'Periodic anomaly detection scan every 6 hours'
AS
BEGIN
    -- Re-run anomaly detection on recent data
    CREATE OR REPLACE TABLE ANALYTICS.INVOICE_ANOMALIES AS
    SELECT * FROM TABLE(
        ANALYTICS.INVOICE_ANOMALY_MODEL!DETECT_ANOMALIES(
            INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'CORE.V_INVOICE_INFERENCE'),
            SERIES_COLNAME => 'SUPPLIER_ID',
            TIMESTAMP_COLNAME => 'TS',
            TARGET_COLNAME => 'AMOUNT',
            CONFIG_OBJECT => {'prediction_interval': 0.99}
        )
    );
    
    -- Log the scan
    CALL AUDIT.SP_LOG_ACTION(
        'SCHEDULED_SCAN', 'AUTO_EXECUTED', NULL, NULL,
        'Periodic anomaly scan completed. Check ANALYTICS.V_ALL_ANOMALIES for results.',
        'SUCCESS'
    );
END;

-- Task: Retrain ML models on a weekly basis to prevent concept drift
CREATE OR REPLACE TASK ANALYTICS.TASK_RETRAIN_ML_MODELS
    WAREHOUSE = FINOPS_WH
    SCHEDULE = 'USING CRON 0 0 * * 0 America/New_York' -- Every Sunday at midnight
    COMMENT = 'Weekly retraining of ML models to capture new trends'
AS
BEGIN
    -- Retrain Invoice Anomaly Model
    CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION INVOICE_ANOMALY_MODEL(
        INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'CORE.V_INVOICE_TRAINING'),
        SERIES_COLNAME => 'SUPPLIER_ID',
        TIMESTAMP_COLNAME => 'TS',
        TARGET_COLNAME => 'AMOUNT',
        LABEL_COLNAME => ''
    );
    
    -- Retrain Payment Anomaly Model
    CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION PAYMENT_ANOMALY_MODEL(
        INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'CORE.V_PAYMENT_TRAINING'),
        SERIES_COLNAME => 'SUPPLIER_ID',
        TIMESTAMP_COLNAME => 'TS',
        TARGET_COLNAME => 'AMOUNT',
        LABEL_COLNAME => ''
    );
    
    CALL AUDIT.SP_LOG_ACTION(
        'SCHEDULED_RETRAIN', 'AUTO_EXECUTED', NULL, NULL,
        'Weekly ML model retraining completed successfully.',
        'SUCCESS'
    );
END;

-- Enable the tasks (Requires EXECUTE TASK privilege on the account for this role)
ALTER TASK ANALYTICS.TASK_PERIODIC_ANOMALY_SCAN RESUME;
ALTER TASK ANALYTICS.TASK_RETRAIN_ML_MODELS RESUME;

-- ============================================================================
-- 6. EXECUTIVE SUMMARY PROCEDURE
-- ============================================================================

CREATE OR REPLACE PROCEDURE ANALYTICS.SP_EXECUTIVE_SUMMARY()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_anomaly_count NUMBER;
    v_critical_count NUMBER;
    v_total_at_risk NUMBER;
    v_payments_held NUMBER;
    v_held_amount NUMBER;
    v_high_risk_suppliers NUMBER;
    v_prompt VARCHAR;
    v_summary VARCHAR;
BEGIN
    -- Count anomalies
    SELECT COUNT(*) INTO v_anomaly_count
    FROM ANALYTICS.V_ALL_ANOMALIES;
    
    SELECT COUNT(*) INTO v_critical_count
    FROM ANALYTICS.V_ALL_ANOMALIES WHERE SEVERITY = 'CRITICAL';
    
    SELECT COALESCE(SUM(ACTUAL_VALUE), 0) INTO v_total_at_risk
    FROM ANALYTICS.V_ALL_ANOMALIES WHERE SEVERITY IN ('CRITICAL', 'WARNING');
    
    -- Count held payments
    SELECT COUNT(*), COALESCE(SUM(AMOUNT), 0) 
    INTO v_payments_held, v_held_amount
    FROM CORE.PAYMENTS WHERE STATUS = 'ON_HOLD';
    
    -- Count high-risk suppliers
    SELECT COUNT(*) INTO v_high_risk_suppliers
    FROM ANALYTICS.V_SUPPLIER_RISK_SCORECARD 
    WHERE RISK_ASSESSMENT IN ('CRITICAL_RISK', 'HIGH_RISK');
    
    v_prompt := CONCAT(
        'Generate a concise executive summary (under 300 words) for the CFO based on these metrics:\n\n',
        '- Total anomalies detected: ', v_anomaly_count::VARCHAR, '\n',
        '- Critical anomalies: ', v_critical_count::VARCHAR, '\n',
        '- Total amount at risk: $', v_total_at_risk::VARCHAR, '\n',
        '- Payments currently on hold: ', v_payments_held::VARCHAR, ' ($', v_held_amount::VARCHAR, ')\n',
        '- High-risk suppliers identified: ', v_high_risk_suppliers::VARCHAR, '\n\n',
        'Format as: Executive Summary header, Key Findings (3-4 bullets), Actions Taken, Recommendations.'
    );
    
    SELECT SNOWFLAKE.CORTEX.COMPLETE('mistral-large2', v_prompt) INTO v_summary;
    
    RETURN v_summary;
END;
$$;

-- ============================================================================
-- VERIFY AUDIT SETUP
-- ============================================================================

-- Insert initial audit entry
CALL AUDIT.SP_LOG_ACTION(
    'SYSTEM_INIT', 'AUTO_EXECUTED', NULL, NULL,
    'LedgerLink system initialized. All tables, ML models, and Cortex functions deployed.',
    'SUCCESS'
);

SELECT '✅ Audit trail, procedures, and scheduled tasks created' AS STATUS;
SELECT * FROM AUDIT.AUDIT_TRAIL ORDER BY CREATED_AT DESC LIMIT 5;
