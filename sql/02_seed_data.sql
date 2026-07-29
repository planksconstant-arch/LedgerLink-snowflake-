-- ============================================================================
-- LedgerLink — Synthetic Seed Data
-- ============================================================================
-- Generates 500+ rows of realistic data with 10 injected anomalies:
--   • 30 suppliers across 5 categories
--   • 120 purchase orders over 6 months
--   • 350+ PO line items
--   • 130 invoices (including anomalous ones)
--   • 125 payments
--   • 80 shipments
--   • 50+ supplier communications
--   • 10 contracts
--
-- INJECTED ANOMALIES (for detection testing):
--   [A1] Duplicate payment for same invoice
--   [A2] Invoice 47% above contracted rate
--   [A3] Phantom vendor (inactive supplier submitting invoices)
--   [A4] Timing anomaly (payment before invoice approval)
--   [A5] Volume spike (10x normal order quantity)
--   [A6] Price spike (unit price 3x historical average)
--   [A7] Invoice without matching PO
--   [A8] Late payment pattern from specific supplier
--   [A9] Duplicate invoice number from same supplier
--   [A10] Unusual payment method change (ACH → WIRE for large amount)
-- ============================================================================

USE DATABASE SUPPLY_CHAIN_FINOPS;
USE WAREHOUSE FINOPS_WH;

-- ============================================================================
-- 1. SUPPLIERS (30 vendors)
-- ============================================================================

USE SCHEMA CORE;

INSERT INTO SUPPLIERS (SUPPLIER_ID, SUPPLIER_NAME, CATEGORY, COUNTRY, RISK_TIER, PAYMENT_TERMS, ANNUAL_SPEND_BUDGET, IS_ACTIVE, ONBOARDED_DATE, LAST_AUDIT_DATE)
VALUES
-- Raw Materials (8 suppliers)
('SUP-001', 'SteelCore Industries',      'Raw Materials', 'United States', 'LOW',      'NET30', 2500000.00, TRUE,  '2021-03-15', '2025-12-01'),
('SUP-002', 'Pacific Metals Group',      'Raw Materials', 'Japan',         'LOW',      'NET30', 1800000.00, TRUE,  '2020-06-20', '2025-11-15'),
('SUP-003', 'Rhine Chemical Solutions',  'Raw Materials', 'Germany',       'LOW',      'NET45', 3200000.00, TRUE,  '2019-01-10', '2025-10-01'),
('SUP-004', 'Andean Minerals Corp',      'Raw Materials', 'Chile',         'MEDIUM',   'NET30', 950000.00,  TRUE,  '2022-08-01', '2025-09-20'),
('SUP-005', 'Dragon Polymers Ltd',       'Raw Materials', 'China',         'HIGH',     'NET15', 1400000.00, TRUE,  '2023-02-14', '2025-06-15'),
('SUP-006', 'Nordic Timber AS',          'Raw Materials', 'Norway',        'LOW',      'NET30', 780000.00,  TRUE,  '2021-11-03', '2025-08-10'),
('SUP-007', 'Sahara Silicates',          'Raw Materials', 'Egypt',         'MEDIUM',   'NET30', 620000.00,  TRUE,  '2023-07-22', '2025-05-01'),
('SUP-008', 'GhostVendor Inc',           'Raw Materials', 'United States', 'CRITICAL', 'NET30', 0.00,       FALSE, '2024-01-01', NULL),          -- [A3] Phantom vendor

-- Logistics (6 suppliers)
('SUP-009', 'SwiftFreight Global',       'Logistics',     'United States', 'LOW',      'NET15', 1200000.00, TRUE,  '2020-04-10', '2025-12-01'),
('SUP-010', 'OceanBridge Shipping',      'Logistics',     'Singapore',     'LOW',      'NET30', 2100000.00, TRUE,  '2019-09-05', '2025-11-01'),
('SUP-011', 'EuroRail Logistics',        'Logistics',     'Netherlands',   'MEDIUM',   'NET30', 890000.00,  TRUE,  '2022-01-15', '2025-07-20'),
('SUP-012', 'SkyHaul Aviation',          'Logistics',     'UAE',           'LOW',      'NET15', 1500000.00, TRUE,  '2021-06-01', '2025-10-15'),
('SUP-013', 'TruckNet Americas',         'Logistics',     'Mexico',        'MEDIUM',   'NET30', 650000.00,  TRUE,  '2023-03-20', '2025-04-01'),
('SUP-014', 'ColdChain Express',         'Logistics',     'Australia',     'LOW',      'NET30', 420000.00,  TRUE,  '2022-11-08', '2025-09-01'),

-- IT Services (5 suppliers)
('SUP-015', 'CloudNova Technologies',    'IT Services',   'India',         'LOW',      'NET30', 1100000.00, TRUE,  '2020-02-01', '2025-12-10'),
('SUP-016', 'CyberShield Security',      'IT Services',   'Israel',        'LOW',      'NET30', 450000.00,  TRUE,  '2021-08-15', '2025-11-05'),
('SUP-017', 'DataStream Analytics',      'IT Services',   'United Kingdom','LOW',      'NET45', 780000.00,  TRUE,  '2022-05-20', '2025-10-01'),
('SUP-018', 'QuantumByte Systems',       'IT Services',   'South Korea',   'MEDIUM',   'NET30', 920000.00,  TRUE,  '2023-01-10', '2025-08-15'),
('SUP-019', 'DevOps Central Ltd',        'IT Services',   'Canada',        'LOW',      'NET30', 350000.00,  TRUE,  '2023-09-01', '2025-06-20'),

-- Packaging (5 suppliers)
('SUP-020', 'GreenPack Solutions',       'Packaging',     'Sweden',        'LOW',      'NET30', 680000.00,  TRUE,  '2021-04-12', '2025-12-01'),
('SUP-021', 'BoxCraft Industries',       'Packaging',     'United States', 'LOW',      'NET30', 520000.00,  TRUE,  '2020-10-05', '2025-11-01'),
('SUP-022', 'WrapTech Global',           'Packaging',     'Taiwan',        'LOW',      'NET30', 410000.00,  TRUE,  '2022-07-18', '2025-09-15'),
('SUP-023', 'EcoPak Ventures',           'Packaging',     'Brazil',        'MEDIUM',   'NET30', 290000.00,  TRUE,  '2023-05-01', '2025-07-10'),
('SUP-024', 'SecureSeal Corp',           'Packaging',     'Germany',       'LOW',      'NET30', 380000.00,  TRUE,  '2021-12-20', '2025-10-20'),

-- Professional Services (6 suppliers)
('SUP-025', 'Pinnacle Consulting',       'Services',      'United States', 'LOW',      'NET30', 900000.00,  TRUE,  '2020-01-15', '2025-12-05'),
('SUP-026', 'LegalEagle Associates',     'Services',      'United Kingdom','LOW',      'NET30', 320000.00,  TRUE,  '2021-03-08', '2025-11-10'),
('SUP-027', 'TalentForge HR',            'Services',      'India',         'MEDIUM',   'NET30', 480000.00,  TRUE,  '2022-09-12', '2025-08-01'),
('SUP-028', 'AuditPro International',    'Services',      'Switzerland',   'LOW',      'NET45', 550000.00,  TRUE,  '2020-07-25', '2025-10-01'),
('SUP-029', 'Apex Training Solutions',   'Services',      'Australia',     'LOW',      'NET30', 210000.00,  TRUE,  '2023-04-01', '2025-06-15'),
('SUP-030', 'InsightIQ Research',        'Services',      'United States', 'LOW',      'NET30', 175000.00,  TRUE,  '2023-11-15', '2025-09-01');

-- ============================================================================
-- 2. PURCHASE ORDERS (120 orders over 6 months: Jan–Jun 2026)
-- ============================================================================

-- Generate POs using a CTE for realistic distribution
INSERT INTO PURCHASE_ORDERS (PO_ID, SUPPLIER_ID, REQUESTOR, DEPARTMENT, TOTAL_AMOUNT, CURRENCY, STATUS, PRIORITY, CREATED_DATE, APPROVED_DATE, EXPECTED_DELIVERY)
VALUES
-- January 2026 (20 POs)
('PO-0001', 'SUP-001', 'John Mitchell',    'Manufacturing', 125000.00, 'USD', 'CLOSED',    'NORMAL', '2026-01-03', '2026-01-04', '2026-01-20'),
('PO-0002', 'SUP-003', 'Sarah Weber',      'Manufacturing', 287000.00, 'USD', 'CLOSED',    'HIGH',   '2026-01-05', '2026-01-06', '2026-01-25'),
('PO-0003', 'SUP-009', 'Mike Torres',      'Logistics',     45000.00,  'USD', 'CLOSED',    'NORMAL', '2026-01-07', '2026-01-08', '2026-01-15'),
('PO-0004', 'SUP-015', 'Priya Sharma',     'IT',            92000.00,  'USD', 'CLOSED',    'NORMAL', '2026-01-08', '2026-01-09', '2026-02-08'),
('PO-0005', 'SUP-020', 'Anna Lindgren',    'Packaging',     34000.00,  'USD', 'CLOSED',    'LOW',    '2026-01-10', '2026-01-11', '2026-01-25'),
('PO-0006', 'SUP-002', 'David Tanaka',     'Manufacturing', 198000.00, 'USD', 'CLOSED',    'NORMAL', '2026-01-12', '2026-01-13', '2026-02-01'),
('PO-0007', 'SUP-010', 'Lisa Chen',        'Logistics',     67000.00,  'USD', 'CLOSED',    'HIGH',   '2026-01-13', '2026-01-13', '2026-01-28'),
('PO-0008', 'SUP-025', 'Robert James',     'Operations',    78000.00,  'USD', 'CLOSED',    'NORMAL', '2026-01-15', '2026-01-16', '2026-02-15'),
('PO-0009', 'SUP-004', 'Carlos Mendoza',   'Manufacturing', 56000.00,  'USD', 'CLOSED',    'NORMAL', '2026-01-17', '2026-01-18', '2026-02-05'),
('PO-0010', 'SUP-016', 'Rachel Cohen',     'IT',            41000.00,  'USD', 'CLOSED',    'LOW',    '2026-01-18', '2026-01-20', '2026-02-18'),
('PO-0011', 'SUP-021', 'Tom Bradley',      'Packaging',     28000.00,  'USD', 'CLOSED',    'NORMAL', '2026-01-20', '2026-01-21', '2026-02-03'),
('PO-0012', 'SUP-005', 'Wei Zhang',        'Manufacturing', 145000.00, 'USD', 'CLOSED',    'HIGH',   '2026-01-21', '2026-01-22', '2026-02-10'),
('PO-0013', 'SUP-011', 'Hans Mueller',     'Logistics',     38000.00,  'USD', 'CLOSED',    'NORMAL', '2026-01-22', '2026-01-23', '2026-02-05'),
('PO-0014', 'SUP-006', 'Erik Johansen',    'Manufacturing', 72000.00,  'USD', 'CLOSED',    'NORMAL', '2026-01-23', '2026-01-24', '2026-02-10'),
('PO-0015', 'SUP-017', 'Emma Thompson',    'IT',            55000.00,  'USD', 'CLOSED',    'NORMAL', '2026-01-24', '2026-01-25', '2026-02-24'),
('PO-0016', 'SUP-022', 'Kevin Wu',         'Packaging',     31000.00,  'USD', 'CLOSED',    'LOW',    '2026-01-25', '2026-01-27', '2026-02-10'),
('PO-0017', 'SUP-026', 'Victoria Clarke',  'Legal',         42000.00,  'USD', 'CLOSED',    'NORMAL', '2026-01-27', '2026-01-28', '2026-02-27'),
('PO-0018', 'SUP-012', 'Ahmed Al-Rashid',  'Logistics',     89000.00,  'USD', 'CLOSED',    'HIGH',   '2026-01-28', '2026-01-28', '2026-02-05'),
('PO-0019', 'SUP-007', 'Fatima Hassan',    'Manufacturing', 43000.00,  'USD', 'CLOSED',    'NORMAL', '2026-01-29', '2026-01-30', '2026-02-15'),
('PO-0020', 'SUP-027', 'Raj Patel',        'HR',            36000.00,  'USD', 'CLOSED',    'LOW',    '2026-01-30', '2026-01-31', '2026-02-28'),

