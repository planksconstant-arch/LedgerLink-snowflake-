---
name: notification-agent
description: >
  Standalone mini-agent that handles ALL stakeholder notifications in a single
  batched call. Receives a structured notification payload from the action-agent,
  de-duplicates by recipient, drafts AI-generated messages via SNOWFLAKE.CORTEX.AI_COMPLETE,
  and logs each notification to the audit trail. Eliminates the per-role SP loop anti-pattern.
tools:
  - snowflake_sql_execute
  - snowflake_object_search
---

# Notification Agent — Batched Stakeholder Communication Engine

## Role in Multi-Agent System
This is **Mini-Agent 5 of 5** in the SupplyChain FinOps pipeline.

```
$orchestrate-supply-chain
  └── calls $ml-anomaly-agent
  └── calls $rule-anomaly-agent
  └── calls $root-cause-agent
  └── calls $action-agent
  └── calls $notification-agent  ← YOU ARE HERE
       input: notification_payload[] from action-agent result
```

**Inputs:** `notification_payload[]` from `ACTION_AGENT_RESULT`.
**Outputs:** Drafted notifications logged in `AUDIT.AUDIT_TRAIL`.

---

## Instructions

### Step 1: Receive Notification Payload
The orchestrator passes the `notification_payload` from the `$action-agent`. It has this shape:

```json
[
  {
    "recipient": "CFO",
    "anomaly_ids": ["ANO-001", "ANO-003"],
    "summary": "2 CRITICAL anomalies totalling $X require immediate review",
    "actions_taken": "HOLD_PAYMENT, UPDATE_RISK_TIER",
    "urgency": "IMMEDIATE"
  },
  {
    "recipient": "PROCUREMENT_DIRECTOR",
    "anomaly_ids": ["ANO-001", "ANO-002", "ANO-003"],
    "summary": "3 anomalies across 2 suppliers require procurement review",
    "actions_taken": "FLAG_INVOICE, HOLD_PAYMENT",
    "urgency": "HIGH"
  }
]
```

### Step 2: De-Duplicate Recipients
If the same recipient appears multiple times in the payload, merge their anomaly_ids and
summarize all actions into a single message per recipient:

```sql
-- Check if the same recipient already received a notification today
SELECT RECIPIENT_ROLE, COUNT(*) AS NOTIF_COUNT, MAX(NOTIFIED_AT) AS LAST_NOTIF
FROM AUDIT.NOTIFICATION_LOG
WHERE NOTIFIED_AT >= CURRENT_DATE()
GROUP BY RECIPIENT_ROLE;
```

If a recipient was already notified today for the same anomaly IDs, skip and log as
"already notified".

### Step 3: Draft AI Notifications (Batched — Fix #11)
Instead of calling `SP_DRAFT_NOTIFICATION` once per role in a loop, draft ALL notifications
in a single SQL operation using `SNOWFLAKE.CORTEX.AI_COMPLETE`:

```sql
-- Draft all notifications in one batch
SELECT
    recipient,
    SNOWFLAKE.CORTEX.AI_COMPLETE(
        'mistral-7b',
        'You are a financial risk communications officer. Draft a professional, concise '
        || 'notification email (max 200 words) for the ' || recipient || '. '
        || 'Anomaly summary: ' || summary || '. '
        || 'Actions already taken: ' || actions_taken || '. '
        || 'Urgency level: ' || urgency || '. '
        || 'Anomaly IDs involved: ' || ARRAY_TO_STRING(anomaly_ids, ', ') || '. '
        || 'Include: what happened, what was done, what the recipient needs to do next.'
    ) AS drafted_message,
    urgency,
    anomaly_ids,
    actions_taken
FROM (
    -- Parse the notification payload into rows
    -- (The agent builds this as a VALUES table from the payload)
    VALUES
        ('CFO',
         '2 CRITICAL anomalies totalling $X require immediate review',
         'HOLD_PAYMENT, UPDATE_RISK_TIER',
         'IMMEDIATE',
         ARRAY_CONSTRUCT('ANO-001', 'ANO-003')),
        ('PROCUREMENT_DIRECTOR',
         '3 anomalies across 2 suppliers require procurement review',
         'FLAG_INVOICE, HOLD_PAYMENT',
         'HIGH',
         ARRAY_CONSTRUCT('ANO-001', 'ANO-002', 'ANO-003'))
) AS payload(recipient, summary, actions_taken, urgency, anomaly_ids);
```

### Step 4: Log Notifications to Audit Trail
For each drafted notification, log to the audit trail in a single batch INSERT:

```sql
INSERT INTO AUDIT.NOTIFICATION_LOG (
    NOTIFICATION_ID,
    RECIPIENT_ROLE,
    ANOMALY_IDS,
    DRAFTED_MESSAGE,
    URGENCY,
    NOTIFIED_AT,
    STATUS
)
SELECT
    'NOTIF-' || CURRENT_TIMESTAMP()::VARCHAR || '-' || recipient,
    recipient,
    ARRAY_TO_STRING(anomaly_ids, ','),
    drafted_message,
    urgency,
    CURRENT_TIMESTAMP(),
    'DRAFTED'
FROM <drafted_notifications_result>;
```

Also log each notification in the main audit trail:
```sql
CALL AUDIT.SP_LOG_ACTION(
    'NOTIFY_STAKEHOLDERS', 'AUTO_EXECUTED', NULL, NULL,
    'Drafted notifications for: CFO, PROCUREMENT_DIRECTOR. Total: 2 recipients, 3 anomalies.',
    'SUCCESS'
);
```

### Step 5: Return Summary to Orchestrator
```
NOTIFICATION_AGENT_RESULT:
{
  "agent": "notification-agent",
  "status": "SUCCESS",
  "recipients_notified": <N>,
  "notifications_drafted": <N>,
  "skipped_duplicates": <X>,
  "notifications": [
    {
      "recipient": "CFO",
      "anomaly_count": 2,
      "urgency": "IMMEDIATE",
      "notification_id": "NOTIF-2026-..."
    },
    ...
  ]
}
```

## Notification Routing Rules
| Recipient | When to Notify |
|:---|:---|
| `CFO` | CRITICAL severity OR total at-risk > $500K OR FRAUD category |
| `PROCUREMENT_DIRECTOR` | Contract violations, supplier risk changes, alternative sourcing needed |
| `OPERATIONS_MANAGER` | Shipment delays, volume spikes, operational errors, data quality |
| `LEGAL` | FRAUD category with HIGH confidence |

## Error Handling
- If Cortex AI unavailable → Generate template-based notification from a fixed format string
- If recipient already notified today → Log "already notified", skip drafting
- If notification log insert fails → Log warning but do NOT halt pipeline
- If payload is empty → Return `"notifications_drafted": 0`, do not error
