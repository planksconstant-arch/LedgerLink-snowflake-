// Shared mock data for the entire dashboard
// In production: replace with real Snowflake API calls

export const ANOMALIES = [
  { id: 'ANO-2026-001', category: 'PRICE_SPIKE', supplier: 'Dragon Polymers Ltd', supplierId: 'SUP-005', amount: 261954, expected: 88200, deviation: 197, severity: 'CRITICAL', status: 'INVESTIGATED', rootCause: 'CONTRACT_VIOLATION', date: '2026-07-02' },
  { id: 'ANO-2026-002', category: 'DUPLICATE_PAYMENT', supplier: 'AlphaChem Industries', supplierId: 'SUP-001', amount: 151200, expected: 75600, deviation: 100, severity: 'CRITICAL', status: 'ACTION_TAKEN', rootCause: 'FRAUD', date: '2026-07-05' },
  { id: 'ANO-2026-003', category: 'PHANTOM_VENDOR', supplier: 'Phantom Supplies Co', supplierId: 'SUP-008', amount: 93960, expected: 0, deviation: 100, severity: 'CRITICAL', status: 'HOLD', rootCause: 'FRAUD', date: '2026-07-08' },
  { id: 'ANO-2026-004', category: 'TIMING_ANOMALY', supplier: 'TechLink Components', supplierId: 'SUP-015', amount: 104760, expected: 104760, deviation: 0, severity: 'CRITICAL', status: 'ESCALATED', rootCause: 'OPERATIONAL_ERROR', date: '2026-07-06' },
  { id: 'ANO-2026-005', category: 'VOLUME_SPIKE', supplier: 'Dragon Polymers Ltd', supplierId: 'SUP-005', amount: 1500000, expected: 150000, deviation: 900, severity: 'WARNING', status: 'INVESTIGATED', rootCause: 'MARKET_CONDITION', date: '2026-07-10' },
  { id: 'ANO-2026-006', category: 'PRICE_SPIKE', supplier: 'Dragon Polymers Ltd', supplierId: 'SUP-005', amount: 165000, expected: 55500, deviation: 197, severity: 'CRITICAL', status: 'HOLD', rootCause: 'CONTRACT_VIOLATION', date: '2026-07-12' },
  { id: 'ANO-2026-007', category: 'UNMATCHED_INVOICE', supplier: 'Dragon Polymers Ltd', supplierId: 'SUP-005', amount: 102600, expected: 0, deviation: 100, severity: 'WARNING', status: 'FLAGGED', rootCause: 'DATA_QUALITY', date: '2026-07-14' },
  { id: 'ANO-2026-008', category: 'DELIVERY_DEGRADATION', supplier: 'Dragon Polymers Ltd', supplierId: 'SUP-005', amount: 0, expected: 0, deviation: 0, severity: 'WARNING', status: 'MONITORING', rootCause: 'OPERATIONAL_ERROR', date: '2026-07-15' },
  { id: 'ANO-2026-009', category: 'DUPLICATE_PAYMENT', supplier: 'Roschem Technologies', supplierId: 'SUP-003', amount: 321840, expected: 160920, deviation: 100, severity: 'CRITICAL', status: 'HOLD', rootCause: 'FRAUD', date: '2026-07-16' },
  { id: 'ANO-2026-010', category: 'METHOD_CHANGE', supplier: 'Dragon Polymers Ltd', supplierId: 'SUP-005', amount: 261954, expected: 261954, deviation: 0, severity: 'WARNING', status: 'REVIEWED', rootCause: 'OPERATIONAL_ERROR', date: '2026-07-18' },
];

export const SUPPLIERS = [
  { id: 'SUP-005', name: 'Dragon Polymers Ltd', category: 'Raw Materials', country: 'China', riskTier: 'HIGH', composite: 23.5, delivery: 3.5, financial: 9.0, relationship: 1.0, compliance: 10.0, anomalyCount: 6, active: true },
  { id: 'SUP-008', name: 'Phantom Supplies Co', category: 'Electronics', country: 'Unknown', riskTier: 'CRITICAL', composite: 0.0, delivery: 0.0, financial: 25.0, relationship: 12.5, compliance: 0.0, anomalyCount: 1, active: false },
  { id: 'SUP-001', name: 'AlphaChem Industries', category: 'Chemicals', country: 'Germany', riskTier: 'MEDIUM', composite: 51.5, delivery: 19.5, financial: 15.0, relationship: 13.0, compliance: 4.0, anomalyCount: 1, active: true },
  { id: 'SUP-003', name: 'Roschem Technologies', category: 'Polymers', country: 'India', riskTier: 'MEDIUM', composite: 55.0, delivery: 17.0, financial: 12.0, relationship: 14.0, compliance: 12.0, anomalyCount: 1, active: true },
  { id: 'SUP-015', name: 'TechLink Components', category: 'Electronics', country: 'Taiwan', riskTier: 'LOW', composite: 71.0, delivery: 21.0, financial: 22.0, relationship: 16.0, compliance: 12.0, anomalyCount: 1, active: true },
  { id: 'SUP-007', name: 'NovaPack Solutions', category: 'Packaging', country: 'USA', riskTier: 'LOW', composite: 82.5, delivery: 23.0, financial: 23.0, relationship: 18.5, compliance: 18.0, anomalyCount: 0, active: true },
  { id: 'SUP-012', name: 'Atlas Freight Co', category: 'Logistics', country: 'Netherlands', riskTier: 'LOW', composite: 88.0, delivery: 24.0, financial: 22.0, relationship: 19.0, compliance: 23.0, anomalyCount: 0, active: true },
];

