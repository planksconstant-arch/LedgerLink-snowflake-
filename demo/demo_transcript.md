# SupplyChain FinOps Agent — Sample CoCo CLI Demo Transcript

> This document shows a sample CoCo CLI session demonstrating the full end-to-end workflow.
> This is what a successful demo execution looks like.

---

## Session Start

```
$ cortex -w /path/to/snowflake-project

 ❄️ Snowflake CoCo CLI v2.x
 Connected to: YOUR_ACCOUNT.snowflakecomputing.com
 Role: SYSADMIN | Warehouse: FINOPS_WH
 Skills loaded: 4 custom skills detected

 Ready. Type your request or /help for commands.
```

---

## Demo Command

```
> $orchestrate-supply-chain Run a complete financial risk assessment for the last 60 days

🧠 Orchestrator activated. Starting 4-phase assessment...
```

---

## Phase 1: DETECTION

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📡 PHASE 1: ANOMALY DETECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Setting context...
  ✓ USE DATABASE SUPPLY_CHAIN_FINOPS
  ✓ USE WAREHOUSE FINOPS_WH

Running ML-based detection...
  ✓ Invoice anomaly model: 3 anomalies detected
  ✓ Payment anomaly model: 2 anomalies detected

Running rule-based detection...
  ✓ Duplicate invoices: 2 found (INV-072/073, INV-074/075)
  ✓ Phantom vendor invoices: 1 found (INV-071, SUP-008)
  ✓ Unmatched invoices (no PO): 2 found (INV-071, INV-076)
  ✓ Timing anomalies: 1 found (PAY-072 before INV-083)
  ✓ Payment method anomalies: 1 found (PAY-073, ACH→WIRE)

╔══════════════════════════════════════════════════════════════╗
║               ANOMALY DETECTION SUMMARY                     ║
╠══════════════════════════════════════════════════════════════╣
║ Scan Period: 2026-06-01 to 2026-07-24                       ║
║ Total Anomalies: 8                                          ║
║   🔴 CRITICAL: 4                                            ║
║   🟡 WARNING:  3                                            ║
║   🔵 INFO:     1                                            ║
║ Total Amount at Risk: $1,487,514                            ║
╚══════════════════════════════════════════════════════════════╝

| # | ID | Category | Supplier | Amount | Deviation | Severity |
|:--|:---|:---------|:---------|:-------|:----------|:---------|
| 1 | ANO-001 | DUPLICATE_PAYMENT | SUP-001 | $151,200 | 100% | 🔴 CRITICAL |
| 2 | ANO-002 | PRICE_SPIKE | SUP-005 | $261,954 | +197% | 🔴 CRITICAL |
| 3 | ANO-003 | PHANTOM_VENDOR | SUP-008 | $93,960 | N/A | 🔴 CRITICAL |
| 4 | ANO-004 | TIMING_ANOMALY | SUP-015 | $104,760 | -2 days | 🔴 CRITICAL |
| 5 | ANO-005 | DUPLICATE_PAYMENT | SUP-003 | $321,840 | 100% | 🟡 WARNING |
| 6 | ANO-006 | UNMATCHED_INVOICE | SUP-005 | $102,600 | N/A | 🟡 WARNING |
| 7 | ANO-007 | METHOD_CHANGE | SUP-005 | $261,954 | N/A | 🟡 WARNING |
| 8 | ANO-008 | VOLUME_SPIKE | SUP-005 | $1,500,000 | +900% | 🔵 INFO |

