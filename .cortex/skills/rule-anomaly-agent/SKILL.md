---
name: rule-anomaly-agent
description: >
  Standalone mini-agent that runs ONLY the 6 rule-based anomaly checks
  (duplicate invoices, phantom vendors, unmatched invoices, timing anomalies,
  payment method changes, volume spikes). Uses MERGE for idempotency.
  Returns structured result set ready for the master orchestrator.
  Does NOT perform ML detection, investigation, or action.
tools:
  - snowflake_sql_execute
  - snowflake_object_search
---

# Rule Anomaly Agent — Business-Rule-Based Fraud Detection

## Role in Multi-Agent System
This is **Mini-Agent 2 of 5** in the SupplyChain FinOps pipeline.

```
$orchestrate-supply-chain
  └── calls $ml-anomaly-agent
  └── calls $rule-anomaly-agent  ← YOU ARE HERE
  └── (merges + deduplicates results)
  └── calls $root-cause-agent
  └── calls $action-agent
  └── calls $notification-agent
```

**Inputs:** None required — reads from pre-built analytical views.
**Outputs:** Rows in `ANALYTICS.ANOMALY_RESULTS` (via MERGE) + summary JSON.

---

## Instructions

### Step 1: Verify Session Context
```sql
USE DATABASE SUPPLY_CHAIN_FINOPS;
USE WAREHOUSE FINOPS_WH;
USE SCHEMA ANALYTICS;
```

### Step 2: Collect All Rule-Based Detections

Run all 6 checks in sequence:

#### Check 1 — Duplicate Invoices
```sql
SELECT
    'RULE-DUP-' || i1.SUPPLIER_ID || '-' || i1.INVOICE_NUMBER AS ANOMALY_ID,
    'V_DUPLICATE_INVOICES'  AS SOURCE_TABLE,
    i2.INVOICE_ID           AS RECORD_ID,
    'DUPLICATE_PAYMENT'     AS ANOMALY_CATEGORY,
    1.0                     AS ANOMALY_SCORE,
    'CRITICAL'              AS SEVERITY,
    i1.TOTAL_AMOUNT         AS EXPECTED_VALUE,
    i2.TOTAL_AMOUNT         AS ACTUAL_VALUE,
    0.0                     AS DEVIATION_PCT,
    'Duplicate invoice number ' || i1.INVOICE_NUMBER || ' from supplier ' || s.SUPPLIER_NAME AS DESCRIPTION,
    i1.SUPPLIER_ID,
    NULL::VARCHAR           AS PAYMENT_ID
FROM ANALYTICS.V_DUPLICATE_INVOICES v
JOIN CORE.INVOICES i1 ON v.ORIGINAL_INVOICE = i1.INVOICE_ID
JOIN CORE.INVOICES i2 ON v.DUPLICATE_INVOICE = i2.INVOICE_ID
JOIN CORE.SUPPLIERS s  ON i1.SUPPLIER_ID = s.SUPPLIER_ID;
```

#### Check 2 — Phantom Vendors
```sql
SELECT
    'RULE-PHANTOM-' || INVOICE_ID AS ANOMALY_ID,
    'V_PHANTOM_VENDOR_INVOICES' AS SOURCE_TABLE,
    INVOICE_ID              AS RECORD_ID,
    'PHANTOM_VENDOR'        AS ANOMALY_CATEGORY,
    1.0                     AS ANOMALY_SCORE,
    'CRITICAL'              AS SEVERITY,
    0.0                     AS EXPECTED_VALUE,
    TOTAL_AMOUNT            AS ACTUAL_VALUE,
    100.0                   AS DEVIATION_PCT,
    'Invoice from inactive/critical-risk supplier ' || SUPPLIER_NAME AS DESCRIPTION,
    SUPPLIER_ID,
    NULL::VARCHAR           AS PAYMENT_ID
FROM ANALYTICS.V_PHANTOM_VENDOR_INVOICES;
```