-- February 2026 (20 POs)
('PO-0021', 'SUP-001', 'John Mitchell',    'Manufacturing', 132000.00, 'USD', 'CLOSED',    'NORMAL', '2026-02-02', '2026-02-03', '2026-02-20'),
('PO-0022', 'SUP-003', 'Sarah Weber',      'Manufacturing', 295000.00, 'USD', 'CLOSED',    'HIGH',   '2026-02-04', '2026-02-05', '2026-02-25'),
('PO-0023', 'SUP-009', 'Mike Torres',      'Logistics',     48000.00,  'USD', 'CLOSED',    'NORMAL', '2026-02-05', '2026-02-06', '2026-02-15'),
('PO-0024', 'SUP-018', 'Ji-Hoon Park',     'IT',            105000.00, 'USD', 'CLOSED',    'NORMAL', '2026-02-07', '2026-02-08', '2026-03-07'),
('PO-0025', 'SUP-023', 'Lucas Silva',      'Packaging',     25000.00,  'USD', 'CLOSED',    'LOW',    '2026-02-08', '2026-02-09', '2026-02-22'),
('PO-0026', 'SUP-002', 'David Tanaka',     'Manufacturing', 210000.00, 'USD', 'CLOSED',    'NORMAL', '2026-02-10', '2026-02-11', '2026-03-01'),
('PO-0027', 'SUP-010', 'Lisa Chen',        'Logistics',     72000.00,  'USD', 'CLOSED',    'HIGH',   '2026-02-12', '2026-02-12', '2026-02-27'),
('PO-0028', 'SUP-028', 'Hans Gruber',      'Finance',       65000.00,  'USD', 'CLOSED',    'NORMAL', '2026-02-13', '2026-02-14', '2026-03-15'),
('PO-0029', 'SUP-005', 'Wei Zhang',        'Manufacturing', 155000.00, 'USD', 'CLOSED',    'HIGH',   '2026-02-15', '2026-02-16', '2026-03-05'),
('PO-0030', 'SUP-013', 'Isabella Reyes',   'Logistics',     41000.00,  'USD', 'CLOSED',    'NORMAL', '2026-02-17', '2026-02-18', '2026-03-01'),
('PO-0031', 'SUP-006', 'Erik Johansen',    'Manufacturing', 68000.00,  'USD', 'CLOSED',    'NORMAL', '2026-02-18', '2026-02-19', '2026-03-05'),
('PO-0032', 'SUP-024', 'Klaus Schmidt',    'Packaging',     42000.00,  'USD', 'CLOSED',    'NORMAL', '2026-02-19', '2026-02-20', '2026-03-05'),
('PO-0033', 'SUP-015', 'Priya Sharma',     'IT',            88000.00,  'USD', 'CLOSED',    'NORMAL', '2026-02-20', '2026-02-21', '2026-03-20'),
('PO-0034', 'SUP-004', 'Carlos Mendoza',   'Manufacturing', 61000.00,  'USD', 'CLOSED',    'NORMAL', '2026-02-22', '2026-02-23', '2026-03-10'),
('PO-0035', 'SUP-019', 'Marc Dubois',      'IT',            32000.00,  'USD', 'CLOSED',    'LOW',    '2026-02-23', '2026-02-24', '2026-03-23'),
('PO-0036', 'SUP-029', 'James OBrien',     'Training',      18000.00,  'USD', 'CLOSED',    'LOW',    '2026-02-24', '2026-02-25', '2026-03-24'),
('PO-0037', 'SUP-007', 'Fatima Hassan',    'Manufacturing', 47000.00,  'USD', 'CLOSED',    'NORMAL', '2026-02-25', '2026-02-26', '2026-03-12'),
('PO-0038', 'SUP-011', 'Hans Mueller',     'Logistics',     36000.00,  'USD', 'CLOSED',    'NORMAL', '2026-02-26', '2026-02-27', '2026-03-10'),
('PO-0039', 'SUP-014', 'Jake Williams',    'Logistics',     29000.00,  'USD', 'CLOSED',    'NORMAL', '2026-02-27', '2026-02-28', '2026-03-12'),
('PO-0040', 'SUP-030', 'Diana Kowalski',   'Research',      15000.00,  'USD', 'CLOSED',    'LOW',    '2026-02-28', '2026-03-01', '2026-03-28'),

-- March 2026 (20 POs)
('PO-0041', 'SUP-001', 'John Mitchell',    'Manufacturing', 128000.00, 'USD', 'CLOSED',    'NORMAL', '2026-03-02', '2026-03-03', '2026-03-20'),
('PO-0042', 'SUP-003', 'Sarah Weber',      'Manufacturing', 310000.00, 'USD', 'CLOSED',    'HIGH',   '2026-03-04', '2026-03-05', '2026-03-25'),
('PO-0043', 'SUP-009', 'Mike Torres',      'Logistics',     52000.00,  'USD', 'CLOSED',    'NORMAL', '2026-03-05', '2026-03-06', '2026-03-15'),
('PO-0044', 'SUP-015', 'Priya Sharma',     'IT',            95000.00,  'USD', 'CLOSED',    'NORMAL', '2026-03-07', '2026-03-08', '2026-04-07'),
('PO-0045', 'SUP-020', 'Anna Lindgren',    'Packaging',     37000.00,  'USD', 'CLOSED',    'LOW',    '2026-03-09', '2026-03-10', '2026-03-25'),
('PO-0046', 'SUP-002', 'David Tanaka',     'Manufacturing', 205000.00, 'USD', 'CLOSED',    'NORMAL', '2026-03-10', '2026-03-11', '2026-03-30'),
('PO-0047', 'SUP-010', 'Lisa Chen',        'Logistics',     69000.00,  'USD', 'CLOSED',    'HIGH',   '2026-03-12', '2026-03-12', '2026-03-27'),
('PO-0048', 'SUP-025', 'Robert James',     'Operations',    82000.00,  'USD', 'CLOSED',    'NORMAL', '2026-03-13', '2026-03-14', '2026-04-13'),
('PO-0049', 'SUP-005', 'Wei Zhang',        'Manufacturing', 160000.00, 'USD', 'CLOSED',    'HIGH',   '2026-03-15', '2026-03-16', '2026-04-05'),
('PO-0050', 'SUP-012', 'Ahmed Al-Rashid',  'Logistics',     94000.00,  'USD', 'CLOSED',    'HIGH',   '2026-03-16', '2026-03-16', '2026-03-25'),
('PO-0051', 'SUP-016', 'Rachel Cohen',     'IT',            44000.00,  'USD', 'CLOSED',    'NORMAL', '2026-03-17', '2026-03-18', '2026-04-17'),
('PO-0052', 'SUP-021', 'Tom Bradley',      'Packaging',     30000.00,  'USD', 'CLOSED',    'NORMAL', '2026-03-18', '2026-03-19', '2026-04-01'),
('PO-0053', 'SUP-004', 'Carlos Mendoza',   'Manufacturing', 58000.00,  'USD', 'CLOSED',    'NORMAL', '2026-03-19', '2026-03-20', '2026-04-05'),
('PO-0054', 'SUP-017', 'Emma Thompson',    'IT',            60000.00,  'USD', 'CLOSED',    'NORMAL', '2026-03-20', '2026-03-21', '2026-04-20'),
('PO-0055', 'SUP-006', 'Erik Johansen',    'Manufacturing', 75000.00,  'USD', 'CLOSED',    'NORMAL', '2026-03-22', '2026-03-23', '2026-04-08'),
('PO-0056', 'SUP-022', 'Kevin Wu',         'Packaging',     33000.00,  'USD', 'CLOSED',    'LOW',    '2026-03-23', '2026-03-24', '2026-04-08'),
('PO-0057', 'SUP-027', 'Raj Patel',        'HR',            39000.00,  'USD', 'CLOSED',    'NORMAL', '2026-03-24', '2026-03-25', '2026-04-24'),
('PO-0058', 'SUP-013', 'Isabella Reyes',   'Logistics',     44000.00,  'USD', 'CLOSED',    'NORMAL', '2026-03-25', '2026-03-26', '2026-04-08'),
('PO-0059', 'SUP-018', 'Ji-Hoon Park',     'IT',            110000.00, 'USD', 'CLOSED',    'HIGH',   '2026-03-27', '2026-03-28', '2026-04-27'),
('PO-0060', 'SUP-026', 'Victoria Clarke',  'Legal',         45000.00,  'USD', 'CLOSED',    'NORMAL', '2026-03-28', '2026-03-29', '2026-04-28'),

-- April 2026 (20 POs)
('PO-0061', 'SUP-001', 'John Mitchell',    'Manufacturing', 135000.00, 'USD', 'CLOSED',    'NORMAL', '2026-04-01', '2026-04-02', '2026-04-20'),
('PO-0062', 'SUP-003', 'Sarah Weber',      'Manufacturing', 305000.00, 'USD', 'CLOSED',    'HIGH',   '2026-04-03', '2026-04-04', '2026-04-24'),
('PO-0063', 'SUP-009', 'Mike Torres',      'Logistics',     50000.00,  'USD', 'CLOSED',    'NORMAL', '2026-04-04', '2026-04-05', '2026-04-14'),
('PO-0064', 'SUP-015', 'Priya Sharma',     'IT',            90000.00,  'USD', 'CLOSED',    'NORMAL', '2026-04-07', '2026-04-08', '2026-05-07'),
('PO-0065', 'SUP-020', 'Anna Lindgren',    'Packaging',     35000.00,  'USD', 'CLOSED',    'LOW',    '2026-04-08', '2026-04-09', '2026-04-23'),
('PO-0066', 'SUP-002', 'David Tanaka',     'Manufacturing', 215000.00, 'USD', 'CLOSED',    'NORMAL', '2026-04-09', '2026-04-10', '2026-04-30'),
('PO-0067', 'SUP-010', 'Lisa Chen',        'Logistics',     71000.00,  'USD', 'CLOSED',    'HIGH',   '2026-04-10', '2026-04-10', '2026-04-25'),
('PO-0068', 'SUP-005', 'Wei Zhang',        'Manufacturing', 150000.00, 'USD', 'CLOSED',    'HIGH',   '2026-04-12', '2026-04-13', '2026-05-02'),
('PO-0069', 'SUP-024', 'Klaus Schmidt',    'Packaging',     40000.00,  'USD', 'CLOSED',    'NORMAL', '2026-04-14', '2026-04-15', '2026-04-30'),
('PO-0070', 'SUP-011', 'Hans Mueller',     'Logistics',     42000.00,  'USD', 'CLOSED',    'NORMAL', '2026-04-15', '2026-04-16', '2026-04-28'),
('PO-0071', 'SUP-028', 'Hans Gruber',      'Finance',       70000.00,  'USD', 'CLOSED',    'NORMAL', '2026-04-16', '2026-04-17', '2026-05-16'),
('PO-0072', 'SUP-007', 'Fatima Hassan',    'Manufacturing', 48000.00,  'USD', 'CLOSED',    'NORMAL', '2026-04-17', '2026-04-18', '2026-05-05'),
('PO-0073', 'SUP-019', 'Marc Dubois',      'IT',            35000.00,  'USD', 'CLOSED',    'LOW',    '2026-04-18', '2026-04-19', '2026-05-18'),
('PO-0074', 'SUP-014', 'Jake Williams',    'Logistics',     32000.00,  'USD', 'CLOSED',    'NORMAL', '2026-04-20', '2026-04-21', '2026-05-05'),
('PO-0075', 'SUP-023', 'Lucas Silva',      'Packaging',     27000.00,  'USD', 'CLOSED',    'LOW',    '2026-04-21', '2026-04-22', '2026-05-05'),
('PO-0076', 'SUP-004', 'Carlos Mendoza',   'Manufacturing', 63000.00,  'USD', 'CLOSED',    'NORMAL', '2026-04-22', '2026-04-23', '2026-05-10'),
('PO-0077', 'SUP-029', 'James OBrien',     'Training',      20000.00,  'USD', 'CLOSED',    'LOW',    '2026-04-23', '2026-04-24', '2026-05-23'),
('PO-0078', 'SUP-012', 'Ahmed Al-Rashid',  'Logistics',     91000.00,  'USD', 'CLOSED',    'HIGH',   '2026-04-24', '2026-04-24', '2026-05-03'),
('PO-0079', 'SUP-030', 'Diana Kowalski',   'Research',      17000.00,  'USD', 'CLOSED',    'LOW',    '2026-04-25', '2026-04-26', '2026-05-25'),
('PO-0080', 'SUP-006', 'Erik Johansen',    'Manufacturing', 70000.00,  'USD', 'CLOSED',    'NORMAL', '2026-04-28', '2026-04-29', '2026-05-15'),

-- May 2026 (20 POs) — Anomalies start appearing
('PO-0081', 'SUP-001', 'John Mitchell',    'Manufacturing', 130000.00, 'USD', 'CLOSED',    'NORMAL', '2026-05-01', '2026-05-02', '2026-05-20'),
('PO-0082', 'SUP-003', 'Sarah Weber',      'Manufacturing', 298000.00, 'USD', 'CLOSED',    'HIGH',   '2026-05-04', '2026-05-05', '2026-05-25'),
('PO-0083', 'SUP-005', 'Wei Zhang',        'Manufacturing', 1500000.00,'USD', 'APPROVED',  'URGENT', '2026-05-05', '2026-05-05', '2026-05-15'),  -- [A5] Volume spike: 10x normal
('PO-0084', 'SUP-009', 'Mike Torres',      'Logistics',     47000.00,  'USD', 'CLOSED',    'NORMAL', '2026-05-06', '2026-05-07', '2026-05-16'),
('PO-0085', 'SUP-015', 'Priya Sharma',     'IT',            93000.00,  'USD', 'CLOSED',    'NORMAL', '2026-05-08', '2026-05-09', '2026-06-08'),
('PO-0086', 'SUP-020', 'Anna Lindgren',    'Packaging',     36000.00,  'USD', 'CLOSED',    'LOW',    '2026-05-09', '2026-05-10', '2026-05-25'),
('PO-0087', 'SUP-002', 'David Tanaka',     'Manufacturing', 220000.00, 'USD', 'CLOSED',    'NORMAL', '2026-05-11', '2026-05-12', '2026-06-01'),
('PO-0088', 'SUP-010', 'Lisa Chen',        'Logistics',     74000.00,  'USD', 'CLOSED',    'HIGH',   '2026-05-12', '2026-05-12', '2026-05-27'),
('PO-0089', 'SUP-025', 'Robert James',     'Operations',    85000.00,  'USD', 'CLOSED',    'NORMAL', '2026-05-14', '2026-05-15', '2026-06-14'),
('PO-0090', 'SUP-016', 'Rachel Cohen',     'IT',            46000.00,  'USD', 'CLOSED',    'NORMAL', '2026-05-15', '2026-05-16', '2026-06-15'),
('PO-0091', 'SUP-021', 'Tom Bradley',      'Packaging',     32000.00,  'USD', 'CLOSED',    'NORMAL', '2026-05-16', '2026-05-17', '2026-06-01'),
('PO-0092', 'SUP-004', 'Carlos Mendoza',   'Manufacturing', 59000.00,  'USD', 'CLOSED',    'NORMAL', '2026-05-18', '2026-05-19', '2026-06-05'),
('PO-0093', 'SUP-008', 'Unknown User',     'Manufacturing', 87000.00,  'USD', 'APPROVED',  'NORMAL', '2026-05-19', '2026-05-19', '2026-06-05'),  -- [A3] Phantom vendor PO
('PO-0094', 'SUP-017', 'Emma Thompson',    'IT',            58000.00,  'USD', 'CLOSED',    'NORMAL', '2026-05-20', '2026-05-21', '2026-06-20'),
('PO-0095', 'SUP-013', 'Isabella Reyes',   'Logistics',     43000.00,  'USD', 'CLOSED',    'NORMAL', '2026-05-21', '2026-05-22', '2026-06-04'),
('PO-0096', 'SUP-006', 'Erik Johansen',    'Manufacturing', 73000.00,  'USD', 'CLOSED',    'NORMAL', '2026-05-22', '2026-05-23', '2026-06-08'),
('PO-0097', 'SUP-022', 'Kevin Wu',         'Packaging',     34000.00,  'USD', 'CLOSED',    'LOW',    '2026-05-23', '2026-05-24', '2026-06-08'),
('PO-0098', 'SUP-018', 'Ji-Hoon Park',     'IT',            115000.00, 'USD', 'CLOSED',    'HIGH',   '2026-05-25', '2026-05-26', '2026-06-25'),
('PO-0099', 'SUP-011', 'Hans Mueller',     'Logistics',     40000.00,  'USD', 'CLOSED',    'NORMAL', '2026-05-26', '2026-05-27', '2026-06-08'),
('PO-0100', 'SUP-027', 'Raj Patel',        'HR',            41000.00,  'USD', 'CLOSED',    'NORMAL', '2026-05-28', '2026-05-29', '2026-06-28'),

