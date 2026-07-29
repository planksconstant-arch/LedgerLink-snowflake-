---
name: ml-anomaly-agent
description: >
  Standalone mini-agent that runs ONLY Snowflake ML-based anomaly detection
  (SNOWFLAKE.ML.ANOMALY_DETECTION and SNOWFLAKE.ML.FORECAST) on invoices and
  payments. Returns a structured result set ready for the master orchestrator
  to merge with rule-based findings. Does NOT perform investigation or action.
tools:
  - snowflake_sql_execute
  - snowflake_object_search
---

# ML Anomaly Agent — Statistical Outlier Detection

## Role in Multi-Agent System
This is **Mini-Agent 1 of 5** in the SupplyChain FinOps pipeline.

```
$orchestrate-supply-chain
  └── calls $ml-anomaly-agent  ← YOU ARE HERE
  └── calls $rule-anomaly-agent
  └── (merges results)
  └── calls $root-cause-agent
  └── calls $action-agent
  └── calls $notification-agent
```

**Inputs:** None required — reads from Snowflake directly.
**Outputs:** Rows in `ANALYTICS.ANOMALY_RESULTS` (via MERGE) + summary JSON for orchestrator.

---

## Instructions

### Step 1: Verify Session Context
```sql
USE DATABASE SUPPLY_CHAIN_FINOPS;
USE WAREHOUSE FINOPS_WH;
USE SCHEMA ANALYTICS;
```

### Step 2: Check Model Freshness
Verify whether ML models exist and have been trained on recent data:
```sql
SELECT 
    'INVOICE_ANOMALY_MODEL' AS MODEL_NAME,
    COUNT(*) AS INFERENCE_ROWS,
    MAX(TS) AS LATEST_INFERENCE_DATE
FROM ANALYTICS.INVOICE_ANOMALIES

UNION ALL

SELECT
    'PAYMENT_ANOMALY_MODEL',
    COUNT(*),
    MAX(TS)
FROM ANALYTICS.PAYMENT_ANOMALIES;
```

**Decision:**
- If `LATEST_INFERENCE_DATE` is older than 7 days → retrain (Step 3).
- If models are current → skip to Step 4.

### Step 3: Retrain Models (if stale)
```sql
-- Retrain invoice anomaly model
CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ANALYTICS.INVOICE_ANOMALY_MODEL(
    INPUT_DATA    => SYSTEM$REFERENCE('VIEW', 'CORE.V_INVOICE_TRAINING'),
    SERIES_COLNAME  => 'SUPPLIER_ID',
    TIMESTAMP_COLNAME => 'TS',
    TARGET_COLNAME  => 'AMOUNT',
    LABEL_COLNAME   => ''
);

-- Re-run inference
CREATE OR REPLACE TABLE ANALYTICS.INVOICE_ANOMALIES AS
SELECT * FROM TABLE(
    ANALYTICS.INVOICE_ANOMALY_MODEL!DETECT_ANOMALIES(
        INPUT_DATA    => SYSTEM$REFERENCE('VIEW', 'CORE.V_INVOICE_INFERENCE'),
        SERIES_COLNAME  => 'SUPPLIER_ID',
        TIMESTAMP_COLNAME => 'TS',
        TARGET_COLNAME  => 'AMOUNT',
        CONFIG_OBJECT   => {'prediction_interval': 0.99}
    )
);

-- Retrain payment anomaly model
CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ANALYTICS.PAYMENT_ANOMALY_MODEL(
    INPUT_DATA    => SYSTEM$REFERENCE('VIEW', 'CORE.V_PAYMENT_TRAINING'),
    SERIES_COLNAME  => 'SUPPLIER_ID',
    TIMESTAMP_COLNAME => 'TS',
    TARGET_COLNAME  => 'AMOUNT',
    LABEL_COLNAME   => ''
);

CREATE OR REPLACE TABLE ANALYTICS.PAYMENT_ANOMALIES AS
SELECT * FROM TABLE(
    ANALYTICS.PAYMENT_ANOMALY_MODEL!DETECT_ANOMALIES(
        INPUT_DATA    => SYSTEM$REFERENCE('VIEW', 'CORE.V_PAYMENT_INFERENCE'),
        SERIES_COLNAME  => 'SUPPLIER_ID',
        TIMESTAMP_COLNAME => 'TS',
        TARGET_COLNAME  => 'AMOUNT',
        CONFIG_OBJECT   => {'prediction_interval': 0.99}
    )
);
```

### Step 4: Run Spend Forecast Comparison
```sql
SELECT
    FORECAST_MONTH,
    CATEGORY,
    FORECASTED_SPEND,
    ACTUAL_SPEND,
    VARIANCE,
    BUDGET_STATUS
FROM ANALYTICS.V_FORECAST_VS_ACTUAL
WHERE BUDGET_STATUS = 'OVER_BUDGET'
ORDER BY VARIANCE DESC;
```

### Step 5: Write Results — Idempotent MERGE
Use MERGE (not INSERT) so re-running this agent never duplicates rows.

