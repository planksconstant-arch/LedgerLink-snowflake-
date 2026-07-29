import pandas as pd

def get_mock_data():
    anomalies_data = [
        {'ID': 'ANO-2026-001', 'Category': 'PRICE_SPIKE', 'Supplier': 'Dragon Polymers Ltd', 'Amount ($)': 261954, 'Expected ($)': 88200, 'Severity': 'CRITICAL', 'Status': 'INVESTIGATED', 'Date': '2026-07-02'},
        {'ID': 'ANO-2026-002', 'Category': 'DUPLICATE_PAYMENT', 'Supplier': 'AlphaChem Industries', 'Amount ($)': 151200, 'Expected ($)': 75600, 'Severity': 'CRITICAL', 'Status': 'ACTION_TAKEN', 'Date': '2026-07-05'},
        {'ID': 'ANO-2026-003', 'Category': 'PHANTOM_VENDOR', 'Supplier': 'Phantom Supplies Co', 'Amount ($)': 93960, 'Expected ($)': 0, 'Severity': 'CRITICAL', 'Status': 'HOLD', 'Date': '2026-07-08'},
        {'ID': 'ANO-2026-004', 'Category': 'TIMING_ANOMALY', 'Supplier': 'TechLink Components', 'Amount ($)': 104760, 'Expected ($)': 104760, 'Severity': 'CRITICAL', 'Status': 'ESCALATED', 'Date': '2026-07-06'},
        {'ID': 'ANO-2026-005', 'Category': 'VOLUME_SPIKE', 'Supplier': 'Dragon Polymers Ltd', 'Amount ($)': 1500000, 'Expected ($)': 150000, 'Severity': 'WARNING', 'Status': 'INVESTIGATED', 'Date': '2026-07-10'},
    ]
    suppliers_data = [
        {'Supplier ID': 'SUP-005', 'Name': 'Dragon Polymers Ltd', 'Risk Tier': 'HIGH', 'Score (0-100)': 23.5, 'Delivery': 3.5, 'Financial': 9.0, 'Compliance': 10.0, 'Anomalies': 6},
        {'Supplier ID': 'SUP-008', 'Name': 'Phantom Supplies Co', 'Risk Tier': 'CRITICAL', 'Score (0-100)': 0.0, 'Delivery': 0.0, 'Financial': 25.0, 'Compliance': 0.0, 'Anomalies': 1},
        {'Supplier ID': 'SUP-001', 'Name': 'AlphaChem Industries', 'Risk Tier': 'MEDIUM', 'Score (0-100)': 51.5, 'Delivery': 19.5, 'Financial': 15.0, 'Compliance': 4.0, 'Anomalies': 1},
    ]
    investigations_data = [
        {'Inv ID': 'INV-2026-001', 'Anomaly': 'ANO-2026-001', 'Supplier': 'Dragon Polymers Ltd', 'Root Cause': 'CONTRACT_VIOLATION', 'Sentiment Trend': '-0.44 → -0.71 → -0.85', 'Confidence': 'HIGH'},
        {'Inv ID': 'INV-2026-002', 'Anomaly': 'ANO-2026-002', 'Supplier': 'AlphaChem Industries', 'Root Cause': 'FRAUD', 'Sentiment Trend': '0.21 → 0.18 → 0.12', 'Confidence': 'HIGH'},
    ]
    audit_data = [
        {'Timestamp': '2026-07-27 06:12:33', 'Action': 'HOLD_PAYMENT', 'Target': 'PAY-071', 'Anomaly': 'ANO-2026-002', 'Status': 'SUCCESS', 'Agent': '-agent', 'HMAC_Signature': 'a1b2c3d4e5f6...'},
        {'Timestamp': '2026-07-27 06:13:44', 'Action': 'UPDATE_RISK_TIER', 'Target': 'SUP-005', 'Anomaly': 'ANO-2026-001', 'Status': 'SUCCESS', 'Agent': '-agent', 'HMAC_Signature': '9f8e7d6c5b4a...'},
        {'Timestamp': '2026-07-27 06:14:02', 'Action': 'NOTIFY_CFO', 'Target': 'CFO', 'Anomaly': 'ANO-2026-009', 'Status': 'SUCCESS', 'Agent': '-agent', 'HMAC_Signature': '1a2b3c4d5e6f...'},
    ]
    return pd.DataFrame(anomalies_data), pd.DataFrame(suppliers_data), pd.DataFrame(investigations_data), pd.DataFrame(audit_data)