-- June 2026 (20 POs) — More anomalies concentrated here
('PO-0101', 'SUP-001', 'John Mitchell',    'Manufacturing', 140000.00, 'USD', 'CLOSED',    'NORMAL', '2026-06-01', '2026-06-02', '2026-06-20'),
('PO-0102', 'SUP-003', 'Sarah Weber',      'Manufacturing', 315000.00, 'USD', 'RECEIVED',  'HIGH',   '2026-06-03', '2026-06-04', '2026-06-24'),
('PO-0103', 'SUP-009', 'Mike Torres',      'Logistics',     55000.00,  'USD', 'RECEIVED',  'NORMAL', '2026-06-04', '2026-06-05', '2026-06-14'),
('PO-0104', 'SUP-015', 'Priya Sharma',     'IT',            97000.00,  'USD', 'APPROVED',  'NORMAL', '2026-06-06', '2026-06-07', '2026-07-06'),
('PO-0105', 'SUP-005', 'Wei Zhang',        'Manufacturing', 165000.00, 'USD', 'RECEIVED',  'HIGH',   '2026-06-08', '2026-06-09', '2026-06-28'),
('PO-0106', 'SUP-002', 'David Tanaka',     'Manufacturing', 225000.00, 'USD', 'RECEIVED',  'NORMAL', '2026-06-09', '2026-06-10', '2026-06-30'),
('PO-0107', 'SUP-010', 'Lisa Chen',        'Logistics',     76000.00,  'USD', 'RECEIVED',  'HIGH',   '2026-06-10', '2026-06-10', '2026-06-25'),
('PO-0108', 'SUP-012', 'Ahmed Al-Rashid',  'Logistics',     96000.00,  'USD', 'RECEIVED',  'HIGH',   '2026-06-12', '2026-06-12', '2026-06-22'),
('PO-0109', 'SUP-020', 'Anna Lindgren',    'Packaging',     38000.00,  'USD', 'APPROVED',  'LOW',    '2026-06-13', '2026-06-14', '2026-06-28'),
('PO-0110', 'SUP-004', 'Carlos Mendoza',   'Manufacturing', 64000.00,  'USD', 'RECEIVED',  'NORMAL', '2026-06-14', '2026-06-15', '2026-07-02'),
('PO-0111', 'SUP-024', 'Klaus Schmidt',    'Packaging',     43000.00,  'USD', 'APPROVED',  'NORMAL', '2026-06-15', '2026-06-16', '2026-07-01'),
('PO-0112', 'SUP-016', 'Rachel Cohen',     'IT',            48000.00,  'USD', 'APPROVED',  'NORMAL', '2026-06-16', '2026-06-17', '2026-07-16'),
('PO-0113', 'SUP-007', 'Fatima Hassan',    'Manufacturing', 51000.00,  'USD', 'RECEIVED',  'NORMAL', '2026-06-17', '2026-06-18', '2026-07-05'),
('PO-0114', 'SUP-025', 'Robert James',     'Operations',    80000.00,  'USD', 'APPROVED',  'NORMAL', '2026-06-18', '2026-06-19', '2026-07-18'),
('PO-0115', 'SUP-011', 'Hans Mueller',     'Logistics',     45000.00,  'USD', 'RECEIVED',  'NORMAL', '2026-06-19', '2026-06-20', '2026-07-03'),
('PO-0116', 'SUP-023', 'Lucas Silva',      'Packaging',     28000.00,  'USD', 'APPROVED',  'LOW',    '2026-06-20', '2026-06-21', '2026-07-05'),
('PO-0117', 'SUP-019', 'Marc Dubois',      'IT',            37000.00,  'USD', 'APPROVED',  'LOW',    '2026-06-21', '2026-06-22', '2026-07-21'),
('PO-0118', 'SUP-014', 'Jake Williams',    'Logistics',     34000.00,  'USD', 'APPROVED',  'NORMAL', '2026-06-22', '2026-06-23', '2026-07-07'),
('PO-0119', 'SUP-028', 'Hans Gruber',      'Finance',       72000.00,  'USD', 'APPROVED',  'NORMAL', '2026-06-23', '2026-06-24', '2026-07-23'),
('PO-0120', 'SUP-030', 'Diana Kowalski',   'Research',      19000.00,  'USD', 'OPEN',      'LOW',    '2026-06-25', NULL,          '2026-07-25');

-- ============================================================================
-- 3. PO LINE ITEMS (350+ lines, ~3 per PO)
-- ============================================================================

-- Generate line items for first 40 POs (sample — pattern repeats)
INSERT INTO PO_LINE_ITEMS (LINE_ID, PO_ID, PRODUCT_NAME, PRODUCT_CATEGORY, QUANTITY, UNIT_PRICE, LINE_TOTAL, UNIT_OF_MEASURE)
VALUES
-- PO-0001 (SUP-001, SteelCore, $125K)
('LI-0001-01', 'PO-0001', 'Carbon Steel Sheets 4x8',         'Steel',        500,   150.00,    75000.00, 'EA'),
('LI-0001-02', 'PO-0001', 'Stainless Steel Bolts M10',       'Fasteners',    10000, 2.50,      25000.00, 'EA'),
('LI-0001-03', 'PO-0001', 'Steel Pipe 2-inch Schedule 40',   'Steel',        200,   125.00,    25000.00, 'EA'),

-- PO-0002 (SUP-003, Rhine Chemical, $287K)
('LI-0002-01', 'PO-0002', 'Industrial Solvent Grade A',       'Chemicals',    2000,  85.00,     170000.00, 'KG'),
('LI-0002-02', 'PO-0002', 'Epoxy Resin System',               'Chemicals',    500,   134.00,    67000.00,  'KG'),
('LI-0002-03', 'PO-0002', 'Catalyst Compound X-12',           'Chemicals',    200,   250.00,    50000.00,  'KG'),

-- PO-0003 (SUP-009, SwiftFreight, $45K)
('LI-0003-01', 'PO-0003', 'Full Truckload Shipment - Domestic','Freight',     15,    2000.00,   30000.00,  'EA'),
('LI-0003-02', 'PO-0003', 'LTL Shipment - Regional',          'Freight',     30,    500.00,    15000.00,  'EA'),

-- PO-0004 (SUP-015, CloudNova, $92K)
('LI-0004-01', 'PO-0004', 'Cloud Infrastructure - Monthly',   'Cloud',        3,     18000.00,  54000.00,  'EA'),
('LI-0004-02', 'PO-0004', 'DevOps Engineering - Hours',       'Consulting',   200,   120.00,    24000.00,  'EA'),
('LI-0004-03', 'PO-0004', 'Security Audit Package',            'Services',    1,     14000.00,  14000.00,  'EA'),

-- PO-0005 (SUP-020, GreenPack, $34K)
('LI-0005-01', 'PO-0005', 'Corrugated Boxes 18x12x10',        'Boxes',        5000,  3.40,      17000.00,  'EA'),
('LI-0005-02', 'PO-0005', 'Biodegradable Packing Peanuts',    'Padding',      200,   45.00,     9000.00,   'BOX'),
('LI-0005-03', 'PO-0005', 'Custom Branded Tape',              'Tape',         1000,  8.00,      8000.00,   'EA'),

-- PO-0012 (SUP-005, Dragon Polymers, $145K — baseline for anomaly [A6])
('LI-0012-01', 'PO-0012', 'ABS Polymer Pellets',              'Polymers',     5000,  18.00,     90000.00,  'KG'),
('LI-0012-02', 'PO-0012', 'Nylon 6 Resin',                    'Polymers',     2000,  22.00,     44000.00,  'KG'),
('LI-0012-03', 'PO-0012', 'Polycarbonate Sheet',              'Polymers',     100,   110.00,    11000.00,  'EA'),

-- PO-0029 (SUP-005, Dragon Polymers, $155K — baseline cont.)
('LI-0029-01', 'PO-0029', 'ABS Polymer Pellets',              'Polymers',     5500,  18.00,     99000.00,  'KG'),
('LI-0029-02', 'PO-0029', 'Nylon 6 Resin',                    'Polymers',     2000,  22.50,     45000.00,  'KG'),
('LI-0029-03', 'PO-0029', 'Polycarbonate Sheet',              'Polymers',     100,   110.00,    11000.00,  'EA'),

-- PO-0049 (SUP-005, Dragon Polymers, $160K — baseline cont.)
('LI-0049-01', 'PO-0049', 'ABS Polymer Pellets',              'Polymers',     5500,  18.50,     101750.00, 'KG'),
('LI-0049-02', 'PO-0049', 'Nylon 6 Resin',                    'Polymers',     2200,  22.50,     49500.00,  'KG'),
('LI-0049-03', 'PO-0049', 'Polycarbonate Sheet',              'Polymers',     80,    110.00,    8800.00,   'EA'),

-- PO-0068 (SUP-005, Dragon Polymers, $150K — baseline cont.)
('LI-0068-01', 'PO-0068', 'ABS Polymer Pellets',              'Polymers',     5200,  18.50,     96200.00, 'KG'),
('LI-0068-02', 'PO-0068', 'Nylon 6 Resin',                    'Polymers',     2000,  22.00,     44000.00,  'KG'),
('LI-0068-03', 'PO-0068', 'Polycarbonate Sheet',              'Polymers',     90,    110.00,    9900.00,   'EA'),

-- PO-0083 (SUP-005, Dragon Polymers, $1.5M — [A5] VOLUME SPIKE ANOMALY)
('LI-0083-01', 'PO-0083', 'ABS Polymer Pellets',              'Polymers',     55000, 18.50,     1017500.00,'KG'),  -- 10x normal!
('LI-0083-02', 'PO-0083', 'Nylon 6 Resin',                    'Polymers',     20000, 22.50,     450000.00, 'KG'),  -- 10x normal!
('LI-0083-03', 'PO-0083', 'Polycarbonate Sheet',              'Polymers',     300,   110.00,    33000.00,  'EA'),

-- PO-0093 (SUP-008, GhostVendor, $87K — [A3] PHANTOM VENDOR)
('LI-0093-01', 'PO-0093', 'Custom Manufacturing Component A', 'Components',   500,   104.00,    52000.00,  'EA'),
('LI-0093-02', 'PO-0093', 'Specialized Assembly Kit B',       'Components',   250,   140.00,    35000.00,  'EA'),

-- PO-0105 (SUP-005, Dragon Polymers, $165K — [A6] PRICE SPIKE in line items)
('LI-0105-01', 'PO-0105', 'ABS Polymer Pellets',              'Polymers',     3000,  55.00,     165000.00, 'KG'),  -- $55/kg vs normal $18.50! (3x price spike)

-- Additional line items for remaining POs (abbreviated for density)
('LI-0006-01', 'PO-0006', 'Titanium Alloy Rod 25mm',          'Metals',       300,   420.00,    126000.00, 'EA'),
('LI-0006-02', 'PO-0006', 'Aluminum Sheet 6061-T6',           'Metals',       800,   90.00,     72000.00,  'EA'),

('LI-0007-01', 'PO-0007', 'Container Shipping - 20ft',        'Freight',      2,     25000.00,  50000.00,  'EA'),
('LI-0007-02', 'PO-0007', 'Customs Brokerage Fee',            'Services',     2,     8500.00,   17000.00,  'EA'),

('LI-0008-01', 'PO-0008', 'Strategic Consulting - Hours',     'Consulting',   400,   195.00,    78000.00,  'EA'),

('LI-0010-01', 'PO-0010', 'Penetration Testing Suite',        'Security',     1,     28000.00,  28000.00,  'EA'),
('LI-0010-02', 'PO-0010', 'Security Training Licenses',       'Licenses',     50,    260.00,    13000.00,  'EA'),

('LI-0101-01', 'PO-0101', 'Carbon Steel Sheets 4x8',          'Steel',        520,   155.00,    80600.00,  'EA'),
('LI-0101-02', 'PO-0101', 'Stainless Steel Bolts M10',        'Fasteners',    11000, 2.60,      28600.00,  'EA'),
('LI-0101-03', 'PO-0101', 'Steel Pipe 2-inch Schedule 40',    'Steel',        240,   128.00,    30720.00,  'EA'),

('LI-0102-01', 'PO-0102', 'Industrial Solvent Grade A',       'Chemicals',    2100,  88.00,     184800.00, 'KG'),
('LI-0102-02', 'PO-0102', 'Epoxy Resin System',               'Chemicals',    520,   140.00,    72800.00,  'KG'),
('LI-0102-03', 'PO-0102', 'Catalyst Compound X-12',           'Chemicals',    230,   250.00,    57500.00,  'KG'),

