---
name: orchestrate-supply-chain
description: >
  Master orchestrator that coordinates 5 specialized mini-agents into a complete
  end-to-end supply chain financial risk intelligence pipeline:
  ML detection → Rule detection → Dedup → Batch investigation → Action execution → Notifications.
  Aggregates all mini-agent results into a comprehensive executive summary.
  Invoke this skill to run the full pipeline with a single command.
tools:
  - snowflake_sql_execute
  - snowflake_object_search
---

# Supply Chain Financial Risk Intelligence — Master Orchestrator

## Architecture

```
$orchestrate-supply-chain  (YOU ARE HERE)
  │
  ├── Phase 1a: $ml-anomaly-agent    → ML_ANOMALY_AGENT_RESULT
  ├── Phase 1b: $rule-anomaly-agent  → RULE_ANOMALY_AGENT_RESULT
  │
  ├── [DEDUP] Merge + de-duplicate both result sets
  │
  ├── Phase 2:  $root-cause-agent    → ROOT_CAUSE_AGENT_RESULT
  ├── Phase 3:  $action-agent        → ACTION_AGENT_RESULT
  └── Phase 4:  $notification-agent  → NOTIFICATION_AGENT_RESULT
                                     → EXECUTIVE SUMMARY
```

## When to Use
- When asked to run a full supply chain financial risk assessment
- When asked to "scan", "audit", or "check" supply chain financial health
- As the primary single-command entry point for the entire FinOps pipeline

---

## Full Orchestration Workflow

### Phase 0: Environment Setup & Health Check
```sql
USE DATABASE SUPPLY_CHAIN_FINOPS;
USE WAREHOUSE FINOPS_WH;

-- Verify all required tables exist and have data
SELECT TABLE_SCHEMA, TABLE_NAME, ROW_COUNT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN ('CORE', 'UNSTRUCTURED', 'ANALYTICS', 'AUDIT')
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
```