export const AUDIT_TRAIL = [
  { id: 'ACT-001', action: 'HOLD_PAYMENT', type: 'AUTO_EXECUTED', anomalyId: 'ANO-2026-002', target: 'PAY-071', amount: 151200, reason: 'Duplicate payment detected', timestamp: '2026-07-27T06:12:33', status: 'SUCCESS', agent: '$action-agent', urgency: 'IMMEDIATE' },
  { id: 'ACT-002', action: 'HOLD_PAYMENT', type: 'AUTO_EXECUTED', anomalyId: 'ANO-2026-003', target: 'PAY-075', amount: 93960, reason: 'Phantom vendor invoice', timestamp: '2026-07-27T06:13:01', status: 'SUCCESS', agent: '$action-agent', urgency: 'IMMEDIATE' },
  { id: 'ACT-003', action: 'UPDATE_RISK_TIER', type: 'AUTO_EXECUTED', anomalyId: 'ANO-2026-001', target: 'SUP-005', amount: null, reason: 'Contract violation: 197% price escalation', timestamp: '2026-07-27T06:13:44', status: 'SUCCESS', agent: '$action-agent', urgency: 'HIGH' },
  { id: 'ACT-004', action: 'NOTIFY_CFO', type: 'AUTO_EXECUTED', anomalyId: 'ANO-2026-009', target: 'CFO', amount: 321840, reason: 'CRITICAL anomaly: Duplicate payment $321K', timestamp: '2026-07-27T06:14:02', status: 'SUCCESS', agent: '$notification-agent', urgency: 'IMMEDIATE' },
  { id: 'ACT-005', action: 'FLAG_INVOICE', type: 'AUTO_EXECUTED', anomalyId: 'ANO-2026-007', target: 'INV-076', amount: 102600, reason: 'Invoice without matching PO', timestamp: '2026-07-27T06:14:55', status: 'SUCCESS', agent: '$action-agent', urgency: 'MEDIUM' },
  { id: 'ACT-006', action: 'ESCALATE', type: 'ESCALATED', anomalyId: 'ANO-2026-004', target: 'PROCUREMENT_DIRECTOR', amount: 104760, reason: 'Payment before invoice date — requires human review', timestamp: '2026-07-27T06:15:18', status: 'PENDING', agent: '$action-agent', urgency: 'HIGH' },
  { id: 'ACT-007', action: 'HOLD_PAYMENT', type: 'AUTO_EXECUTED', anomalyId: 'ANO-2026-006', target: 'PAY-080', amount: 165000, reason: 'Price spike exceeds contractual max 5%', timestamp: '2026-07-27T06:15:55', status: 'SUCCESS', agent: '$action-agent', urgency: 'HIGH' },
];

export const INVESTIGATIONS = [
  { id: 'INV-2026-001', anomalyId: 'ANO-2026-001', supplier: 'Dragon Polymers Ltd', rootCause: 'CONTRACT_VIOLATION', category: 'CONTRACT_VIOLATION', riskScore: 23.5, confidence: 'HIGH', contractViolation: true, sentimentTrend: '-0.44 → -0.71 → -0.85', recommendedAction: 'Initiate contract renegotiation + legal review', aiInvestigated: true, timestamp: '2026-07-27T06:10:01' },
  { id: 'INV-2026-002', anomalyId: 'ANO-2026-002', supplier: 'AlphaChem Industries', rootCause: 'Duplicate invoice SC-2026-0601 submitted and paid twice', category: 'FRAUD', riskScore: 51.5, confidence: 'HIGH', contractViolation: false, sentimentTrend: '0.21 → 0.18 → 0.12', recommendedAction: 'Hold second payment + initiate vendor audit', aiInvestigated: true, timestamp: '2026-07-27T06:10:44' },
  { id: 'INV-2026-003', anomalyId: 'ANO-2026-003', supplier: 'Phantom Supplies Co', rootCause: 'Invoice from inactive supplier with terminated contract', category: 'FRAUD', riskScore: 0.0, confidence: 'HIGH', contractViolation: true, sentimentTrend: 'N/A — no communications', recommendedAction: 'Immediate payment hold + legal escalation', aiInvestigated: false, timestamp: '2026-07-27T06:11:12' },
  { id: 'INV-2026-004', anomalyId: 'ANO-2026-009', supplier: 'Roschem Technologies', rootCause: 'Invoice number RC-2026-0452 submitted twice', category: 'FRAUD', riskScore: 55.0, confidence: 'HIGH', contractViolation: false, sentimentTrend: '0.15 → 0.11 → 0.09', recommendedAction: 'Hold duplicate payment + contact supplier', aiInvestigated: true, timestamp: '2026-07-27T06:11:58' },
];