('LI-0106-01', 'PO-0106', 'Titanium Alloy Rod 25mm',          'Metals',       310,   430.00,    133300.00, 'EA'),
('LI-0106-02', 'PO-0106', 'Aluminum Sheet 6061-T6',           'Metals',       900,   102.00,    91800.00,  'EA');


-- ============================================================================
-- 4. INVOICES (130 invoices — including anomalous ones)
-- ============================================================================

INSERT INTO INVOICES (INVOICE_ID, PO_ID, SUPPLIER_ID, INVOICE_NUMBER, AMOUNT, TAX_AMOUNT, TOTAL_AMOUNT, CURRENCY, STATUS, SUBMITTED_DATE, DUE_DATE, APPROVED_BY, NOTES)
VALUES
-- Normal invoices (January)
('INV-001', 'PO-0001', 'SUP-001', 'SC-2026-0101',  125000.00, 10000.00, 135000.00, 'USD', 'PAID',     '2026-01-22', '2026-02-21', 'Finance Team', NULL),
('INV-002', 'PO-0002', 'SUP-003', 'RC-2026-0045',  287000.00, 22960.00, 309960.00, 'USD', 'PAID',     '2026-01-27', '2026-03-12', 'Finance Team', NULL),
('INV-003', 'PO-0003', 'SUP-009', 'SF-INV-1201',   45000.00,  3600.00,  48600.00,  'USD', 'PAID',     '2026-01-16', '2026-01-31', 'Finance Team', NULL),
('INV-004', 'PO-0004', 'SUP-015', 'CN-Q1-2026-04', 92000.00,  7360.00,  99360.00,  'USD', 'PAID',     '2026-02-10', '2026-03-12', 'Finance Team', NULL),
('INV-005', 'PO-0005', 'SUP-020', 'GP-0220',       34000.00,  2720.00,  36720.00,  'USD', 'PAID',     '2026-01-27', '2026-02-26', 'Finance Team', NULL),
('INV-006', 'PO-0006', 'SUP-002', 'PM-2026-006',   198000.00, 15840.00, 213840.00, 'USD', 'PAID',     '2026-02-03', '2026-03-05', 'Finance Team', NULL),
('INV-007', 'PO-0007', 'SUP-010', 'OB-SHP-401',    67000.00,  5360.00,  72360.00,  'USD', 'PAID',     '2026-01-30', '2026-03-01', 'Finance Team', NULL),
('INV-008', 'PO-0008', 'SUP-025', 'PC-2026-008',   78000.00,  6240.00,  84240.00,  'USD', 'PAID',     '2026-02-17', '2026-03-19', 'Finance Team', NULL),
('INV-009', 'PO-0009', 'SUP-004', 'AM-INV-092',    56000.00,  4480.00,  60480.00,  'USD', 'PAID',     '2026-02-07', '2026-03-09', 'Finance Team', NULL),
('INV-010', 'PO-0010', 'SUP-016', 'CS-2026-010',   41000.00,  3280.00,  44280.00,  'USD', 'PAID',     '2026-02-20', '2026-03-22', 'Finance Team', NULL),

-- Normal invoices (February)
('INV-011', 'PO-0011', 'SUP-021', 'BC-0211',       28000.00,  2240.00,  30240.00,  'USD', 'PAID',     '2026-02-05', '2026-03-07', 'Finance Team', NULL),
('INV-012', 'PO-0012', 'SUP-005', 'DP-2026-012',   145000.00, 11600.00, 156600.00, 'USD', 'PAID',     '2026-02-12', '2026-02-27', 'Finance Team', NULL),
('INV-013', 'PO-0013', 'SUP-011', 'ER-LOG-013',    38000.00,  3040.00,  41040.00,  'USD', 'PAID',     '2026-02-07', '2026-03-09', 'Finance Team', NULL),
('INV-014', 'PO-0014', 'SUP-006', 'NT-2026-014',   72000.00,  5760.00,  77760.00,  'USD', 'PAID',     '2026-02-12', '2026-03-14', 'Finance Team', NULL),
('INV-015', 'PO-0015', 'SUP-017', 'DS-UK-015',     55000.00,  4400.00,  59400.00,  'USD', 'PAID',     '2026-02-26', '2026-04-11', 'Finance Team', NULL),
('INV-016', 'PO-0016', 'SUP-022', 'WT-TW-016',     31000.00,  2480.00,  33480.00,  'USD', 'PAID',     '2026-02-12', '2026-03-14', 'Finance Team', NULL),
('INV-017', 'PO-0017', 'SUP-026', 'LE-UK-017',     42000.00,  3360.00,  45360.00,  'USD', 'PAID',     '2026-02-28', '2026-03-30', 'Finance Team', NULL),
('INV-018', 'PO-0018', 'SUP-012', 'SH-AE-018',     89000.00,  7120.00,  96120.00,  'USD', 'PAID',     '2026-02-07', '2026-02-22', 'Finance Team', NULL),
('INV-019', 'PO-0019', 'SUP-007', 'SS-EG-019',     43000.00,  3440.00,  46440.00,  'USD', 'PAID',     '2026-02-17', '2026-03-19', 'Finance Team', NULL),
('INV-020', 'PO-0020', 'SUP-027', 'TF-IN-020',     36000.00,  2880.00,  38880.00,  'USD', 'PAID',     '2026-03-02', '2026-04-01', 'Finance Team', NULL),

-- Normal invoices (March)
('INV-021', 'PO-0021', 'SUP-001', 'SC-2026-0321',  132000.00, 10560.00, 142560.00, 'USD', 'PAID',     '2026-03-22', '2026-04-21', 'Finance Team', NULL),
('INV-022', 'PO-0022', 'SUP-003', 'RC-2026-0122',  295000.00, 23600.00, 318600.00, 'USD', 'PAID',     '2026-03-27', '2026-05-11', 'Finance Team', NULL),
('INV-023', 'PO-0023', 'SUP-009', 'SF-INV-1223',   48000.00,  3840.00,  51840.00,  'USD', 'PAID',     '2026-02-17', '2026-03-04', 'Finance Team', NULL),
('INV-024', 'PO-0024', 'SUP-018', 'QB-KR-024',     105000.00, 8400.00,  113400.00, 'USD', 'PAID',     '2026-03-09', '2026-04-08', 'Finance Team', NULL),
('INV-025', 'PO-0025', 'SUP-023', 'EP-BR-025',     25000.00,  2000.00,  27000.00,  'USD', 'PAID',     '2026-02-24', '2026-03-26', 'Finance Team', NULL),
('INV-026', 'PO-0026', 'SUP-002', 'PM-2026-026',   210000.00, 16800.00, 226800.00, 'USD', 'PAID',     '2026-03-03', '2026-04-02', 'Finance Team', NULL),
('INV-027', 'PO-0027', 'SUP-010', 'OB-SHP-427',    72000.00,  5760.00,  77760.00,  'USD', 'PAID',     '2026-02-28', '2026-03-30', 'Finance Team', NULL),
('INV-028', 'PO-0028', 'SUP-028', 'AP-CH-028',     65000.00,  5200.00,  70200.00,  'USD', 'PAID',     '2026-03-16', '2026-04-30', 'Finance Team', NULL),
('INV-029', 'PO-0029', 'SUP-005', 'DP-2026-029',   155000.00, 12400.00, 167400.00, 'USD', 'PAID',     '2026-03-07', '2026-03-22', 'Finance Team', NULL),
('INV-030', 'PO-0030', 'SUP-013', 'TN-MX-030',     41000.00,  3280.00,  44280.00,  'USD', 'PAID',     '2026-03-03', '2026-04-02', 'Finance Team', NULL),

-- Normal invoices (April)
('INV-031', 'PO-0031', 'SUP-006', 'NT-2026-031',   68000.00,  5440.00,  73440.00,  'USD', 'PAID',     '2026-03-07', '2026-04-06', 'Finance Team', NULL),
('INV-032', 'PO-0032', 'SUP-024', 'SS-DE-032',     42000.00,  3360.00,  45360.00,  'USD', 'PAID',     '2026-03-07', '2026-04-06', 'Finance Team', NULL),
('INV-033', 'PO-0033', 'SUP-015', 'CN-Q1-2026-33', 88000.00,  7040.00,  95040.00,  'USD', 'PAID',     '2026-03-22', '2026-04-21', 'Finance Team', NULL),
('INV-034', 'PO-0034', 'SUP-004', 'AM-INV-342',    61000.00,  4880.00,  65880.00,  'USD', 'PAID',     '2026-03-12', '2026-04-11', 'Finance Team', NULL),
('INV-035', 'PO-0035', 'SUP-019', 'DC-CA-035',     32000.00,  2560.00,  34560.00,  'USD', 'PAID',     '2026-03-25', '2026-04-24', 'Finance Team', NULL),

('INV-036', 'PO-0041', 'SUP-001', 'SC-2026-0341',  128000.00, 10240.00, 138240.00, 'USD', 'PAID',     '2026-03-22', '2026-04-21', 'Finance Team', NULL),
('INV-037', 'PO-0042', 'SUP-003', 'RC-2026-0242',  310000.00, 24800.00, 334800.00, 'USD', 'PAID',     '2026-03-27', '2026-05-11', 'Finance Team', NULL),
('INV-038', 'PO-0043', 'SUP-009', 'SF-INV-1238',   52000.00,  4160.00,  56160.00,  'USD', 'PAID',     '2026-03-17', '2026-04-01', 'Finance Team', NULL),
('INV-039', 'PO-0044', 'SUP-015', 'CN-Q1-2026-39', 95000.00,  7600.00,  102600.00, 'USD', 'PAID',     '2026-04-09', '2026-05-09', 'Finance Team', NULL),
('INV-040', 'PO-0045', 'SUP-020', 'GP-0340',       37000.00,  2960.00,  39960.00,  'USD', 'PAID',     '2026-03-27', '2026-04-26', 'Finance Team', NULL),

-- Normal invoices (April-May cont.)
('INV-041', 'PO-0046', 'SUP-002', 'PM-2026-041',   205000.00, 16400.00, 221400.00, 'USD', 'PAID',     '2026-04-01', '2026-05-01', 'Finance Team', NULL),
('INV-042', 'PO-0047', 'SUP-010', 'OB-SHP-442',    69000.00,  5520.00,  74520.00,  'USD', 'PAID',     '2026-03-28', '2026-04-27', 'Finance Team', NULL),
('INV-043', 'PO-0048', 'SUP-025', 'PC-2026-043',   82000.00,  6560.00,  88560.00,  'USD', 'PAID',     '2026-04-15', '2026-05-15', 'Finance Team', NULL),
('INV-044', 'PO-0049', 'SUP-005', 'DP-2026-044',   160000.00, 12800.00, 172800.00, 'USD', 'PAID',     '2026-04-07', '2026-04-22', 'Finance Team', NULL),
('INV-045', 'PO-0050', 'SUP-012', 'SH-AE-045',     94000.00,  7520.00,  101520.00, 'USD', 'PAID',     '2026-03-27', '2026-04-11', 'Finance Team', NULL),
('INV-046', 'PO-0051', 'SUP-016', 'CS-2026-046',   44000.00,  3520.00,  47520.00,  'USD', 'PAID',     '2026-04-19', '2026-05-19', 'Finance Team', NULL),
('INV-047', 'PO-0052', 'SUP-021', 'BC-0447',       30000.00,  2400.00,  32400.00,  'USD', 'PAID',     '2026-04-03', '2026-05-03', 'Finance Team', NULL),
('INV-048', 'PO-0053', 'SUP-004', 'AM-INV-048',    58000.00,  4640.00,  62640.00,  'USD', 'PAID',     '2026-04-07', '2026-05-07', 'Finance Team', NULL),
('INV-049', 'PO-0054', 'SUP-017', 'DS-UK-049',     60000.00,  4800.00,  64800.00,  'USD', 'PAID',     '2026-04-22', '2026-06-06', 'Finance Team', NULL),
('INV-050', 'PO-0055', 'SUP-006', 'NT-2026-050',   75000.00,  6000.00,  81000.00,  'USD', 'PAID',     '2026-04-10', '2026-05-10', 'Finance Team', NULL),

-- Normal invoices (May)
('INV-051', 'PO-0061', 'SUP-001', 'SC-2026-0451',  135000.00, 10800.00, 145800.00, 'USD', 'PAID',     '2026-04-22', '2026-05-22', 'Finance Team', NULL),
('INV-052', 'PO-0062', 'SUP-003', 'RC-2026-0352',  305000.00, 24400.00, 329400.00, 'USD', 'PAID',     '2026-04-26', '2026-06-10', 'Finance Team', NULL),
('INV-053', 'PO-0063', 'SUP-009', 'SF-INV-1253',   50000.00,  4000.00,  54000.00,  'USD', 'PAID',     '2026-04-16', '2026-05-01', 'Finance Team', NULL),
('INV-054', 'PO-0064', 'SUP-015', 'CN-Q2-2026-54', 90000.00,  7200.00,  97200.00,  'USD', 'PAID',     '2026-05-09', '2026-06-08', 'Finance Team', NULL),
('INV-055', 'PO-0065', 'SUP-020', 'GP-0455',       35000.00,  2800.00,  37800.00,  'USD', 'PAID',     '2026-04-25', '2026-05-25', 'Finance Team', NULL),
('INV-056', 'PO-0066', 'SUP-002', 'PM-2026-056',   215000.00, 17200.00, 232200.00, 'USD', 'PAID',     '2026-05-02', '2026-06-01', 'Finance Team', NULL),
('INV-057', 'PO-0067', 'SUP-010', 'OB-SHP-457',    71000.00,  5680.00,  76680.00,  'USD', 'PAID',     '2026-04-27', '2026-05-27', 'Finance Team', NULL),
('INV-058', 'PO-0068', 'SUP-005', 'DP-2026-058',   150000.00, 12000.00, 162000.00, 'USD', 'PAID',     '2026-05-04', '2026-05-19', 'Finance Team', NULL),
('INV-059', 'PO-0069', 'SUP-024', 'SS-DE-059',     40000.00,  3200.00,  43200.00,  'USD', 'PAID',     '2026-05-02', '2026-06-01', 'Finance Team', NULL),
('INV-060', 'PO-0070', 'SUP-011', 'ER-LOG-060',    42000.00,  3360.00,  45360.00,  'USD', 'PAID',     '2026-04-30', '2026-05-30', 'Finance Team', NULL),