Proceeding to Phase 2 for 7 anomalies (CRITICAL + WARNING)...
```

---

## Phase 2: INVESTIGATION

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 PHASE 2: ROOT CAUSE INVESTIGATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Investigating ANO-001 (DUPLICATE_PAYMENT, SUP-001)...
  ✓ Supplier profile: SteelCore Industries — LOW risk, ACTIVE
  ✓ Invoice check: INV-072 and INV-073 have identical invoice number SC-2026-0601
  ✓ Amount: Both $151,200.00
  ✓ Sentiment: Positive (0.85) — no relationship issues
  ✓ Root cause: OPERATIONAL_ERROR — duplicate invoice entry, likely system glitch

╔══════════════════════════════════════════════════════════════╗
║             INVESTIGATION REPORT — ANO-001                  ║
╠══════════════════════════════════════════════════════════════╣
║ Supplier: SteelCore Industries (SUP-001)                    ║
║ Root Cause: Duplicate invoice submission (system glitch)    ║
║ Category: OPERATIONAL_ERROR                                 ║
║ Confidence: HIGH                                            ║
║ Supplier Risk Score: 85/100 (LOW_RISK)                      ║
╠══════════════════════════════════════════════════════════════╣
║ EVIDENCE:                                                   ║
║ • INV-072 and INV-073 share invoice number SC-2026-0601     ║
║ • Both submitted within 3 days of each other                ║
║ • Supplier relationship is POSITIVE (sentiment: 0.85)       ║
║ • SteelCore has 100% on-time delivery and 0 disputes        ║
║ CONTRACT: No violation — pricing within 3% maximum          ║
╠══════════════════════════════════════════════════════════════╣
║ RECOMMENDED: Cancel duplicate payment PAY-071               ║
║ URGENCY: HIGH                                               ║
╚══════════════════════════════════════════════════════════════╝

Investigating ANO-002 (PRICE_SPIKE, SUP-005)...
  ✓ Supplier profile: Dragon Polymers Ltd — HIGH risk, ACTIVE
  ✓ Price history: ABS Polymer was $18.00-$18.50/KG, now $55.00/KG
  ✓ Contract clause: Max escalation 5%/year (§3)
  ✓ Sentiment analysis: DETERIORATING (-0.7 → -0.85 → -0.9)
  ✓ Shipment delays: Increasing (2→4→10→8 days)
  ✓ Root cause: CONTRACT_VIOLATION — 197% price increase vs 5% max

╔══════════════════════════════════════════════════════════════╗
║             INVESTIGATION REPORT — ANO-002                  ║
╠══════════════════════════════════════════════════════════════╣
║ Supplier: Dragon Polymers Ltd (SUP-005)                     ║
║ Root Cause: Unauthorized price escalation of 197%           ║
║ Category: CONTRACT_VIOLATION                                ║
║ Confidence: HIGH                                            ║
║ Supplier Risk Score: 28/100 (CRITICAL_RISK)                 ║
╠══════════════════════════════════════════════════════════════╣
║ EVIDENCE:                                                   ║
║ • ABS Polymer: $18.50/KG → $55.00/KG (+197%)               ║
║ • Contract §3: Max escalation 5%/year ($19.43 max)          ║
║ • Sentiment trend: 0.7 → -0.2 → -0.7 → -0.85 (DECLINING)  ║
║ • Delivery delays: 2→3→4→10→8 days (DETERIORATING)         ║
║ • Supplier threatened to halt supply if prices not accepted  ║
║ CONTRACT: VIOLATED — §3 price escalation clause breached    ║
╠══════════════════════════════════════════════════════════════╣
║ RECOMMENDED: Hold payment + Legal review + Alt. sourcing    ║
║ URGENCY: IMMEDIATE                                          ║
╚══════════════════════════════════════════════════════════════╝

Investigating ANO-003 (PHANTOM_VENDOR, SUP-008)...
  ✓ Supplier profile: GhostVendor Inc — CRITICAL risk, INACTIVE
  ✓ Contract: TERMINATED on 2025-01-15
  ✓ Communications: Suspicious email from unverified domain
  ✓ Root cause: FRAUD — Invoice from terminated, inactive vendor

╔══════════════════════════════════════════════════════════════╗
║             INVESTIGATION REPORT — ANO-003                  ║
╠══════════════════════════════════════════════════════════════╣
║ Supplier: GhostVendor Inc (SUP-008)                         ║
║ Root Cause: Fraudulent invoice from terminated vendor        ║
║ Category: FRAUD                                             ║
║ Confidence: HIGH                                            ║
║ Supplier Risk Score: 0/100 (CRITICAL_RISK)                  ║
╠══════════════════════════════════════════════════════════════╣
║ EVIDENCE:                                                   ║
║ • Supplier marked INACTIVE since 2025-01-15                 ║
║ • Contract TERMINATED for delivery failures + non-compliance║
║ • Invoice GV-2026-071 has NO matching purchase order        ║
║ • Email sent from unverified domain at 22:30 (off-hours)    ║
║ • Follow-up pressure email within 2 weeks                   ║
║ CONTRACT: TERMINATED — vendor flagged as DO NOT USE          ║
╠══════════════════════════════════════════════════════════════╣
║ RECOMMENDED: Reject invoice + Report to CFO + Block vendor  ║
║ URGENCY: IMMEDIATE                                          ║
╚══════════════════════════════════════════════════════════════╝

[... similar reports for ANO-004 through ANO-007 ...]
```

---

## Phase 3: ACTION EXECUTION

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ PHASE 3: ACTION EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Executing actions for ANO-001 (DUPLICATE_PAYMENT)...
  ✓ Payment PAY-071 placed ON HOLD ($151,200)
  ✓ Invoice INV-073 flagged as DISPUTED
  ✓ Audit entry logged: AUD-20260724-4521
  ✓ Follow-up: Verify with SteelCore within 48 hours

Executing actions for ANO-002 (CONTRACT_VIOLATION)...
  ⚠ Amount ($261,954) exceeds auto-execute threshold ($200,000)
  → ESCALATED for human approval
  ✓ Invoice INV-070 flagged as DISPUTED
  ✓ Supplier SUP-005 risk tier: HIGH → CRITICAL
  ✓ CFO notification drafted
  ✓ Procurement Director notification drafted
  ✓ Audit entry logged: AUD-20260724-4522

