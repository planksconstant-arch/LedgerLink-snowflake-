---
name: root-cause-agent
description: >
  Standalone mini-agent that investigates a BATCH of anomaly IDs concurrently,
  correlating structured data (invoices, POs, shipments) with unstructured data
  (contracts, communications) using Snowflake Cortex AI. Calculates supplier
  risk scores, determines root causes, and logs investigation results.
  Accepts a list of anomaly IDs from the orchestrator — does NOT detect anomalies
  or execute actions.
tools:
  - snowflake_sql_execute
  - snowflake_object_search
---

# Root Cause Agent — Batch Investigation Engine

## Role in Multi-Agent System
This is **Mini-Agent 3 of 5** in the SupplyChain FinOps pipeline.

```
$orchestrate-supply-chain
  └── calls $ml-anomaly-agent
  └── calls $rule-anomaly-agent
  └── (merges + deduplicates results)
  └── calls $root-cause-agent  ← YOU ARE HERE
       input: list of ANOMALY_IDs to investigate
  └── calls $action-agent
  └── calls $notification-agent
```

**Inputs:** A list of `ANOMALY_ID` values from the orchestrator (CRITICAL + WARNING only).
**Outputs:** Rows in `ANALYTICS.INVESTIGATION_LOG` + per-anomaly investigation JSON.

---

## Instructions

### Step 1: Receive Anomaly Batch
The orchestrator passes a comma-delimited list of ANOMALY_IDs. Load them:

```sql
-- Query the batch of anomalies to investigate
SELECT
    ar.ANOMALY_ID,
    ar.ANOMALY_CATEGORY,
    ar.SEVERITY,
    ar.RECORD_ID,
    ar.EXPECTED_VALUE,
    ar.ACTUAL_VALUE,
    ar.DEVIATION_PCT,
    ar.DESCRIPTION,
    -- Resolve supplier from record
    COALESCE(i.SUPPLIER_ID, p.SUPPLIER_ID, ar.RECORD_ID) AS SUPPLIER_ID
FROM ANALYTICS.ANOMALY_RESULTS ar
LEFT JOIN CORE.INVOICES  i ON ar.RECORD_ID = i.INVOICE_ID
LEFT JOIN CORE.PAYMENTS  p ON ar.RECORD_ID = p.PAYMENT_ID
WHERE ar.ANOMALY_ID IN (<ANOMALY_ID_LIST>)
  AND ar.IS_INVESTIGATED = FALSE
  AND ar.SEVERITY IN ('CRITICAL', 'WARNING')
ORDER BY
    CASE ar.SEVERITY WHEN 'CRITICAL' THEN 1 ELSE 2 END,
    ar.ANOMALY_SCORE DESC;
```

### Step 2: AI Triage (Cost Optimization — Fix #6)
Before calling Cortex AI for EACH anomaly, apply the triage rule:

```
AI_TRIAGE_THRESHOLD = $200,000   ← aligned with auto-execute threshold
```

| Condition | Action |
|:---|:---|
| Severity = `CRITICAL` | → Always run AI investigation |
| Severity = `WARNING` AND `ACTUAL_VALUE > $200,000` | → Run AI investigation |
| Severity = `WARNING` AND `ACTUAL_VALUE ≤ $200,000` | → Rule-based analysis only |

### Step 3: For Each Anomaly — Gather Batch Evidence

Rather than one SQL per anomaly, gather evidence for ALL anomalies in one pass:

#### 3a. Supplier Profiles (batch)
```sql
SELECT * FROM CORE.SUPPLIERS
WHERE SUPPLIER_ID IN (
    SELECT DISTINCT COALESCE(i.SUPPLIER_ID, p.SUPPLIER_ID)
    FROM ANALYTICS.ANOMALY_RESULTS ar
    LEFT JOIN CORE.INVOICES i ON ar.RECORD_ID = i.INVOICE_ID
    LEFT JOIN CORE.PAYMENTS p ON ar.RECORD_ID = p.PAYMENT_ID
    WHERE ar.ANOMALY_ID IN (<ANOMALY_ID_LIST>)
);
```

#### 3b. Recent Invoices (batch — last 6 months, all affected suppliers)
```sql
SELECT INVOICE_ID, SUPPLIER_ID, PO_ID, INVOICE_NUMBER,
       TOTAL_AMOUNT, STATUS, SUBMITTED_DATE, NOTES
FROM CORE.INVOICES
WHERE SUPPLIER_ID IN (<SUPPLIER_ID_LIST>)
  AND SUBMITTED_DATE >= DATEADD('month', -6, CURRENT_DATE())
ORDER BY SUPPLIER_ID, SUBMITTED_DATE DESC;
```

#### 3c. PO History (batch)
```sql
SELECT PO_ID, SUPPLIER_ID, TOTAL_AMOUNT, STATUS, PRIORITY,
       CREATED_DATE, EXPECTED_DELIVERY
FROM CORE.PURCHASE_ORDERS
WHERE SUPPLIER_ID IN (<SUPPLIER_ID_LIST>)
ORDER BY SUPPLIER_ID, CREATED_DATE DESC;
```

#### 3d. Shipment Performance (batch)
```sql
SELECT SHIPMENT_ID, SUPPLIER_ID, EXPECTED_DATE, ACTUAL_DATE,
       DELAY_DAYS, DELAY_REASON, STATUS
FROM CORE.SHIPMENTS
WHERE SUPPLIER_ID IN (<SUPPLIER_ID_LIST>)
ORDER BY SUPPLIER_ID, EXPECTED_DATE DESC;
```