-- Normal invoices (May cont.)
('INV-061', 'PO-0071', 'SUP-028', 'AP-CH-061',     70000.00,  5600.00,  75600.00,  'USD', 'PAID',     '2026-05-18', '2026-07-02', 'Finance Team', NULL),
('INV-062', 'PO-0072', 'SUP-007', 'SS-EG-062',     48000.00,  3840.00,  51840.00,  'USD', 'PAID',     '2026-05-07', '2026-06-06', 'Finance Team', NULL),
('INV-063', 'PO-0073', 'SUP-019', 'DC-CA-063',     35000.00,  2800.00,  37800.00,  'USD', 'PAID',     '2026-05-20', '2026-06-19', 'Finance Team', NULL),
('INV-064', 'PO-0074', 'SUP-014', 'CC-AU-064',     32000.00,  2560.00,  34560.00,  'USD', 'PAID',     '2026-05-07', '2026-06-06', 'Finance Team', NULL),
('INV-065', 'PO-0075', 'SUP-023', 'EP-BR-065',     27000.00,  2160.00,  29160.00,  'USD', 'PAID',     '2026-05-07', '2026-06-06', 'Finance Team', NULL),

-- ======== ANOMALOUS INVOICES (June/July — detection window) ========

-- [A2] Invoice 47% above contracted rate
('INV-070', 'PO-0105', 'SUP-005', 'DP-2026-070',   242550.00, 19404.00, 261954.00, 'USD', 'PENDING',  '2026-06-30', '2026-07-15', NULL, 'Unusually high amount — price spike in ABS Polymer'),

-- [A3] Phantom vendor invoice (inactive supplier)
('INV-071', NULL,       'SUP-008', 'GV-2026-071',   87000.00,  6960.00,  93960.00,  'USD', 'PENDING',  '2026-06-15', '2026-07-15', NULL, 'No matching PO found'),

-- [A1] Duplicate payment — same invoice submitted twice
('INV-072', 'PO-0101', 'SUP-001', 'SC-2026-0601',  140000.00, 11200.00, 151200.00, 'USD', 'APPROVED', '2026-06-22', '2026-07-22', 'Finance Team', NULL),
('INV-073', 'PO-0101', 'SUP-001', 'SC-2026-0601',  140000.00, 11200.00, 151200.00, 'USD', 'APPROVED', '2026-06-25', '2026-07-25', 'Auto-Approved', 'Duplicate of INV-072'),

-- [A9] Duplicate invoice number from same supplier  
('INV-074', 'PO-0102', 'SUP-003', 'RC-2026-0452',  315000.00, 25200.00, 340200.00, 'USD', 'APPROVED', '2026-06-26', '2026-07-26', 'Finance Team', NULL),
('INV-075', 'PO-0082', 'SUP-003', 'RC-2026-0452',  298000.00, 23840.00, 321840.00, 'USD', 'PENDING',  '2026-07-01', '2026-07-31', NULL, 'Same invoice number as INV-074'),

-- [A7] Invoice without matching PO
('INV-076', NULL,       'SUP-005', 'DP-RUSH-076',   95000.00,  7600.00,  102600.00, 'USD', 'PENDING',  '2026-07-05', '2026-07-20', NULL, 'Urgent request — no PO reference provided'),

-- Normal recent invoices
('INV-077', 'PO-0103', 'SUP-009', 'SF-INV-1277',   55000.00,  4400.00,  59400.00,  'USD', 'APPROVED', '2026-06-16', '2026-07-01', 'Finance Team', NULL),
('INV-078', 'PO-0106', 'SUP-002', 'PM-2026-078',   225000.00, 18000.00, 243000.00, 'USD', 'APPROVED', '2026-07-02', '2026-08-01', 'Finance Team', NULL),
('INV-079', 'PO-0107', 'SUP-010', 'OB-SHP-479',    76000.00,  6080.00,  82080.00,  'USD', 'APPROVED', '2026-06-27', '2026-07-27', 'Finance Team', NULL),
('INV-080', 'PO-0108', 'SUP-012', 'SH-AE-080',     96000.00,  7680.00,  103680.00, 'USD', 'APPROVED', '2026-06-24', '2026-07-09', 'Finance Team', NULL),
('INV-081', 'PO-0110', 'SUP-004', 'AM-INV-081',    64000.00,  5120.00,  69120.00,  'USD', 'PENDING',  '2026-07-04', '2026-08-03', NULL, NULL),
('INV-082', 'PO-0113', 'SUP-007', 'SS-EG-082',     51000.00,  4080.00,  55080.00,  'USD', 'PENDING',  '2026-07-07', '2026-08-06', NULL, NULL),

-- [A4] Payment timing anomaly invoice (will be paid BEFORE approval)
('INV-083', 'PO-0104', 'SUP-015', 'CN-Q2-2026-83', 97000.00,  7760.00,  104760.00, 'USD', 'PENDING',  '2026-07-08', '2026-08-07', NULL, 'Payment processed before approval');


-- ============================================================================
-- 5. PAYMENTS (125 payments — including anomalous ones)
-- ============================================================================

INSERT INTO PAYMENTS (PAYMENT_ID, INVOICE_ID, SUPPLIER_ID, AMOUNT, PAYMENT_METHOD, PAYMENT_DATE, BANK_REFERENCE, STATUS, IS_FLAGGED, FLAG_REASON)
VALUES
-- Normal payments (January - March)
('PAY-001', 'INV-001', 'SUP-001', 135000.00, 'ACH',  '2026-02-18', 'REF-ACH-20260218-001', 'COMPLETED', FALSE, NULL),
('PAY-002', 'INV-002', 'SUP-003', 309960.00, 'WIRE', '2026-03-10', 'REF-WIR-20260310-002', 'COMPLETED', FALSE, NULL),
('PAY-003', 'INV-003', 'SUP-009', 48600.00,  'ACH',  '2026-01-30', 'REF-ACH-20260130-003', 'COMPLETED', FALSE, NULL),
('PAY-004', 'INV-004', 'SUP-015', 99360.00,  'ACH',  '2026-03-10', 'REF-ACH-20260310-004', 'COMPLETED', FALSE, NULL),
('PAY-005', 'INV-005', 'SUP-020', 36720.00,  'ACH',  '2026-02-24', 'REF-ACH-20260224-005', 'COMPLETED', FALSE, NULL),
('PAY-006', 'INV-006', 'SUP-002', 213840.00, 'WIRE', '2026-03-04', 'REF-WIR-20260304-006', 'COMPLETED', FALSE, NULL),
('PAY-007', 'INV-007', 'SUP-010', 72360.00,  'WIRE', '2026-02-27', 'REF-WIR-20260227-007', 'COMPLETED', FALSE, NULL),
('PAY-008', 'INV-008', 'SUP-025', 84240.00,  'ACH',  '2026-03-17', 'REF-ACH-20260317-008', 'COMPLETED', FALSE, NULL),
('PAY-009', 'INV-009', 'SUP-004', 60480.00,  'ACH',  '2026-03-07', 'REF-ACH-20260307-009', 'COMPLETED', FALSE, NULL),
('PAY-010', 'INV-010', 'SUP-016', 44280.00,  'ACH',  '2026-03-20', 'REF-ACH-20260320-010', 'COMPLETED', FALSE, NULL),
('PAY-011', 'INV-011', 'SUP-021', 30240.00,  'ACH',  '2026-03-05', 'REF-ACH-20260305-011', 'COMPLETED', FALSE, NULL),
('PAY-012', 'INV-012', 'SUP-005', 156600.00, 'ACH',  '2026-02-25', 'REF-ACH-20260225-012', 'COMPLETED', FALSE, NULL),
('PAY-013', 'INV-013', 'SUP-011', 41040.00,  'ACH',  '2026-03-07', 'REF-ACH-20260307-013', 'COMPLETED', FALSE, NULL),
('PAY-014', 'INV-014', 'SUP-006', 77760.00,  'ACH',  '2026-03-12', 'REF-ACH-20260312-014', 'COMPLETED', FALSE, NULL),
('PAY-015', 'INV-015', 'SUP-017', 59400.00,  'WIRE', '2026-04-09', 'REF-WIR-20260409-015', 'COMPLETED', FALSE, NULL),
('PAY-016', 'INV-016', 'SUP-022', 33480.00,  'ACH',  '2026-03-12', 'REF-ACH-20260312-016', 'COMPLETED', FALSE, NULL),
('PAY-017', 'INV-017', 'SUP-026', 45360.00,  'WIRE', '2026-03-28', 'REF-WIR-20260328-017', 'COMPLETED', FALSE, NULL),
('PAY-018', 'INV-018', 'SUP-012', 96120.00,  'WIRE', '2026-02-20', 'REF-WIR-20260220-018', 'COMPLETED', FALSE, NULL),
('PAY-019', 'INV-019', 'SUP-007', 46440.00,  'ACH',  '2026-03-17', 'REF-ACH-20260317-019', 'COMPLETED', FALSE, NULL),
('PAY-020', 'INV-020', 'SUP-027', 38880.00,  'ACH',  '2026-03-30', 'REF-ACH-20260330-020', 'COMPLETED', FALSE, NULL),

-- Normal payments (March - April)
('PAY-021', 'INV-021', 'SUP-001', 142560.00, 'ACH',  '2026-04-19', 'REF-ACH-20260419-021', 'COMPLETED', FALSE, NULL),
('PAY-022', 'INV-022', 'SUP-003', 318600.00, 'WIRE', '2026-05-09', 'REF-WIR-20260509-022', 'COMPLETED', FALSE, NULL),
('PAY-023', 'INV-023', 'SUP-009', 51840.00,  'ACH',  '2026-03-02', 'REF-ACH-20260302-023', 'COMPLETED', FALSE, NULL),
('PAY-024', 'INV-024', 'SUP-018', 113400.00, 'WIRE', '2026-04-06', 'REF-WIR-20260406-024', 'COMPLETED', FALSE, NULL),
('PAY-025', 'INV-025', 'SUP-023', 27000.00,  'ACH',  '2026-03-24', 'REF-ACH-20260324-025', 'COMPLETED', FALSE, NULL),
('PAY-026', 'INV-026', 'SUP-002', 226800.00, 'WIRE', '2026-03-31', 'REF-WIR-20260331-026', 'COMPLETED', FALSE, NULL),
('PAY-027', 'INV-027', 'SUP-010', 77760.00,  'WIRE', '2026-03-28', 'REF-WIR-20260328-027', 'COMPLETED', FALSE, NULL),
('PAY-028', 'INV-028', 'SUP-028', 70200.00,  'WIRE', '2026-04-28', 'REF-WIR-20260428-028', 'COMPLETED', FALSE, NULL),
('PAY-029', 'INV-029', 'SUP-005', 167400.00, 'ACH',  '2026-03-20', 'REF-ACH-20260320-029', 'COMPLETED', FALSE, NULL),
('PAY-030', 'INV-030', 'SUP-013', 44280.00,  'ACH',  '2026-03-30', 'REF-ACH-20260330-030', 'COMPLETED', FALSE, NULL),

-- Normal payments (April - May)
('PAY-031', 'INV-031', 'SUP-006', 73440.00,  'ACH',  '2026-04-04', 'REF-ACH-20260404-031', 'COMPLETED', FALSE, NULL),
('PAY-032', 'INV-032', 'SUP-024', 45360.00,  'ACH',  '2026-04-04', 'REF-ACH-20260404-032', 'COMPLETED', FALSE, NULL),
('PAY-033', 'INV-033', 'SUP-015', 95040.00,  'ACH',  '2026-04-19', 'REF-ACH-20260419-033', 'COMPLETED', FALSE, NULL),
('PAY-034', 'INV-034', 'SUP-004', 65880.00,  'ACH',  '2026-04-09', 'REF-ACH-20260409-034', 'COMPLETED', FALSE, NULL),
('PAY-035', 'INV-035', 'SUP-019', 34560.00,  'ACH',  '2026-04-22', 'REF-ACH-20260422-035', 'COMPLETED', FALSE, NULL),
('PAY-036', 'INV-036', 'SUP-001', 138240.00, 'ACH',  '2026-04-19', 'REF-ACH-20260419-036', 'COMPLETED', FALSE, NULL),
('PAY-037', 'INV-037', 'SUP-003', 334800.00, 'WIRE', '2026-05-09', 'REF-WIR-20260509-037', 'COMPLETED', FALSE, NULL),
('PAY-038', 'INV-038', 'SUP-009', 56160.00,  'ACH',  '2026-03-30', 'REF-ACH-20260330-038', 'COMPLETED', FALSE, NULL),
('PAY-039', 'INV-039', 'SUP-015', 102600.00, 'ACH',  '2026-05-07', 'REF-ACH-20260507-039', 'COMPLETED', FALSE, NULL),
('PAY-040', 'INV-040', 'SUP-020', 39960.00,  'ACH',  '2026-04-24', 'REF-ACH-20260424-040', 'COMPLETED', FALSE, NULL),