#### Check 3 — Unmatched Invoices (No PO)
```sql
SELECT
    'RULE-UNMATCH-' || INVOICE_ID AS ANOMALY_ID,
    'V_UNMATCHED_INVOICES'  AS SOURCE_TABLE,
    INVOICE_ID              AS RECORD_ID,
    'UNMATCHED_INVOICE'     AS ANOMALY_CATEGORY,
    0.85                    AS ANOMALY_SCORE,
    'WARNING'               AS SEVERITY,
    0.0                     AS EXPECTED_VALUE,
    TOTAL_AMOUNT            AS ACTUAL_VALUE,
    100.0                   AS DEVIATION_PCT,
    'Invoice with no matching purchase order from ' || SUPPLIER_NAME AS DESCRIPTION,
    SUPPLIER_ID,
    NULL::VARCHAR           AS PAYMENT_ID
FROM ANALYTICS.V_UNMATCHED_INVOICES;
```

#### Check 4 — Timing Anomalies
```sql
SELECT
    'RULE-TIMING-' || PAYMENT_ID AS ANOMALY_ID,
    'V_TIMING_ANOMALIES'    AS SOURCE_TABLE,
    INVOICE_ID              AS RECORD_ID,
    'TIMING_ANOMALY'        AS ANOMALY_CATEGORY,
    0.95                    AS ANOMALY_SCORE,
    'CRITICAL'              AS SEVERITY,
    0.0                     AS EXPECTED_VALUE,
    AMOUNT                  AS ACTUAL_VALUE,
    100.0                   AS DEVIATION_PCT,
    ANOMALY_TYPE || ': Payment ' || PAYMENT_ID || ' vs Invoice ' || INV_ID || ' for ' || SUPPLIER_NAME AS DESCRIPTION,
    SUPPLIER_ID,
    PAYMENT_ID
FROM ANALYTICS.V_TIMING_ANOMALIES;
```

#### Check 5 — Payment Method Changes
```sql
SELECT
    'RULE-METHOD-' || PAYMENT_ID AS ANOMALY_ID,
    'V_PAYMENT_METHOD_ANOMALIES' AS SOURCE_TABLE,
    PAYMENT_ID              AS RECORD_ID,
    'METHOD_CHANGE'         AS ANOMALY_CATEGORY,
    0.80                    AS ANOMALY_SCORE,
    'WARNING'               AS SEVERITY,
    0.0                     AS EXPECTED_VALUE,
    AMOUNT                  AS ACTUAL_VALUE,
    100.0                   AS DEVIATION_PCT,
    'Payment method changed from ' || NORMAL_METHOD || ' to ' || CURRENT_METHOD
        || ' on $' || TO_VARCHAR(AMOUNT, '999,999,999') || ' payment for ' || SUPPLIER_NAME AS DESCRIPTION,
    SUPPLIER_ID,
    PAYMENT_ID
FROM ANALYTICS.V_PAYMENT_METHOD_ANOMALIES;
```