cortex_reports = {
    'ANO-2026-001': {
        'reasoning': "Analysis of UNSTRUCTURED.CONTRACTS and CORE.INVOICES reveals a severe pricing mismatch. The active contract (CTR-005-MASTER) caps price escalation at 5% YoY. The current invoice reflects a 197% increase over the historical baseline for item 'Industrial Polymer Grade A'. Furthermore, sentiment analysis on recent supplier emails shows a sharp deteriorating trend from -0.44 to -0.85.",
        'evidence': [
            "**Contract Clause:** Section 4.2 - Pricing: Supplier may not increase prices by more than 5% annually without 90 days written notice.",
            "**Sentiment Score:** -0.85 (Hostile)",
            "**Historical Price:** $300/unit",
            "**Invoiced Price:** $891/unit"
        ],
        'recommended_action': "Hold payment automatically, alert procurement director for renegotiation."
    },
    'ANO-2026-002': {
        'reasoning': "Analysis of CORE.PAYMENTS and CORE.INVOICES shows a duplicate payment attempt for invoice 'INV-024'. This matches the exact amount ($151,200) paid 3 days prior. Cross-referencing the supplier 'AlphaChem Industries', we found no legitimate secondary PO that matches this amount.",
        'evidence': [
            "**Payment History:** Payment of $151,200 cleared on 2026-07-02 (PAY-055).",
            "**Duplicate Trigger:** Rule-Anomaly-Agent detected identical invoice hash on 2026-07-05.",
        ],
        'recommended_action': "Immediate HOLD on payment payload. Notify CFO for fraud investigation."
    },
    'ANO-2026-003': {
        'reasoning': "Supplier 'Phantom Supplies Co' submitted an invoice for $93,960. However, CORE.SUPPLIERS lists this entity as inactive since 2024. Furthermore, no valid PO exists in CORE.PURCHASE_ORDERS for this transaction.",
        'evidence': [
            "**Supplier Status:** INACTIVE (as of Jan 2024)",
            "**Purchase Order:** NONE (Unmatched)",
            "**Risk Score:** 0.0 (CRITICAL)"
        ],
        'recommended_action': "Reject invoice. Flag supplier ID for internal audit."
    },
    'ANO-2026-004': {
        'reasoning': "Payment scheduled for $104,760 to 'TechLink Components'. The payment date (2026-07-06) precedes the invoice approval date. This violates standard FinOps timing rules.",
        'evidence': [
            "**Invoice Status:** PENDING",
            "**Payment Scheduled:** 2026-07-06"
        ],
        'recommended_action': "Escalate to Finance Operations for manual review. Defer payment until invoice is APPROVED."
    },
    'ANO-2026-005': {
        'reasoning': "Volume for 'Dragon Polymers Ltd' jumped from an average of 5,000 units/month to 50,000 units in a single order, a 10x spike. While not inherently fraudulent, this triggers a WARNING due to potential data entry error or unauthorized bulk ordering.",
        'evidence': [
            "**Historical Avg Volume:** 5,000 units",
            "**Current Order Volume:** 50,000 units (10x Spike)",
            "**PO Alignment:** PO-889 confirms large order, but authorization chain lacks VP approval."
        ],
        'recommended_action': "Require secondary human approval (VP level) before proceeding with payment."
    }
}