Executing actions for ANO-003 (FRAUD)...
  ✓ Invoice INV-071 REJECTED (no payment issued)
  ✓ Supplier SUP-008 confirmed BLOCKED
  ✓ CFO notification drafted — fraud alert
  ✓ Audit entry logged: AUD-20260724-4523
  ✓ Follow-up: Engage legal for fraud investigation

Executing actions for ANO-004 (TIMING_ANOMALY)...
  ✓ Payment PAY-072 placed ON HOLD ($104,760)
  ✓ Audit entry logged: AUD-20260724-4524
  ✓ Operations Manager notification drafted

╔══════════════════════════════════════════════════════════════╗
║              ACTION EXECUTION SUMMARY                       ║
╠══════════════════════════════════════════════════════════════╣
║ Actions Executed:                                           ║
║   ✅ Payments held: 2 ($255,960 total)                      ║
║   ✅ Supplier risk tiers updated: 1 (SUP-005 → CRITICAL)    ║
║   ✅ Invoices flagged for review: 4                         ║
║   ✅ Notifications drafted: 5                               ║
║   ✅ Follow-ups scheduled: 3                                ║
║                                                             ║
║ Escalations Required:                                       ║
║   ⚠️  ANO-002: Payment hold for $261,954 needs CFO approval ║
║   ⚠️  ANO-003: Fraud case needs legal engagement            ║
║                                                             ║
║ Estimated Financial Impact:                                 ║
║   💰 Amount protected: $255,960                             ║
║   📊 Suppliers under enhanced monitoring: 2                 ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Phase 4: EXECUTIVE SUMMARY

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 PHASE 4: EXECUTIVE SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

╔══════════════════════════════════════════════════════════════════════╗
║         SUPPLYCHAIN FINOPS AGENT — EXECUTIVE SUMMARY               ║
║         Report Generated: 2026-07-24T15:45:00                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                     ║
║  📊 DETECTION RESULTS                                              ║
║  ├── Total Anomalies Detected: 8                                   ║
║  ├── 🔴 Critical: 4                                                ║
║  ├── 🟡 Warning:  3                                                ║
║  └── 🔵 Info:     1                                                ║
║                                                                     ║
║  🔍 INVESTIGATION RESULTS                                          ║
║  ├── Anomalies Investigated: 7                                     ║
║  ├── Root Causes Found:                                            ║
║  │   ├── Fraud: 1 (phantom vendor)                                 ║
║  │   ├── Contract Violation: 2 (price escalation)                  ║
║  │   ├── Operational Error: 2 (duplicates, timing)                 ║
║  │   └── Other: 2 (method change, unmatched PO)                   ║
║  └── Avg Supplier Risk Score: 42/100                               ║
║                                                                     ║
║  ⚡ ACTIONS TAKEN                                                   ║
║  ├── Payments Held: 2 ($255,960)                                   ║
║  ├── Risk Tiers Updated: 1 supplier                                ║
║  ├── Invoices Flagged: 4                                           ║
║  ├── Notifications Drafted: 5                                      ║
║  └── Follow-ups Scheduled: 3                                       ║
║                                                                     ║
║  💰 FINANCIAL IMPACT                                               ║
║  ├── Total Amount at Risk: $1,487,514                              ║
║  ├── Amount Protected: $255,960                                    ║
║  └── Estimated Annual Savings: $2.1M                               ║
║                                                                     ║
║  ⚠️  ITEMS REQUIRING HUMAN REVIEW:                                 ║
║  ├── ANO-002: $261,954 payment hold (exceeds auto threshold)       ║
║  └── ANO-003: Fraud case — legal engagement required               ║
║                                                                     ║
║  🏆 TOP RISK SUPPLIERS:                                            ║
║  ├── 1. SUP-008 GhostVendor Inc    Score: 0/100  (CRITICAL)       ║
║  ├── 2. SUP-005 Dragon Polymers    Score: 28/100 (CRITICAL)       ║
║  └── 3. SUP-007 Sahara Silicates   Score: 52/100 (MEDIUM)         ║
║                                                                     ║
╚══════════════════════════════════════════════════════════════════════╝

Full audit trail: 12 entries logged in AUDIT.AUDIT_TRAIL
All actions are immutable and traceable.
```

---

## Verification Queries

After the demo, run these queries to verify:

```sql
-- Check audit trail
SELECT * FROM AUDIT.AUDIT_TRAIL ORDER BY CREATED_AT DESC;

-- Check held payments
SELECT * FROM CORE.PAYMENTS WHERE STATUS = 'ON_HOLD';

-- Check flagged invoices
SELECT * FROM CORE.INVOICES WHERE STATUS = 'DISPUTED';

-- Check supplier risk scores
SELECT * FROM ANALYTICS.V_SUPPLIER_RISK_SCORECARD ORDER BY COMPOSITE_HEALTH_SCORE ASC;

-- Check investigation log
SELECT * FROM ANALYTICS.INVESTIGATION_LOG ORDER BY INVESTIGATED_AT DESC;
```