#### Check 6 — Volume Spikes (PO line items)
```sql
WITH supplier_avg AS (
    SELECT
        po.SUPPLIER_ID,
        li.PRODUCT_NAME,
        AVG(li.QUANTITY) AS AVG_QTY,
        STDDEV(li.QUANTITY) AS STDDEV_QTY
    FROM CORE.PO_LINE_ITEMS li
    JOIN CORE.PURCHASE_ORDERS po ON li.PO_ID = po.PO_ID
    WHERE po.CREATED_DATE < '2026-06-01'
    GROUP BY po.SUPPLIER_ID, li.PRODUCT_NAME
    HAVING COUNT(*) >= 3
)
SELECT
    'RULE-VOL-' || po.PO_ID || '-' || li.LINE_ID AS ANOMALY_ID,
    'PO_LINE_ITEMS'         AS SOURCE_TABLE,
    po.PO_ID                AS RECORD_ID,
    'VOLUME_SPIKE'          AS ANOMALY_CATEGORY,
    LEAST(1.0, (li.QUANTITY - sa.AVG_QTY) / NULLIF(sa.STDDEV_QTY, 1) / 10) AS ANOMALY_SCORE,
    CASE
        WHEN li.QUANTITY > sa.AVG_QTY * 5 THEN 'CRITICAL'
        WHEN li.QUANTITY > sa.AVG_QTY * 2 THEN 'WARNING'
        ELSE 'INFO'
    END                     AS SEVERITY,
    sa.AVG_QTY              AS EXPECTED_VALUE,
    li.QUANTITY             AS ACTUAL_VALUE,
    ROUND((li.QUANTITY - sa.AVG_QTY) / NULLIF(sa.AVG_QTY, 0) * 100, 2) AS DEVIATION_PCT,
    'Volume spike: ' || li.PRODUCT_NAME || ' ordered ' || li.QUANTITY
        || ' units vs avg ' || ROUND(sa.AVG_QTY, 0) || ' for ' || s.SUPPLIER_NAME AS DESCRIPTION,
    po.SUPPLIER_ID,
    NULL::VARCHAR           AS PAYMENT_ID
FROM CORE.PO_LINE_ITEMS li
JOIN CORE.PURCHASE_ORDERS po ON li.PO_ID = po.PO_ID
JOIN supplier_avg sa ON po.SUPPLIER_ID = sa.SUPPLIER_ID AND li.PRODUCT_NAME = sa.PRODUCT_NAME
JOIN CORE.SUPPLIERS s  ON po.SUPPLIER_ID = s.SUPPLIER_ID
WHERE po.CREATED_DATE >= '2026-06-01'
  AND li.QUANTITY > sa.AVG_QTY * 2;
```

### Step 3: Write Results — Idempotent MERGE (Fix #5)
Merge ALL six check results into `ANALYTICS.ANOMALY_RESULTS` using MERGE to prevent
duplicate rows on re-runs. Repeat the pattern below for each check result:

```sql
MERGE INTO ANALYTICS.ANOMALY_RESULTS tgt
USING (
    -- Paste the SELECT from any Check above here
) src
ON tgt.ANOMALY_ID = src.ANOMALY_ID
WHEN NOT MATCHED THEN INSERT (
    ANOMALY_ID, SOURCE_TABLE, RECORD_ID, ANOMALY_CATEGORY,
    ANOMALY_SCORE, SEVERITY, EXPECTED_VALUE, ACTUAL_VALUE,
    DEVIATION_PCT, DESCRIPTION, IS_INVESTIGATED
) VALUES (
    src.ANOMALY_ID, src.SOURCE_TABLE, src.RECORD_ID, src.ANOMALY_CATEGORY,
    src.ANOMALY_SCORE, src.SEVERITY, src.EXPECTED_VALUE, src.ACTUAL_VALUE,
    src.DEVIATION_PCT, src.DESCRIPTION, FALSE
);
```

Run this MERGE for each of the 6 checks.

### Step 4: Log Detection Run
```sql
CALL AUDIT.SP_LOG_ACTION(
    'RULE_DETECT', 'AUTO_EXECUTED', NULL, NULL,
    'Rule-based anomaly scan completed by $rule-anomaly-agent.',
    'SUCCESS'
);
```

### Step 5: Return Summary to Orchestrator
```
RULE_ANOMALY_AGENT_RESULT:
{
  "agent": "rule-anomaly-agent",
  "status": "SUCCESS",
  "checks_run": 6,
  "anomalies_written": <N>,
  "critical": <X>,
  "warning": <Y>,
  "anomaly_ids": ["RULE-DUP-...", "RULE-PHANTOM-...", ...]
}
```

## Severity Assignment Rules
| Condition | Severity |
|:---|:---|
| Phantom vendor, duplicate invoice, timing anomaly | `CRITICAL` |
| Unmatched invoice, method change | `WARNING` |
| Volume spike < 5× avg | `WARNING` |
| Volume spike ≥ 5× avg | `CRITICAL` |

## Error Handling
- If a view is empty → note "0 anomalies from <check name>", continue
- If seed data not loaded → return `"status": "NO_DATA"` with setup instructions
- If MERGE fails for one check → log error, continue remaining checks