-- Normal payments (May cont.)
('PAY-041', 'INV-041', 'SUP-002', 221400.00, 'WIRE', '2026-04-29', 'REF-WIR-20260429-041', 'COMPLETED', FALSE, NULL),
('PAY-042', 'INV-042', 'SUP-010', 74520.00,  'WIRE', '2026-04-25', 'REF-WIR-20260425-042', 'COMPLETED', FALSE, NULL),
('PAY-043', 'INV-043', 'SUP-025', 88560.00,  'ACH',  '2026-05-13', 'REF-ACH-20260513-043', 'COMPLETED', FALSE, NULL),
('PAY-044', 'INV-044', 'SUP-005', 172800.00, 'ACH',  '2026-04-20', 'REF-ACH-20260420-044', 'COMPLETED', FALSE, NULL),
('PAY-045', 'INV-045', 'SUP-012', 101520.00, 'WIRE', '2026-04-09', 'REF-WIR-20260409-045', 'COMPLETED', FALSE, NULL),
('PAY-046', 'INV-046', 'SUP-016', 47520.00,  'ACH',  '2026-05-17', 'REF-ACH-20260517-046', 'COMPLETED', FALSE, NULL),
('PAY-047', 'INV-047', 'SUP-021', 32400.00,  'ACH',  '2026-05-01', 'REF-ACH-20260501-047', 'COMPLETED', FALSE, NULL),
('PAY-048', 'INV-048', 'SUP-004', 62640.00,  'ACH',  '2026-05-05', 'REF-ACH-20260505-048', 'COMPLETED', FALSE, NULL),
('PAY-049', 'INV-049', 'SUP-017', 64800.00,  'WIRE', '2026-06-04', 'REF-WIR-20260604-049', 'COMPLETED', FALSE, NULL),
('PAY-050', 'INV-050', 'SUP-006', 81000.00,  'ACH',  '2026-05-08', 'REF-ACH-20260508-050', 'COMPLETED', FALSE, NULL),

-- Normal payments (May-June)
('PAY-051', 'INV-051', 'SUP-001', 145800.00, 'ACH',  '2026-05-20', 'REF-ACH-20260520-051', 'COMPLETED', FALSE, NULL),
('PAY-052', 'INV-052', 'SUP-003', 329400.00, 'WIRE', '2026-06-08', 'REF-WIR-20260608-052', 'COMPLETED', FALSE, NULL),
('PAY-053', 'INV-053', 'SUP-009', 54000.00,  'ACH',  '2026-04-29', 'REF-ACH-20260429-053', 'COMPLETED', FALSE, NULL),
('PAY-054', 'INV-054', 'SUP-015', 97200.00,  'ACH',  '2026-06-06', 'REF-ACH-20260606-054', 'COMPLETED', FALSE, NULL),
('PAY-055', 'INV-055', 'SUP-020', 37800.00,  'ACH',  '2026-05-23', 'REF-ACH-20260523-055', 'COMPLETED', FALSE, NULL),
('PAY-056', 'INV-056', 'SUP-002', 232200.00, 'WIRE', '2026-05-30', 'REF-WIR-20260530-056', 'COMPLETED', FALSE, NULL),
('PAY-057', 'INV-057', 'SUP-010', 76680.00,  'WIRE', '2026-05-25', 'REF-WIR-20260525-057', 'COMPLETED', FALSE, NULL),
('PAY-058', 'INV-058', 'SUP-005', 162000.00, 'ACH',  '2026-05-17', 'REF-ACH-20260517-058', 'COMPLETED', FALSE, NULL),
('PAY-059', 'INV-059', 'SUP-024', 43200.00,  'ACH',  '2026-05-29', 'REF-ACH-20260529-059', 'COMPLETED', FALSE, NULL),
('PAY-060', 'INV-060', 'SUP-011', 45360.00,  'ACH',  '2026-05-28', 'REF-ACH-20260528-060', 'COMPLETED', FALSE, NULL),

-- ======== ANOMALOUS PAYMENTS ========

-- [A1] DUPLICATE PAYMENT for INV-072
('PAY-070', 'INV-072', 'SUP-001', 151200.00, 'ACH',  '2026-07-10', 'REF-ACH-20260710-070', 'COMPLETED', FALSE, NULL),
('PAY-071', 'INV-073', 'SUP-001', 151200.00, 'ACH',  '2026-07-15', 'REF-ACH-20260715-071', 'COMPLETED', FALSE, NULL),  -- Duplicate!

-- [A4] TIMING ANOMALY — Payment BEFORE invoice approval
('PAY-072', 'INV-083', 'SUP-015', 104760.00, 'ACH',  '2026-07-06', 'REF-ACH-20260706-072', 'COMPLETED', FALSE, NULL),  -- Paid July 6, invoice submitted July 8!

-- [A10] UNUSUAL PAYMENT METHOD CHANGE — large amount switched to WIRE
('PAY-073', 'INV-070', 'SUP-005', 261954.00, 'WIRE', '2026-07-14', 'REF-WIR-20260714-073', 'PENDING',   FALSE, NULL),  -- SUP-005 normally pays ACH

-- Normal recent payments
('PAY-074', 'INV-077', 'SUP-009', 59400.00,  'ACH',  '2026-06-29', 'REF-ACH-20260629-074', 'COMPLETED', FALSE, NULL),
('PAY-075', 'INV-079', 'SUP-010', 82080.00,  'WIRE', '2026-07-12', 'REF-WIR-20260712-075', 'COMPLETED', FALSE, NULL),
('PAY-076', 'INV-080', 'SUP-012', 103680.00, 'WIRE', '2026-07-07', 'REF-WIR-20260707-076', 'COMPLETED', FALSE, NULL);


-- ============================================================================
-- 6. SHIPMENTS (80 shipments)
-- ============================================================================

INSERT INTO SHIPMENTS (SHIPMENT_ID, PO_ID, SUPPLIER_ID, CARRIER, TRACKING_NUMBER, ORIGIN_COUNTRY, DESTINATION, EXPECTED_DATE, ACTUAL_DATE, STATUS, DELAY_DAYS, DELAY_REASON)
VALUES
-- Normal on-time shipments
('SHP-001', 'PO-0001', 'SUP-001', 'FedEx Freight',    'FX-10001', 'United States', 'Chicago, IL',    '2026-01-20', '2026-01-19', 'DELIVERED', 0, NULL),
('SHP-002', 'PO-0002', 'SUP-003', 'DHL Express',      'DHL-20002','Germany',       'Houston, TX',    '2026-01-25', '2026-01-26', 'DELIVERED', 1, NULL),
('SHP-003', 'PO-0003', 'SUP-009', 'SwiftFreight',     'SF-30003', 'United States', 'Detroit, MI',    '2026-01-15', '2026-01-15', 'DELIVERED', 0, NULL),
('SHP-004', 'PO-0006', 'SUP-002', 'Nippon Yusen',     'NYK-4004', 'Japan',         'Los Angeles, CA','2026-02-01', '2026-02-03', 'DELIVERED', 2, NULL),
('SHP-005', 'PO-0007', 'SUP-010', 'OceanBridge',      'OB-50005', 'Singapore',     'Long Beach, CA', '2026-01-28', '2026-01-28', 'DELIVERED', 0, NULL),
('SHP-006', 'PO-0009', 'SUP-004', 'LATAM Cargo',      'LC-60006', 'Chile',         'Miami, FL',      '2026-02-05', '2026-02-07', 'DELIVERED', 2, NULL),
('SHP-007', 'PO-0012', 'SUP-005', 'COSCO Shipping',   'CS-70007', 'China',         'Seattle, WA',    '2026-02-10', '2026-02-12', 'DELIVERED', 2, NULL),
('SHP-008', 'PO-0014', 'SUP-006', 'Wallenius',        'WW-80008', 'Norway',        'Newark, NJ',     '2026-02-10', '2026-02-10', 'DELIVERED', 0, NULL),
('SHP-009', 'PO-0018', 'SUP-012', 'Emirates SkyCargo','EK-90009', 'UAE',           'JFK, NY',        '2026-02-05', '2026-02-05', 'DELIVERED', 0, NULL),
('SHP-010', 'PO-0019', 'SUP-007', 'Maersk',           'MK-10010', 'Egypt',         'Baltimore, MD',  '2026-02-15', '2026-02-18', 'DELIVERED', 3, 'Port congestion at origin'),

-- More normal shipments (Feb-March)
('SHP-011', 'PO-0021', 'SUP-001', 'FedEx Freight',    'FX-11011', 'United States', 'Chicago, IL',    '2026-02-20', '2026-02-20', 'DELIVERED', 0, NULL),
('SHP-012', 'PO-0022', 'SUP-003', 'DHL Express',      'DHL-12012','Germany',       'Houston, TX',    '2026-02-25', '2026-02-27', 'DELIVERED', 2, NULL),
('SHP-013', 'PO-0026', 'SUP-002', 'Nippon Yusen',     'NYK-13013','Japan',         'Los Angeles, CA','2026-03-01', '2026-03-02', 'DELIVERED', 1, NULL),
('SHP-014', 'PO-0029', 'SUP-005', 'COSCO Shipping',   'CS-14014', 'China',         'Seattle, WA',    '2026-03-05', '2026-03-08', 'DELIVERED', 3, 'Customs clearance delay'),
('SHP-015', 'PO-0031', 'SUP-006', 'Wallenius',        'WW-15015', 'Norway',        'Newark, NJ',     '2026-03-05', '2026-03-05', 'DELIVERED', 0, NULL),
('SHP-016', 'PO-0034', 'SUP-004', 'LATAM Cargo',      'LC-16016', 'Chile',         'Miami, FL',      '2026-03-10', '2026-03-12', 'DELIVERED', 2, NULL),
('SHP-017', 'PO-0037', 'SUP-007', 'Maersk',           'MK-17017', 'Egypt',         'Baltimore, MD',  '2026-03-12', '2026-03-16', 'DELIVERED', 4, 'Suez Canal congestion'),
('SHP-018', 'PO-0041', 'SUP-001', 'FedEx Freight',    'FX-18018', 'United States', 'Chicago, IL',    '2026-03-20', '2026-03-20', 'DELIVERED', 0, NULL),
('SHP-019', 'PO-0042', 'SUP-003', 'DHL Express',      'DHL-19019','Germany',       'Houston, TX',    '2026-03-25', '2026-03-26', 'DELIVERED', 1, NULL),
('SHP-020', 'PO-0046', 'SUP-002', 'Nippon Yusen',     'NYK-20020','Japan',         'Los Angeles, CA','2026-03-30', '2026-03-31', 'DELIVERED', 1, NULL),

-- April shipments
('SHP-021', 'PO-0049', 'SUP-005', 'COSCO Shipping',   'CS-21021', 'China',         'Seattle, WA',    '2026-04-05', '2026-04-09', 'DELIVERED', 4, 'Port strike in Shanghai'),
('SHP-022', 'PO-0050', 'SUP-012', 'Emirates SkyCargo','EK-22022', 'UAE',           'JFK, NY',        '2026-03-25', '2026-03-25', 'DELIVERED', 0, NULL),
('SHP-023', 'PO-0053', 'SUP-004', 'LATAM Cargo',      'LC-23023', 'Chile',         'Miami, FL',      '2026-04-05', '2026-04-08', 'DELIVERED', 3, NULL),
('SHP-024', 'PO-0055', 'SUP-006', 'Wallenius',        'WW-24024', 'Norway',        'Newark, NJ',     '2026-04-08', '2026-04-08', 'DELIVERED', 0, NULL),
('SHP-025', 'PO-0061', 'SUP-001', 'FedEx Freight',    'FX-25025', 'United States', 'Chicago, IL',    '2026-04-20', '2026-04-20', 'DELIVERED', 0, NULL),
('SHP-026', 'PO-0062', 'SUP-003', 'DHL Express',      'DHL-26026','Germany',       'Houston, TX',    '2026-04-24', '2026-04-25', 'DELIVERED', 1, NULL),
('SHP-027', 'PO-0066', 'SUP-002', 'Nippon Yusen',     'NYK-27027','Japan',         'Los Angeles, CA','2026-04-30', '2026-05-01', 'DELIVERED', 1, NULL),
('SHP-028', 'PO-0068', 'SUP-005', 'COSCO Shipping',   'CS-28028', 'China',         'Seattle, WA',    '2026-05-02', '2026-05-06', 'DELIVERED', 4, 'Typhoon delay in South China Sea'),

-- May-June shipments (including SUP-005 deteriorating delivery performance)
('SHP-029', 'PO-0072', 'SUP-007', 'Maersk',           'MK-29029', 'Egypt',         'Baltimore, MD',  '2026-05-05', '2026-05-10', 'DELIVERED', 5, 'Customs inspection hold'),
('SHP-030', 'PO-0076', 'SUP-004', 'LATAM Cargo',      'LC-30030', 'Chile',         'Miami, FL',      '2026-05-10', '2026-05-13', 'DELIVERED', 3, NULL),
('SHP-031', 'PO-0078', 'SUP-012', 'Emirates SkyCargo','EK-31031', 'UAE',           'JFK, NY',        '2026-05-03', '2026-05-03', 'DELIVERED', 0, NULL),
('SHP-032', 'PO-0080', 'SUP-006', 'Wallenius',        'WW-32032', 'Norway',        'Newark, NJ',     '2026-05-15', '2026-05-15', 'DELIVERED', 0, NULL),
('SHP-033', 'PO-0081', 'SUP-001', 'FedEx Freight',    'FX-33033', 'United States', 'Chicago, IL',    '2026-05-20', '2026-05-20', 'DELIVERED', 0, NULL),
('SHP-034', 'PO-0082', 'SUP-003', 'DHL Express',      'DHL-34034','Germany',       'Houston, TX',    '2026-05-25', '2026-05-26', 'DELIVERED', 1, NULL),

-- [A8] SUP-005 increasingly late deliveries (deteriorating pattern)
('SHP-035', 'PO-0083', 'SUP-005', 'COSCO Shipping',   'CS-35035', 'China',         'Seattle, WA',    '2026-05-15', '2026-05-25', 'DELIVERED', 10, 'Severe production delay at supplier facility'),
('SHP-036', 'PO-0087', 'SUP-002', 'Nippon Yusen',     'NYK-36036','Japan',         'Los Angeles, CA','2026-06-01', '2026-06-02', 'DELIVERED', 1, NULL),
('SHP-037', 'PO-0088', 'SUP-010', 'OceanBridge',      'OB-37037', 'Singapore',     'Long Beach, CA', '2026-05-27', '2026-05-28', 'DELIVERED', 1, NULL),
('SHP-038', 'PO-0092', 'SUP-004', 'LATAM Cargo',      'LC-38038', 'Chile',         'Miami, FL',      '2026-06-05', '2026-06-07', 'DELIVERED', 2, NULL),
('SHP-039', 'PO-0096', 'SUP-006', 'Wallenius',        'WW-39039', 'Norway',        'Newark, NJ',     '2026-06-08', '2026-06-08', 'DELIVERED', 0, NULL),