#### 3e. Communication Sentiment (batch)
```sql
SELECT * FROM ANALYTICS.V_SUPPLIER_SENTIMENT_TREND
WHERE SUPPLIER_ID IN (<SUPPLIER_ID_LIST>)
ORDER BY SUPPLIER_ID, COMM_DATE;
```

#### 3f. Risk Scorecards (batch)
```sql
SELECT SUPPLIER_ID, SUPPLIER_NAME, COMPOSITE_HEALTH_SCORE,
       RISK_ASSESSMENT, DELIVERY_SCORE, FINANCIAL_SCORE,
       RELATIONSHIP_SCORE, COMPLIANCE_SCORE
FROM ANALYTICS.V_SUPPLIER_RISK_SCORECARD
WHERE SUPPLIER_ID IN (<SUPPLIER_ID_LIST>);
```

#### 3g. Active Contracts (batch)
```sql
SELECT CONTRACT_ID, SUPPLIER_ID, CONTRACT_TYPE,
       MAX_PRICE_ESCALATION_PCT, START_DATE, END_DATE, STATUS
FROM UNSTRUCTURED.CONTRACTS
WHERE SUPPLIER_ID IN (<SUPPLIER_ID_LIST>)
  AND STATUS = 'ACTIVE';
```

### Step 4: AI Investigation (per anomaly, if triage passes)
```sql
CALL ANALYTICS.SP_INVESTIGATE_ANOMALY(
    '<supplier_id>',
    '<anomaly_description>'
);
```

This uses `SNOWFLAKE.CORTEX.COMPLETE` to reason across all gathered evidence.

### Step 5: Determine Root Cause per Anomaly

| Root Cause Category | Indicators |
|:---|:---|
| `FRAUD` | Phantom vendor, duplicate invoices, no matching PO, payment before invoice |
| `CONTRACT_VIOLATION` | Price exceeds contractual maximum, unauthorized escalation |
| `MARKET_CONDITION` | Documented commodity price changes, force majeure events |
| `OPERATIONAL_ERROR` | Data entry mistakes, system glitches, timing errors |
| `DATA_QUALITY` | Missing fields, inconsistent records, duplicate data |

### Step 6: Log Investigation Results (batch INSERT)
```sql
INSERT INTO ANALYTICS.INVESTIGATION_LOG (
    INVESTIGATION_ID, ANOMALY_ID, SUPPLIER_ID, ROOT_CAUSE,
    ROOT_CAUSE_CATEGORY, SUPPLIER_RISK_SCORE, EVIDENCE_SUMMARY,
    SENTIMENT_TREND, CONTRACT_VIOLATION, RECOMMENDED_ACTION
)
SELECT
    'INV-' || CURRENT_TIMESTAMP()::VARCHAR || '-' || ANOMALY_ID,
    ANOMALY_ID,
    SUPPLIER_ID,
    <root_cause>,
    <category>,
    <risk_score>,
    <evidence_summary>,
    <sentiment_trend>,
    <contract_violation_bool>,
    <recommended_action>
FROM (VALUES
    ('<anomaly_id_1>', '<supplier_id_1>', ...),
    ('<anomaly_id_2>', '<supplier_id_2>', ...),
    ...
) AS v(ANOMALY_ID, SUPPLIER_ID, ...);

-- Mark all as investigated in one UPDATE
UPDATE ANALYTICS.ANOMALY_RESULTS
SET IS_INVESTIGATED = TRUE
WHERE ANOMALY_ID IN (<ANOMALY_ID_LIST>);
```

### Step 7: Return Batch Result to Orchestrator
```
ROOT_CAUSE_AGENT_RESULT:
{
  "agent": "root-cause-agent",
  "status": "SUCCESS",
  "anomalies_investigated": <N>,
  "ai_investigated": <X>,
  "rule_based_only": <Y>,
  "root_cause_summary": {
    "FRAUD": <count>,
    "CONTRACT_VIOLATION": <count>,
    "MARKET_CONDITION": <count>,
    "OPERATIONAL_ERROR": <count>,
    "DATA_QUALITY": <count>
  },
  "high_risk_suppliers": ["SUP-005", ...],
  "investigations": [
    {
      "anomaly_id": "...",
      "supplier_id": "...",
      "root_cause_category": "...",
      "risk_score": <0-100>,
      "confidence": "HIGH|MEDIUM|LOW",
      "contract_violation": true|false,
      "payment_id": "...",
      "invoice_id": "...",
      "recommended_action": "..."
    },
    ...
  ]
}
```

## Decision Branches
- `FRAUD` → Flag for `$action-agent` with IMMEDIATE urgency
- `CONTRACT_VIOLATION` → Flag for `$action-agent` with HIGH urgency
- `MARKET_CONDITION` → Flag for `$action-agent` as RECOMMENDED review
- `OPERATIONAL_ERROR` or `DATA_QUALITY` → Flag for human review

## Error Handling
- If no communications found → Note data gap, reduce confidence to LOW
- If no contract found → Flag as compliance gap, note in evidence
- If Cortex AI unavailable → Use rule-based analysis only, set confidence LOW
- If investigation SP fails for one anomaly → Skip to next, log partial result
- If batch is empty → Return `"anomalies_investigated": 0`, do not error