**Circuit-Breaker Guard (Fix #10):**
Record the pipeline start time. If any phase exceeds `MAX_PHASE_MINUTES = 15` minutes,
log a timeout, report partial results, and stop. Do NOT let a hung phase block the pipeline.

```sql
-- Record pipeline start
SET PIPELINE_START = CURRENT_TIMESTAMP();

-- After each phase, check elapsed time
SELECT DATEDIFF('minute', $PIPELINE_START, CURRENT_TIMESTAMP()) AS ELAPSED_MINUTES;
-- If ELAPSED_MINUTES > 15, halt and report partial results.
```

If tables are empty, inform the user to run the setup scripts in order:
```
sql/00_setup_database.sql → 01_create_tables.sql → 02_seed_data.sql →
03_create_ml_models.sql  → 04_cortex_functions.sql → 05_audit_and_tasks.sql
```

---

### Phase 1: DETECTION — Run Both Anomaly Agents in Parallel

Invoke **both** detection agents. They write independently to `ANALYTICS.ANOMALY_RESULTS`
using MERGE (idempotent), so they can run concurrently without conflicts.

#### 1a. Invoke $ml-anomaly-agent
```
$ml-anomaly-agent Run ML-based anomaly detection on invoices and payments
```

Receive `ML_ANOMALY_AGENT_RESULT`. If `status = "MODEL_MISSING"`, note it and continue
— rule-based detection is still valuable without ML.

#### 1b. Invoke $rule-anomaly-agent
```
$rule-anomaly-agent Run all 6 rule-based anomaly checks
```

Receive `RULE_ANOMALY_AGENT_RESULT`.

#### 1c. Dedup & Merge Results (Fix #5 reinforcement)
After both agents complete, de-duplicate across results by record ID and category:

```sql
-- Final view of all unique anomalies from this scan
SELECT
    ANOMALY_ID,
    SOURCE_TABLE,
    RECORD_ID,
    ANOMALY_CATEGORY,
    ANOMALY_SCORE,
    SEVERITY,
    EXPECTED_VALUE,
    ACTUAL_VALUE,
    DEVIATION_PCT,
    DESCRIPTION
FROM ANALYTICS.ANOMALY_RESULTS
WHERE IS_INVESTIGATED = FALSE
  AND SEVERITY IN ('CRITICAL', 'WARNING')
ORDER BY
    CASE SEVERITY WHEN 'CRITICAL' THEN 1 ELSE 2 END,
    ANOMALY_SCORE DESC;
```

**Decision Point:**
- If `0 anomalies` → Log clean scan, produce clean summary report, **STOP**
- If anomalies found → Continue to Phase 2

---

### Phase 2: INVESTIGATION — Batch Root Cause Analysis

Collect ALL `ANOMALY_ID` values from the dedup query and pass them as a batch:

```
$root-cause-agent Investigate anomalies: ANO-001, ANO-002, ANO-003, ...
```

Receive `ROOT_CAUSE_AGENT_RESULT`.

**Circuit-breaker check:** If Phase 2 took > 15 minutes, report partial investigation
results and proceed to Phase 3 with what was completed.

**Decision Point:**
- If `FRAUD` or `CONTRACT_VIOLATION` found → Flag for immediate Phase 3 action
- If `MARKET_CONDITION` → Flag for recommended review
- If `OPERATIONAL_ERROR` or `DATA_QUALITY` → Flag for correction

---

### Phase 3: ACTION EXECUTION

Pass `ROOT_CAUSE_AGENT_RESULT.investigations[]` to the action agent:

```
$action-agent Execute recovery actions for investigations: INV-001, INV-002, ...
```

Receive `ACTION_AGENT_RESULT` which includes:
- Actions executed (holds, flags, tier updates)
- Escalations requiring human review
- `notification_payload` for Phase 4

**Circuit-breaker check:** If Phase 3 took > 15 minutes, log partial results and proceed.

---

### Phase 4: NOTIFICATIONS

Pass `ACTION_AGENT_RESULT.notification_payload` to the notification agent:

```
$notification-agent Draft and log stakeholder notifications
```

Receive `NOTIFICATION_AGENT_RESULT`.

---

### Phase 5: EXECUTIVE SUMMARY REPORT

Aggregate all 5 mini-agent results into the final report:

```sql
-- Pull executive summary from stored procedure
CALL ANALYTICS.SP_EXECUTIVE_SUMMARY();

-- Supplier risk leaderboard
SELECT SUPPLIER_ID, SUPPLIER_NAME, COMPOSITE_HEALTH_SCORE, RISK_ASSESSMENT,
       DELIVERY_SCORE, FINANCIAL_SCORE, RELATIONSHIP_SCORE, COMPLIANCE_SCORE
FROM ANALYTICS.V_SUPPLIER_RISK_SCORECARD
ORDER BY COMPOSITE_HEALTH_SCORE ASC
LIMIT 10;

-- Recent audit trail
SELECT * FROM AUDIT.AUDIT_TRAIL
ORDER BY CREATED_AT DESC
LIMIT 20;
```

Present the final executive summary:

```
╔══════════════════════════════════════════════════════════════════════╗
║         SUPPLYCHAIN FINOPS AGENT — EXECUTIVE SUMMARY               ║
║         Multi-Agent Pipeline Report — [timestamp]                   ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                     ║
║  🤖 PIPELINE AGENTS                                                 ║
║  ├── $ml-anomaly-agent:    [SUCCESS/TIMEOUT/MODEL_MISSING]          ║
║  ├── $rule-anomaly-agent:  [SUCCESS/TIMEOUT]                        ║
║  ├── $root-cause-agent:    [SUCCESS/PARTIAL (<N> of <M> done)]      ║
║  ├── $action-agent:        [SUCCESS/PARTIAL]                        ║
║  └── $notification-agent:  [SUCCESS]                                ║
║                                                                     ║
║  📊 DETECTION RESULTS                                               ║
║  ├── ML Anomalies Found:   <N> (<X> critical, <Y> warning)          ║
║  ├── Rule Anomalies Found: <N> (<X> critical, <Y> warning)          ║
║  ├── After Dedup Total:    <N>                                       ║
║  └── Total Amount at Risk: $XXX,XXX                                 ║
║                                                                     ║
║  🔍 INVESTIGATION RESULTS                                           ║
║  ├── Anomalies Investigated: <N>                                    ║
║  ├── AI-Powered: <X>  │  Rule-Based: <Y>                           ║
║  ├── Root Causes:                                                   ║
║  │   ├── Fraud:               <count>                               ║
║  │   ├── Contract Violation:  <count>                               ║
║  │   ├── Market Condition:    <count>                               ║
║  │   ├── Operational Error:   <count>                               ║
║  │   └── Data Quality:        <count>                               ║
║  └── Avg Supplier Risk Score: XX/100                                ║
║                                                                     ║
║  ⚡ ACTIONS TAKEN                                                    ║
║  ├── Payments Held:          <N> ($XXX,XXX)                         ║
║  ├── Risk Tiers Updated:     <N> suppliers                          ║
║  ├── Invoices Flagged:       <N>                                    ║
║  └── Escalations Pending:    <N> (require human review)             ║
║                                                                     ║
║  📢 NOTIFICATIONS                                                   ║
║  ├── CFO:                    [NOTIFIED / SKIPPED]                   ║
║  ├── Procurement Director:   [NOTIFIED / SKIPPED]                   ║
║  └── Operations Manager:     [NOTIFIED / SKIPPED]                   ║
║                                                                     ║
║  💰 FINANCIAL IMPACT                                                ║
║  ├── Total Amount at Risk:   $X,XXX,XXX                             ║
║  ├── Amount Protected:       $XXX,XXX                               ║
║  └── Estimated Annual Savings: $X.XM                                ║
║                                                                     ║
║  ⚠️  ITEMS REQUIRING HUMAN REVIEW:                                  ║
║  └── [List of escalated items with anomaly IDs and reasons]         ║
║                                                                     ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

## Error Recovery (Fix #10 — Global Circuit Breaker)

| Phase Failure | Recovery |
|:---|:---|
| Phase 1a (ML) fails | Continue with rule-based results only |
| Phase 1b (Rule) fails | Continue with ML results only |
| Phase 2 times out | Report partial investigations, continue to Phase 3 |
| Phase 3 fails on one action | Retry 3×, then escalate; continue remaining actions |
| Phase 4 (Notifications) fails | Log warning — do NOT halt; pipeline results are already saved |
| Any phase completely fails | Report what completed, list what needs manual attention |

---

## Usage Examples

### Full Scan
```bash
cortex -w . -p '$orchestrate-supply-chain Run a complete financial risk assessment for the last 60 days'
```

### Focused Supplier Scan
```bash
cortex -w . -p '$orchestrate-supply-chain Investigate supplier SUP-005 — we suspect pricing issues'
# Skips broad detection, focuses all agents on SUP-005
```

### Report Only (No New Scan)
```bash
cortex -w . -p '$orchestrate-supply-chain Show current risk status without running new scans'
# Queries existing ANOMALY_RESULTS and INVESTIGATION_LOG, produces summary
```

### Individual Agent Calls
```bash
cortex -w . -p '$ml-anomaly-agent Run ML anomaly detection'
cortex -w . -p '$rule-anomaly-agent Check for duplicate invoices and phantom vendors'
cortex -w . -p '$root-cause-agent Investigate ANO-001, ANO-002'
cortex -w . -p '$action-agent Execute actions for INV-001, INV-002'
cortex -w . -p '$notification-agent Draft notifications for CFO and Procurement'
```