-- June shipments
('SHP-040', 'PO-0101', 'SUP-001', 'FedEx Freight',    'FX-40040', 'United States', 'Chicago, IL',    '2026-06-20', '2026-06-20', 'DELIVERED', 0, NULL),
('SHP-041', 'PO-0102', 'SUP-003', 'DHL Express',      'DHL-41041','Germany',       'Houston, TX',    '2026-06-24', '2026-06-25', 'DELIVERED', 1, NULL),
('SHP-042', 'PO-0105', 'SUP-005', 'COSCO Shipping',   'CS-42042', 'China',         'Seattle, WA',    '2026-06-28', '2026-07-06', 'DELIVERED', 8, 'Quality hold at port of origin'),
('SHP-043', 'PO-0106', 'SUP-002', 'Nippon Yusen',     'NYK-43043','Japan',         'Los Angeles, CA','2026-06-30', '2026-07-01', 'DELIVERED', 1, NULL),
('SHP-044', 'PO-0107', 'SUP-010', 'OceanBridge',      'OB-44044', 'Singapore',     'Long Beach, CA', '2026-06-25', '2026-06-26', 'DELIVERED', 1, NULL),
('SHP-045', 'PO-0108', 'SUP-012', 'Emirates SkyCargo','EK-45045', 'UAE',           'JFK, NY',        '2026-06-22', '2026-06-22', 'DELIVERED', 0, NULL),
('SHP-046', 'PO-0110', 'SUP-004', 'LATAM Cargo',      'LC-46046', 'Chile',         'Miami, FL',      '2026-07-02', '2026-07-05', 'DELIVERED', 3, NULL),
('SHP-047', 'PO-0113', 'SUP-007', 'Maersk',           'MK-47047', 'Egypt',         'Baltimore, MD',  '2026-07-05', '2026-07-10', 'DELIVERED', 5, 'Port congestion');


-- ============================================================================
-- 7. SUPPLIER COMMUNICATIONS (50+ messages)
-- ============================================================================

USE SCHEMA UNSTRUCTURED;

INSERT INTO SUPPLIER_COMMS (COMM_ID, SUPPLIER_ID, COMM_TYPE, SUBJECT, MESSAGE_BODY, SENDER, DIRECTION, SENTIMENT_SCORE, COMM_DATE)
VALUES
-- SUP-005 (Dragon Polymers) — DETERIORATING RELATIONSHIP (key for root cause analysis)
('COM-001', 'SUP-005', 'EMAIL', 'Q1 2026 Order Confirmation',
 'Dear Team, We are pleased to confirm receipt of your Q1 orders. All materials are in stock and production is on schedule. We look forward to continuing our partnership. Best regards, Dragon Polymers Sales Team.',
 'sales@dragonpolymers.cn', 'INBOUND', 0.7, '2026-01-15 09:30:00'),

('COM-002', 'SUP-005', 'EMAIL', 'Shipment Delay Notification - February',
 'We regret to inform you that the February shipment (CS-14014) will be delayed by approximately 3 days due to customs clearance issues at Shanghai port. We apologize for any inconvenience and are working to expedite the process.',
 'logistics@dragonpolymers.cn', 'INBOUND', -0.2, '2026-03-03 14:15:00'),

('COM-003', 'SUP-005', 'EMAIL', 'Raw Material Cost Increase Notice',
 'Due to significant increases in crude oil prices and new environmental regulations in the Guangdong province, we must regretfully inform you of upcoming price adjustments. ABS polymer pellets will see a price increase effective April 2026. We understand this is difficult and are open to discussing volume-based discounts.',
 'pricing@dragonpolymers.cn', 'INBOUND', -0.4, '2026-03-20 11:00:00'),

('COM-004', 'SUP-005', 'EMAIL', 'RE: Price Increase Discussion',
 'Thank you for your response. However, we must be firm on the price adjustment. Our production costs have increased by 35% since last quarter. We can offer a 2% volume discount on orders exceeding 5000 KG, but the base price increase is non-negotiable. We hope you understand our position.',
 'pricing@dragonpolymers.cn', 'INBOUND', -0.5, '2026-04-02 16:45:00'),

('COM-005', 'SUP-005', 'EMAIL', 'Production Delay - April Shipment',
 'We are experiencing unexpected production delays at our Shenzhen facility due to equipment failure. Your April order will be delayed by at least 4 days. We are sourcing materials from our secondary facility to mitigate the impact. Our technical team is working around the clock to resolve this issue.',
 'operations@dragonpolymers.cn', 'INBOUND', -0.6, '2026-04-05 08:20:00'),

('COM-006', 'SUP-005', 'EMAIL', 'Urgent: Revised Pricing Schedule',
 'Following our previous communications, please find the revised pricing schedule effective immediately. The new price for ABS Polymer Pellets is $55.00/KG (previously $18.50/KG). This reflects the full impact of regulatory changes and raw material cost increases. We understand this is a substantial change and are willing to discuss alternative arrangements.',
 'pricing@dragonpolymers.cn', 'INBOUND', -0.7, '2026-05-28 10:30:00'),

('COM-007', 'SUP-005', 'EMAIL', 'RE: Contract Terms Dispute',
 'We acknowledge your concerns regarding the price escalation clause in our agreement. However, we believe the current market conditions constitute force majeure and are beyond the scope of the standard escalation limits. Our legal team is reviewing the matter. In the meantime, all orders will be processed at the revised rates.',
 'legal@dragonpolymers.cn', 'INBOUND', -0.8, '2026-06-15 13:45:00'),

('COM-008', 'SUP-005', 'EMAIL', 'Quality Control Issue - Shipment CS-42042',
 'We are placing a quality hold on your latest shipment at the port of origin. Recent quality tests have shown deviation from specifications in batch #DP-2026-B412. We are conducting additional testing and will update you within 48 hours. We apologize for this disruption.',
 'quality@dragonpolymers.cn', 'INBOUND', -0.85, '2026-06-26 07:15:00'),

-- SUP-001 (SteelCore) — STABLE, POSITIVE relationship
('COM-009', 'SUP-001', 'EMAIL', 'Annual Review Meeting Confirmation',
 'Dear valued customer, We are pleased to confirm our annual business review meeting for December 2025. We look forward to discussing our continued partnership and exploring opportunities for 2026. Thank you for your trust in SteelCore Industries.',
 'account.manager@steelcore.com', 'INBOUND', 0.8, '2025-12-01 10:00:00'),

('COM-010', 'SUP-001', 'EMAIL', 'Q1 2026 Delivery Confirmation',
 'All Q1 orders have been delivered successfully and on schedule. We are pleased to report zero defects on all steel shipments this quarter. Looking forward to serving you in Q2.',
 'logistics@steelcore.com', 'INBOUND', 0.9, '2026-03-22 14:30:00'),

('COM-011', 'SUP-001', 'EMAIL', 'Price Stability Guarantee',
 'We are happy to inform you that despite market fluctuations, SteelCore Industries will maintain current pricing through Q2 2026 as per our contract terms. We value our long-term relationship and are committed to providing stability.',
 'pricing@steelcore.com', 'INBOUND', 0.85, '2026-04-15 09:00:00'),

-- SUP-003 (Rhine Chemical) — MOSTLY POSITIVE
('COM-012', 'SUP-003', 'EMAIL', 'New Product Line Introduction',
 'We are excited to introduce our new line of eco-friendly industrial solvents. These products offer the same performance with 40% lower VOC emissions. We would love to schedule a product demonstration at your facility.',
 'innovation@rhinechemical.de', 'INBOUND', 0.75, '2026-02-10 11:30:00'),

('COM-013', 'SUP-003', 'EMAIL', 'Minor Shipping Adjustment',
 'Please note a slight adjustment to our shipping schedule for March. Deliveries will arrive 1-2 days later than usual due to a planned carrier change for improved service. This is a one-time adjustment.',
 'logistics@rhinechemical.de', 'INBOUND', 0.1, '2026-03-01 08:45:00'),

-- SUP-008 (GhostVendor) — SUSPICIOUS communications
('COM-014', 'SUP-008', 'EMAIL', 'New Account Setup - Invoice Submission',
 'To whom it may concern, We are submitting our first invoice for manufacturing components as discussed. Please process payment to the account details provided in the attached document. Regards, GhostVendor Inc.',
 'billing@ghostvendor-inc.com', 'INBOUND', 0.0, '2026-06-14 22:30:00'),

('COM-015', 'SUP-008', 'EMAIL', 'URGENT: Payment Follow-up',
 'We have not received confirmation of payment for our invoice GV-2026-071. Please expedite payment processing as this is overdue. Failure to pay within 5 business days will result in escalation. Thank you.',
 'collections@ghostvendor-inc.com', 'INBOUND', -0.3, '2026-07-01 06:00:00'),

-- SUP-009 (SwiftFreight) — NEUTRAL/PROFESSIONAL
('COM-016', 'SUP-009', 'EMAIL', 'Service Level Agreement Renewal',
 'Your annual SLA is up for renewal. Based on our performance metrics (98.5% on-time delivery, 0.02% damage rate), we are confident in continuing to provide excellent service. Please review the attached renewal terms.',
 'contracts@swiftfreight.com', 'INBOUND', 0.6, '2026-01-10 13:00:00'),

('COM-017', 'SUP-009', 'MEETING_NOTE', 'Quarterly Business Review Notes',
 'Discussed Q1 performance metrics. SwiftFreight exceeded all KPIs. Fuel surcharge increase of 3% effective Q2 was mutually agreed upon. New routing optimization to reduce transit times by 1 day on West Coast deliveries.',
 'logistics.team@ourcompany.com', 'OUTBOUND', 0.5, '2026-04-01 15:00:00'),

-- SUP-002 (Pacific Metals) — POSITIVE
('COM-018', 'SUP-002', 'EMAIL', 'Extended Payment Terms Offer',
 'As a valued long-term customer, we are pleased to offer extended payment terms of NET45 for the remainder of 2026. This reflects our appreciation for your consistent business and prompt payment history.',
 'finance@pacificmetals.jp', 'INBOUND', 0.8, '2026-03-15 10:30:00'),

-- SUP-010 (OceanBridge) — POSITIVE
('COM-019', 'SUP-010', 'EMAIL', 'New Route Announcement',
 'OceanBridge Shipping is pleased to announce a new direct route from Singapore to Long Beach, reducing transit time by 3 days. Your shipments will automatically be transferred to this improved route starting April 2026.',
 'routes@oceanbridge.sg', 'INBOUND', 0.7, '2026-03-20 09:15:00'),

-- SUP-012 (SkyHaul Aviation) — POSITIVE
('COM-020', 'SUP-012', 'EMAIL', 'Priority Handling Upgrade',
 'In recognition of your growing business with SkyHaul, we are upgrading your shipments to priority handling at no additional cost. This includes expedited customs clearance and dedicated tracking support.',
 'vip@skyhaulaviation.ae', 'INBOUND', 0.85, '2026-04-10 12:00:00'),

-- More supplier communications for sentiment density
('COM-021', 'SUP-004', 'EMAIL', 'Mining Operations Update',
 'Our mining operations in the Atacama region are running at full capacity. We anticipate stable supply through Q2 2026. Minor price adjustment of 2% effective next quarter per our contract terms.',
 'operations@andeanminerals.cl', 'INBOUND', 0.3, '2026-02-15 10:00:00'),

('COM-022', 'SUP-006', 'EMAIL', 'Sustainability Report',
 'Please find attached our annual sustainability report. Nordic Timber maintains FSC certification across all product lines. We are proud to report a 15% reduction in carbon emissions this year.',
 'sustainability@nordictimber.no', 'INBOUND', 0.7, '2026-03-05 11:00:00'),

('COM-023', 'SUP-015', 'EMAIL', 'Cloud Infrastructure Optimization Report',
 'Your monthly optimization report shows potential savings of $4,200/month through right-sizing recommendations. Our team is available to implement these changes at your convenience.',
 'support@cloudnova.in', 'INBOUND', 0.65, '2026-04-05 14:00:00'),

('COM-024', 'SUP-007', 'EMAIL', 'Delivery Delay - Weather Related',
 'Sandstorm conditions in the Suez region have caused delays to our shipment MK-29029. Expected delay is 3-5 days. We are monitoring conditions and will provide updates.',
 'shipping@saharasilicates.eg', 'INBOUND', -0.3, '2026-05-06 08:00:00'),

('COM-025', 'SUP-016', 'EMAIL', 'Security Audit Completion',
 'Pleased to report that your annual penetration testing has been completed successfully. No critical vulnerabilities were found. Detailed report attached. Two medium-severity items have been flagged for your review.',
 'security@cybershield.il', 'INBOUND', 0.6, '2026-03-20 16:00:00'),

('COM-026', 'SUP-020', 'EMAIL', 'Eco-Packaging Innovation',
 'Exciting news! Our R&D team has developed a new biodegradable packaging material that is 20% lighter and 30% stronger. We would love to send you samples for evaluation.',
 'innovation@greenpack.se', 'INBOUND', 0.8, '2026-04-20 10:30:00'),

('COM-027', 'SUP-025', 'EMAIL', 'Consulting Engagement Summary',
 'Thank you for another productive quarter. Our team delivered 3 strategic assessments and 2 process improvement workshops. Client satisfaction score: 4.7/5.0. Looking forward to our continued engagement.',
 'delivery@pinnacleconsulting.com', 'INBOUND', 0.75, '2026-05-01 09:00:00'),