```sql
-- Invoice ML anomalies → ANOMALY_RESULTS
MERGE INTO ANALYTICS.ANOMALY_RESULTS tgt
USING (
    SELECT
        'ML-INV-' || ia.SERIES || '-' || TO_VARCHAR(ia.TS, 'YYYYMMDD') AS ANOMALY_ID,
        'INVOICE_ANOMALIES'     AS SOURCE_TABLE,
        i.INVOICE_ID            AS RECORD_ID,
        'PRICE_SPIKE'           AS ANOMALY_CATEGORY,
        ia.PERCENTILE           AS ANOMALY_SCORE,
        CASE
            WHEN ABS(ia.AMOUNT - ia.FORECAST) / NULLIF(ia.FORECAST, 0) > 0.5 THEN 'CRITICAL'
            WHEN ABS(ia.AMOUNT - ia.FORECAST) / NULLIF(ia.FORECAST, 0) > 0.2 THEN 'WARNING'
            ELSE 'INFO'
        END                     AS SEVERITY,
        ia.FORECAST             AS EXPECTED_VALUE,
        ia.AMOUNT               AS ACTUAL_VALUE,
        ROUND(ABS(ia.AMOUNT - ia.FORECAST) / NULLIF(ia.FORECAST, 0) * 100, 2) AS DEVIATION_PCT,
        'ML model detected statistical invoice amount anomaly for ' || ia.SERIES AS DESCRIPTION,
        FALSE                   AS IS_INVESTIGATED
    FROM ANALYTICS.INVOICE_ANOMALIES ia
    LEFT JOIN CORE.INVOICES i
        ON ia.TS = i.SUBMITTED_DATE
       AND ia.SERIES = i.SUPPLIER_ID
       AND ABS(ia.AMOUNT - i.TOTAL_AMOUNT) < 1
    WHERE ia.IS_ANOMALY = TRUE
) src
ON tgt.ANOMALY_ID = src.ANOMALY_ID
WHEN NOT MATCHED THEN INSERT (
    ANOMALY_ID, SOURCE_TABLE, RECORD_ID, ANOMALY_CATEGORY,
    ANOMALY_SCORE, SEVERITY, EXPECTED_VALUE, ACTUAL_VALUE,
    DEVIATION_PCT, DESCRIPTION, IS_INVESTIGATED
) VALUES (
    src.ANOMALY_ID, src.SOURCE_TABLE, src.RECORD_ID, src.ANOMALY_CATEGORY,
    src.ANOMALY_SCORE, src.SEVERITY, src.EXPECTED_VALUE, src.ACTUAL_VALUE,
    src.DEVIATION_PCT, src.DESCRIPTION, src.IS_INVESTIGATED
);

-- Payment ML anomalies → ANOMALY_RESULTS
MERGE INTO ANALYTICS.ANOMALY_RESULTS tgt
USING (
    SELECT
        'ML-PAY-' || pa.SERIES || '-' || TO_VARCHAR(pa.TS, 'YYYYMMDD') AS ANOMALY_ID,
        'PAYMENT_ANOMALIES'     AS SOURCE_TABLE,
        p.PAYMENT_ID            AS RECORD_ID,
        'PRICE_SPIKE'           AS ANOMALY_CATEGORY,
        pa.PERCENTILE           AS ANOMALY_SCORE,
        CASE
            WHEN ABS(pa.AMOUNT - pa.FORECAST) / NULLIF(pa.FORECAST, 0) > 0.5 THEN 'CRITICAL'
            WHEN ABS(pa.AMOUNT - pa.FORECAST) / NULLIF(pa.FORECAST, 0) > 0.2 THEN 'WARNING'
            ELSE 'INFO'
        END                     AS SEVERITY,
        pa.FORECAST             AS EXPECTED_VALUE,
        pa.AMOUNT               AS ACTUAL_VALUE,
        ROUND(ABS(pa.AMOUNT - pa.FORECAST) / NULLIF(pa.FORECAST, 0) * 100, 2) AS DEVIATION_PCT,
        'ML model detected statistical payment amount anomaly for ' || pa.SERIES AS DESCRIPTION,
        FALSE                   AS IS_INVESTIGATED
    FROM ANALYTICS.PAYMENT_ANOMALIES pa
    LEFT JOIN CORE.PAYMENTS p
        ON pa.TS = p.PAYMENT_DATE
       AND pa.SERIES = p.SUPPLIER_ID
       AND ABS(pa.AMOUNT - p.AMOUNT) < 1
    WHERE pa.IS_ANOMALY = TRUE
) src
ON tgt.ANOMALY_ID = src.ANOMALY_ID
WHEN NOT MATCHED THEN INSERT (
    ANOMALY_ID, SOURCE_TABLE, RECORD_ID, ANOMALY_CATEGORY,
    ANOMALY_SCORE, SEVERITY, EXPECTED_VALUE, ACTUAL_VALUE,
    DEVIATION_PCT, DESCRIPTION, IS_INVESTIGATED
) VALUES (
    src.ANOMALY_ID, src.SOURCE_TABLE, src.RECORD_ID, src.ANOMALY_CATEGORY,
    src.ANOMALY_SCORE, src.SEVERITY, src.EXPECTED_VALUE, src.ACTUAL_VALUE,
    src.DEVIATION_PCT, src.DESCRIPTION, src.IS_INVESTIGATED
);
```

### Step 6: Log Detection Run
```sql
CALL AUDIT.SP_LOG_ACTION(
    'ML_DETECT', 'AUTO_EXECUTED', NULL, NULL,
    'ML anomaly scan completed by $ml-anomaly-agent.',
    'SUCCESS'
);
```

### Step 7: Return Summary to Orchestrator
Return a structured summary in this format:

```
ML_ANOMALY_AGENT_RESULT:
{
  "agent": "ml-anomaly-agent",
  "status": "SUCCESS",
  "anomalies_written": <N>,
  "critical": <X>,
  "warning": <Y>,
  "info": <Z>,
  "anomaly_ids": ["ML-INV-...", "ML-PAY-...", ...]
}
```

## Error Handling
- If ML model doesn't exist → Offer to train, set `"status": "MODEL_MISSING"` in result
- If inference table is empty → Set `"anomalies_written": 0`, do not error
- If MERGE fails → Log error via `SP_LOG_ACTION` with status `'ERROR'`, return partial result