// Deep-dive evidence for drill-down views
export const ANOMALY_DETAILS = {
  'ANO-2026-001': {
    cortexReasoning: "Analysis of UNSTRUCTURED.CONTRACTS and CORE.INVOICES reveals a severe pricing mismatch. The active contract (CTR-005-MASTER) caps price escalation at 5% YoY. The current invoice reflects a 197% increase over the historical baseline for item 'Industrial Polymer Grade A'. Furthermore, sentiment analysis on recent supplier emails (UNSTRUCTURED.SUPPLIER_COMMS) shows a sharp deteriorating trend from -0.44 to -0.85 over the last 30 days, containing keywords 'force majeure', 'supply constraints', and 'immediate price adjustments'.",
    evidence: {
      contractClause: "Section 4.2 - Pricing: Supplier may not increase prices by more than 5% annually without 90 days written notice.",
      sentimentScore: "-0.85 (Hostile)",
      relatedEmails: 4,
    },
    actionsTaken: [
      { id: 'ACT-003', action: 'UPDATE_RISK_TIER', status: 'SUCCESS', target: 'SUP-005', timestamp: '2026-07-27T06:13:44' }
    ]
  },
  'ANO-2026-002': {
    cortexReasoning: "Detected duplicate payment signature. Invoice 'SC-2026-0601' was submitted on 2026-07-01 and paid via ACH on 2026-07-03. A second invoice with an identical amount ($75,600), supplier ID (SUP-001), and line items was submitted on 2026-07-05 with a slightly obfuscated invoice number 'SC-2026-0601-B'. This triggers the FRAUD detection ruleset.",
    evidence: {
      contractClause: "N/A",
      sentimentScore: "0.12 (Neutral)",
      relatedEmails: 0,
    },
    actionsTaken: [
      { id: 'ACT-001', action: 'HOLD_PAYMENT', status: 'SUCCESS', target: 'PAY-071', timestamp: '2026-07-27T06:12:33' }
    ]
  }
};

export const PIPELINE_AGENTS = [
  { id: 'ml-anomaly-agent', name: 'ML Anomaly Agent', result: '6 anomalies' },
  { id: 'rule-anomaly-agent', name: 'Rule Anomaly Agent', result: '4 anomalies' },
  { id: 'root-cause-agent', name: 'Root Cause Agent', result: '4 investigated' },
  { id: 'action-agent', name: 'Action Agent', result: '7 actions' },
  { id: 'notification-agent', name: 'Notification Agent', result: '3 notified' },
];

export const STATS = {
  anomaliesDetected: 10,
  criticalCount: 5,
  warningCount: 5,
  amountAtRisk: 1801268,
  amountProtected: 611160,
  actionsTaken: 7,
  suppliersMonitored: 30,
  suppliersHighRisk: 2,
  investigationsCompleted: 4,
  notificationsSent: 3,
  paymentsHeld: 3,
  totalHeldAmount: 611160,
};

// Helpers
export const fmt = (n) => n >= 1000000
  ? `$${(n/1000000).toFixed(1)}M`
  : n >= 1000
  ? `$${(n/1000).toFixed(0)}K`
  : `$${n}`;

export const fmtFull = (n) => `$${n.toLocaleString()}`;

export const severityClass = (s) => {
  if (s === 'CRITICAL') return 'badge-critical';
  if (s === 'WARNING')  return 'badge-warning';
  if (s === 'INFO')     return 'badge-info';
  return 'badge-neutral';
};

export const categoryLabel = (c) => ({
  PRICE_SPIKE: 'Price Spike',
  DUPLICATE_PAYMENT: 'Duplicate Payment',
  PHANTOM_VENDOR: 'Phantom Vendor',
  TIMING_ANOMALY: 'Timing Anomaly',
  VOLUME_SPIKE: 'Volume Spike',
  UNMATCHED_INVOICE: 'Unmatched Invoice',
  METHOD_CHANGE: 'Method Change',
  DELIVERY_DEGRADATION: 'Delivery Degradation',
}[c] || c);

export const rootCauseColor = (rc) => ({
  FRAUD: '#F87171',
  CONTRACT_VIOLATION: '#FBBF24',
  MARKET_CONDITION: '#A78BFA',
  OPERATIONAL_ERROR: '#38BDF8',
  DATA_QUALITY: '#71717A',
}[rc] || '#71717A');

export const riskColor = (score) => {
  if (score < 30) return '#F87171';
  if (score < 50) return '#FBBF24';
  if (score < 70) return '#38BDF8';
  return '#34D399';
};

export const riskLabel = (score) => {
  if (score < 30) return 'CRITICAL';
  if (score < 50) return 'HIGH';
  if (score < 70) return 'MEDIUM';
  return 'LOW';
};