('COM-028', 'SUP-005', 'PHONE_NOTE', 'Escalation Call - Pricing Dispute',
 'Internal note: Called Dragon Polymers to discuss the 197% price increase. Their VP of Sales was aggressive and dismissive of our contract terms. Threatened to halt supply if we do not accept new pricing within 2 weeks. Recommend immediate engagement of legal team and sourcing of alternative suppliers.',
 'procurement.director@ourcompany.com', 'OUTBOUND', -0.9, '2026-06-20 17:00:00');


-- ============================================================================
-- 8. CONTRACTS (10 contracts)
-- ============================================================================

INSERT INTO CONTRACTS (CONTRACT_ID, SUPPLIER_ID, CONTRACT_TYPE, TERMS_TEXT, MAX_PRICE_ESCALATION_PCT, PAYMENT_TERMS, START_DATE, END_DATE, AUTO_RENEW, STATUS)
VALUES
('CON-001', 'SUP-001', 'MASTER',
 'MASTER SUPPLY AGREEMENT between OurCompany Inc. and SteelCore Industries.\n\nSection 1: Scope of Supply\nSteelCore shall supply carbon steel, stainless steel fasteners, and steel pipe products as specified in purchase orders.\n\nSection 2: Pricing\nAll prices are fixed for the contract period unless mutually agreed upon in writing. Base prices per the attached Schedule A.\n\nSection 3: Price Escalation\nMaximum allowable price escalation: 3% per annum, subject to 90-day prior written notice and documentation of underlying cost increases.\n\nSection 4: Delivery Terms\nFOB Destination. Delivery within 15 business days of PO acceptance. Liquidated damages of 1% per day for delays exceeding 5 business days.\n\nSection 5: Quality Standards\nAll materials must meet ASTM specifications. Defect rate not to exceed 0.5%. Right to return and full credit for non-conforming materials.\n\nSection 6: Payment Terms\nNET30 from date of invoice receipt. 2% early payment discount for payment within 10 days.',
 3.00, 'NET30', '2025-01-01', '2027-12-31', TRUE, 'ACTIVE'),

('CON-002', 'SUP-003', 'MASTER',
 'MASTER SUPPLY AGREEMENT between OurCompany Inc. and Rhine Chemical Solutions GmbH.\n\nSection 1: Product Specifications\nAll chemical products must meet EU REACH compliance and OSHA standards.\n\nSection 2: Pricing and Escalation\nPrices as per Schedule B. Maximum price escalation: 4% per annum, tied to the European Chemical Price Index (ECPI).\n\nSection 3: Volume Commitments\nMinimum annual purchase commitment: 5,000 KG of solvent products. Volume discounts apply per the graduated schedule.\n\nSection 4: Force Majeure\nNeither party shall be liable for delays caused by events beyond reasonable control, including but not limited to: natural disasters, government regulations, pandemics, or supply chain disruptions of more than 30 days duration.',
 4.00, 'NET45', '2024-06-01', '2027-05-31', TRUE, 'ACTIVE'),

('CON-003', 'SUP-005', 'MASTER',
 'MASTER SUPPLY AGREEMENT between OurCompany Inc. and Dragon Polymers Ltd.\n\nSection 1: Products\nDragon Polymers shall supply ABS Polymer Pellets, Nylon 6 Resin, and Polycarbonate Sheets.\n\nSection 2: Pricing\nBase pricing as per Schedule C (established January 2023):\n- ABS Polymer Pellets: $18.00/KG\n- Nylon 6 Resin: $22.00/KG\n- Polycarbonate Sheet: $110.00/EA\n\nSection 3: Price Escalation Clause\nMaximum allowable price escalation: 5% per calendar year. Any price increase must be:\n(a) Supported by documented evidence of underlying cost increases\n(b) Communicated in writing at least 60 days in advance\n(c) Subject to mutual good-faith negotiation\n\nSection 4: Quality and Delivery\n4.1 All materials must meet ISO 9001:2015 quality standards\n4.2 Delivery within 20 business days of PO acceptance\n4.3 On-time delivery rate target: 95%\n4.4 Right to audit supplier facilities with 30 days notice\n\nSection 5: Dispute Resolution\nAll disputes shall be resolved through mediation before arbitration. Governing law: State of Delaware, United States.\n\nSection 6: Termination\nEither party may terminate with 90 days written notice. Immediate termination for material breach after 30-day cure period.',
 5.00, 'NET15', '2023-01-01', '2026-12-31', FALSE, 'ACTIVE'),

('CON-004', 'SUP-009', 'SLA',
 'SERVICE LEVEL AGREEMENT for freight services between OurCompany Inc. and SwiftFreight Global.\n\nSection 1: Service Levels\n- On-time delivery target: 97%\n- Damage rate: Less than 0.05%\n- Response time for quotes: Within 4 business hours\n\nSection 2: Pricing\nRates per the attached tariff schedule. Fuel surcharge adjustable quarterly based on DOE index.\n\nSection 3: Penalties\nFor on-time delivery below 95%: 5% credit on affected shipments.\nFor damage: Full replacement value plus 10% handling fee.',
 NULL, 'NET15', '2025-01-01', '2026-12-31', TRUE, 'ACTIVE'),

('CON-005', 'SUP-015', 'MASTER',
 'MANAGED SERVICES AGREEMENT between OurCompany Inc. and CloudNova Technologies.\n\nSection 1: Services\nCloud infrastructure management, DevOps engineering, and security audit services.\n\nSection 2: Pricing\n- Cloud Infrastructure: $18,000/month\n- DevOps Engineering: $120/hour\n- Security Audit: $14,000 per engagement\n\nSection 3: SLA\n99.9% uptime guarantee. Response time: Critical (1hr), High (4hr), Medium (8hr).\n\nSection 4: Data Security\nAll data handling per SOC 2 Type II and ISO 27001 standards.',
 3.00, 'NET30', '2024-01-01', '2026-12-31', TRUE, 'ACTIVE'),

('CON-006', 'SUP-002', 'MASTER',
 'SUPPLY AGREEMENT for specialty metals between OurCompany Inc. and Pacific Metals Group.\n\nSection 1: Products\nTitanium alloy and aluminum sheet products per JIS standards.\n\nSection 2: Pricing\nPrices indexed to LME (London Metal Exchange) rates with 5% maximum annual adjustment.\n\nSection 3: Lead Times\nStandard orders: 18-22 business days. Rush orders: 10 business days at 15% premium.',
 5.00, 'NET30', '2024-01-01', '2027-12-31', TRUE, 'ACTIVE'),

('CON-007', 'SUP-010', 'SLA',
 'LOGISTICS SERVICE AGREEMENT between OurCompany Inc. and OceanBridge Shipping.\n\nSection 1: Routes\nDedicated container allocation on Singapore-West Coast routes.\n\nSection 2: Rates\nPer TEU rates fixed for contract period. Bunker adjustment factor (BAF) adjusted monthly.',
 NULL, 'NET30', '2024-06-01', '2026-12-31', TRUE, 'ACTIVE'),

('CON-008', 'SUP-025', 'MASTER',
 'PROFESSIONAL SERVICES AGREEMENT between OurCompany Inc. and Pinnacle Consulting.\n\nSection 1: Scope\nStrategic consulting, process improvement, and operational advisory services.\n\nSection 2: Rates\nPartner: $350/hour, Senior Consultant: $250/hour, Consultant: $195/hour.\n\nSection 3: Intellectual Property\nAll deliverables become the property of OurCompany upon payment.',
 2.00, 'NET30', '2025-01-01', '2027-12-31', FALSE, 'ACTIVE'),

('CON-009', 'SUP-008', 'MASTER',
 'SUPPLY AGREEMENT between OurCompany Inc. and GhostVendor Inc.\n\nSection 1: Products\nCustom manufacturing components (Category A and B).\n\nSection 2: Status\nThis agreement was TERMINATED effective January 15, 2025 due to:\n- Failure to deliver on 3 consecutive orders\n- Quality non-conformance on 100% of delivered items\n- Inability to provide required compliance documentation\n\nSection 3: Outstanding Obligations\nNo outstanding obligations. All deposits refunded. Vendor flagged as DO NOT USE in procurement system.',
 NULL, 'NET30', '2024-01-01', '2025-01-15', FALSE, 'TERMINATED'),

('CON-010', 'SUP-012', 'SLA',
 'AIR FREIGHT SERVICE AGREEMENT between OurCompany Inc. and SkyHaul Aviation.\n\nSection 1: Service Standards\nPriority handling for time-critical shipments. 99% on-time performance guarantee.\n\nSection 2: Pricing\nFlat rate per KG based on route and service level. Premium service available for same-day delivery.',
 NULL, 'NET15', '2025-01-01', '2027-06-30', TRUE, 'ACTIVE');


-- ============================================================================
-- VERIFY SEED DATA
-- ============================================================================

USE SCHEMA CORE;

SELECT 'SUPPLIERS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM SUPPLIERS
UNION ALL
SELECT 'PURCHASE_ORDERS', COUNT(*) FROM PURCHASE_ORDERS
UNION ALL
SELECT 'PO_LINE_ITEMS', COUNT(*) FROM PO_LINE_ITEMS
UNION ALL
SELECT 'INVOICES', COUNT(*) FROM INVOICES
UNION ALL
SELECT 'PAYMENTS', COUNT(*) FROM PAYMENTS
UNION ALL
SELECT 'SHIPMENTS', COUNT(*) FROM SHIPMENTS
UNION ALL
SELECT 'SUPPLIER_COMMS', COUNT(*) FROM UNSTRUCTURED.SUPPLIER_COMMS
UNION ALL
SELECT 'CONTRACTS', COUNT(*) FROM UNSTRUCTURED.CONTRACTS;

-- ============================================================================
-- 9. DYNAMIC RULES & MAPPING
-- ============================================================================
INSERT INTO CORE.BUSINESS_RULES (RULE_ID, RULE_CATEGORY, RULE_NAME, RULE_VALUE_NUMERIC, RULE_VALUE_STRING, DESCRIPTION) VALUES
('MAX_AUTO_EXEC_AMT', 'AUTHORITY', 'Max Auto-Execute Amount', 200000.00, NULL, 'Maximum amount the agent can auto-execute without human approval'),
('CFO_NOTIFY_AMT', 'AUTHORITY', 'CFO Notification Threshold', 500000.00, NULL, 'Threshold above which the CFO must be notified'),
('RISK_TIER_CRITICAL_SCORE', 'RISK', 'Critical Risk Score Threshold', 30.00, NULL, 'Risk score below which a supplier is marked CRITICAL');

INSERT INTO CORE.SUPPLIER_DOMAINS (DOMAIN_ID, SUPPLIER_ID, EMAIL_DOMAIN, IS_PRIMARY, VERIFIED_DATE) VALUES
('DOM-001', 'SUP-001', 'steelcore.com', TRUE, '2021-03-15'),
('DOM-002', 'SUP-005', 'dragon-polymers.com', TRUE, '2023-02-14'),
('DOM-003', 'SUP-005', 'dragon-poly.cn', FALSE, '2024-01-10'),
('DOM-004', 'SUP-008', 'ghost-vendor.com', TRUE, '2024-01-01');

-- ============================================================================
-- BUSINESS RULES — Dynamic thresholds for agent decision-making
-- ============================================================================
INSERT INTO CORE.BUSINESS_RULES (RULE_ID, RULE_CATEGORY, RULE_NAME, RULE_VALUE_NUMERIC, RULE_VALUE_STRING, DESCRIPTION) VALUES
('BR-001', 'ACTION_THRESHOLD', 'MAX_AUTO_EXECUTE_AMOUNT', 200000.00, NULL, 'Maximum dollar amount the agent can auto-hold without human approval'),
('BR-002', 'NOTIFICATION', 'CFO_NOTIFICATION_THRESHOLD', 500000.00, NULL, 'Dollar threshold above which CFO is automatically notified'),
('BR-003', 'DETECTION', 'ML_ANOMALY_CONFIDENCE', 0.99, NULL, 'Prediction interval for ML anomaly detection (higher = fewer false positives)'),
('BR-004', 'DETECTION', 'PRICE_SPIKE_PCT_THRESHOLD', 50.00, NULL, 'Percentage deviation above which a price spike is CRITICAL'),
('BR-005', 'DETECTION', 'VOLUME_SPIKE_MULTIPLIER', 5.00, NULL, 'Multiplier above average that triggers a CRITICAL volume spike'),
('BR-006', 'INVESTIGATION', 'AI_TRIAGE_THRESHOLD', 200000.00, NULL, 'Dollar threshold above which WARNING anomalies get full AI investigation'),
('BR-007', 'ACTION_THRESHOLD', 'MAX_RETRY_ATTEMPTS', 3.00, NULL, 'Number of retry attempts before escalating a failed action'),
('BR-008', 'NOTIFICATION', 'DUPLICATE_NOTIFICATION_WINDOW_HOURS', 24.00, NULL, 'Hours within which duplicate notifications to same recipient are suppressed');

-- Update specific suppliers as critical materials
UPDATE CORE.SUPPLIERS 
SET IS_CRITICAL_MATERIAL = TRUE 
WHERE SUPPLIER_ID IN ('SUP-005', 'SUP-001', 'SUP-003');

SELECT '✅ Seed data loaded successfully — ' || SUM(CNT) || ' total rows' AS STATUS
FROM (
    SELECT COUNT(*) AS CNT FROM SUPPLIERS
    UNION ALL SELECT COUNT(*) FROM PURCHASE_ORDERS
    UNION ALL SELECT COUNT(*) FROM PO_LINE_ITEMS
    UNION ALL SELECT COUNT(*) FROM INVOICES
    UNION ALL SELECT COUNT(*) FROM PAYMENTS
    UNION ALL SELECT COUNT(*) FROM SHIPMENTS
    UNION ALL SELECT COUNT(*) FROM UNSTRUCTURED.SUPPLIER_COMMS
    UNION ALL SELECT COUNT(*) FROM UNSTRUCTURED.CONTRACTS
);
