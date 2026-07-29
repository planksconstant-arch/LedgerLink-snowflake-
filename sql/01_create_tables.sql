-- ============================================================================
-- SupplyChain FinOps Agent — Table Definitions
-- ============================================================================
-- Creates all 12 tables across 4 schemas:
--   CORE:         SUPPLIERS, PURCHASE_ORDERS, PO_LINE_ITEMS, INVOICES,
--                 PAYMENTS, SHIPMENTS
--   UNSTRUCTURED: SUPPLIER_COMMS, CONTRACTS
--   ANALYTICS:    ANOMALY_RESULTS, INVESTIGATION_LOG
--   AUDIT:        AUDIT_TRAIL, NOTIFICATION_LOG
-- ============================================================================

USE DATABASE SUPPLY_CHAIN_FINOPS;
USE WAREHOUSE FINOPS_WH;

-- ============================================================================
-- SCHEMA: CORE — Transactional / Operational Data
-- ============================================================================

USE SCHEMA CORE;

-- 1. SUPPLIERS — Vendor master data
CREATE OR REPLACE TABLE SUPPLIERS (
    SUPPLIER_ID         VARCHAR(20)     PRIMARY KEY,
    SUPPLIER_NAME       VARCHAR(200)    NOT NULL,
    CATEGORY            VARCHAR(50)     NOT NULL,       -- Raw Materials, Logistics, IT, Packaging, Services
    COUNTRY             VARCHAR(50)     NOT NULL,
    RISK_TIER           VARCHAR(10)     DEFAULT 'LOW',  -- LOW, MEDIUM, HIGH, CRITICAL
    PAYMENT_TERMS       VARCHAR(30)     DEFAULT 'NET30',
    ANNUAL_SPEND_BUDGET NUMBER(15,2)    DEFAULT 0,
    CONTACT_EMAIL       VARCHAR(255),
    IS_ACTIVE           BOOLEAN         DEFAULT TRUE,
    IS_CRITICAL_MATERIAL BOOLEAN        DEFAULT FALSE, -- Prevents automated supply chain disruptions
    ONBOARDED_DATE      DATE            NOT NULL,
    LAST_AUDIT_DATE     DATE,
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Master supplier/vendor directory with risk classification';

-- 2. PURCHASE_ORDERS — PO header data
CREATE OR REPLACE TABLE PURCHASE_ORDERS (
    PO_ID               VARCHAR(20)     PRIMARY KEY,
    SUPPLIER_ID         VARCHAR(20)     NOT NULL REFERENCES SUPPLIERS(SUPPLIER_ID),
    REQUESTOR           VARCHAR(100)    NOT NULL,
    DEPARTMENT          VARCHAR(50)     NOT NULL,
    TOTAL_AMOUNT        NUMBER(15,2)    NOT NULL,
    CURRENCY            VARCHAR(3)      DEFAULT 'USD',
    STATUS              VARCHAR(20)     DEFAULT 'OPEN',  -- OPEN, APPROVED, RECEIVED, CLOSED, CANCELLED
    PRIORITY            VARCHAR(10)     DEFAULT 'NORMAL', -- LOW, NORMAL, HIGH, URGENT
    CREATED_DATE        DATE            NOT NULL,
    APPROVED_DATE       DATE,
    EXPECTED_DELIVERY   DATE,
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Purchase order headers linked to suppliers';

-- 3. PO_LINE_ITEMS — PO detail lines
CREATE OR REPLACE TABLE PO_LINE_ITEMS (
    LINE_ID             VARCHAR(25)     PRIMARY KEY,
    PO_ID               VARCHAR(20)     NOT NULL REFERENCES PURCHASE_ORDERS(PO_ID),
    PRODUCT_NAME        VARCHAR(200)    NOT NULL,
    PRODUCT_CATEGORY    VARCHAR(50),
    QUANTITY            NUMBER(10,2)    NOT NULL,
    UNIT_PRICE          NUMBER(12,4)    NOT NULL,
    LINE_TOTAL          NUMBER(15,2)    NOT NULL,        -- quantity * unit_price
    UNIT_OF_MEASURE     VARCHAR(20)     DEFAULT 'EA',    -- EA, KG, LB, BOX, PALLET
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Individual line items within purchase orders';

-- 4. INVOICES — Supplier invoices
CREATE OR REPLACE TABLE INVOICES (
    INVOICE_ID          VARCHAR(20)     PRIMARY KEY,
    PO_ID               VARCHAR(20)     REFERENCES PURCHASE_ORDERS(PO_ID),
    SUPPLIER_ID         VARCHAR(20)     NOT NULL REFERENCES SUPPLIERS(SUPPLIER_ID),
    INVOICE_NUMBER      VARCHAR(50)     NOT NULL,
    AMOUNT              NUMBER(15,2)    NOT NULL,
    TAX_AMOUNT          NUMBER(12,2)    DEFAULT 0,
    TOTAL_AMOUNT        NUMBER(15,2)    NOT NULL,
    CURRENCY            VARCHAR(3)      DEFAULT 'USD',
    STATUS              VARCHAR(20)     DEFAULT 'PENDING', -- PENDING, APPROVED, PAID, DISPUTED, CANCELLED
    SUBMITTED_DATE      DATE            NOT NULL,
    DUE_DATE            DATE            NOT NULL,
    APPROVED_BY         VARCHAR(100),
    NOTES               VARCHAR(500),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Supplier invoices matched against purchase orders';

-- 5. PAYMENTS — Payment transactions
CREATE OR REPLACE TABLE PAYMENTS (
    PAYMENT_ID          VARCHAR(20)     PRIMARY KEY,
    INVOICE_ID          VARCHAR(20)     NOT NULL REFERENCES INVOICES(INVOICE_ID),
    SUPPLIER_ID         VARCHAR(20)     NOT NULL REFERENCES SUPPLIERS(SUPPLIER_ID),
    AMOUNT              NUMBER(15,2)    NOT NULL,
    PAYMENT_METHOD      VARCHAR(30)     DEFAULT 'ACH',   -- ACH, WIRE, CHECK, CARD
    PAYMENT_DATE        DATE            NOT NULL,
    BANK_REFERENCE      VARCHAR(50),
    STATUS              VARCHAR(20)     DEFAULT 'COMPLETED', -- PENDING, COMPLETED, FAILED, REVERSED, ON_HOLD
    IS_FLAGGED          BOOLEAN         DEFAULT FALSE,
    FLAG_REASON         VARCHAR(200),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Payment transactions against approved invoices';

-- 6. SHIPMENTS — Logistics tracking
CREATE OR REPLACE TABLE SHIPMENTS (
    SHIPMENT_ID         VARCHAR(20)     PRIMARY KEY,
    PO_ID               VARCHAR(20)     NOT NULL REFERENCES PURCHASE_ORDERS(PO_ID),
    SUPPLIER_ID         VARCHAR(20)     NOT NULL REFERENCES SUPPLIERS(SUPPLIER_ID),
    CARRIER             VARCHAR(100),
    TRACKING_NUMBER     VARCHAR(50),
    ORIGIN_COUNTRY      VARCHAR(50),
    DESTINATION         VARCHAR(100),
    EXPECTED_DATE       DATE            NOT NULL,
    ACTUAL_DATE         DATE,
    STATUS              VARCHAR(20)     DEFAULT 'IN_TRANSIT', -- PENDING, IN_TRANSIT, DELIVERED, DELAYED, LOST
    DELAY_DAYS          NUMBER(5,0)     DEFAULT 0,
    DELAY_REASON        VARCHAR(200),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Shipment tracking for purchase orders';

-- ============================================================================
-- SCHEMA: UNSTRUCTURED — Text Data (Contracts, Communications)
-- ============================================================================

USE SCHEMA UNSTRUCTURED;

-- 7. SUPPLIER_COMMS — Supplier emails/messages
CREATE OR REPLACE TABLE SUPPLIER_COMMS (
    COMM_ID             VARCHAR(20)     PRIMARY KEY,
    SUPPLIER_ID         VARCHAR(20)     NOT NULL,
    COMM_TYPE           VARCHAR(20)     NOT NULL,        -- EMAIL, PHONE_NOTE, MEETING_NOTE, CHAT
    SUBJECT             VARCHAR(300),
    MESSAGE_BODY        VARCHAR(5000)   NOT NULL,        -- Full message text
    SENDER              VARCHAR(100),
    DIRECTION           VARCHAR(10)     DEFAULT 'INBOUND', -- INBOUND, OUTBOUND
    SENTIMENT_SCORE     FLOAT,                            -- Pre-computed or computed by Cortex
    COMM_DATE           TIMESTAMP_NTZ   NOT NULL,
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Supplier communications for sentiment analysis and context';

-- 8. CONTRACTS — Supplier contracts
CREATE OR REPLACE TABLE CONTRACTS (
    CONTRACT_ID         VARCHAR(20)     PRIMARY KEY,
    SUPPLIER_ID         VARCHAR(20)     NOT NULL,
    CONTRACT_TYPE       VARCHAR(30)     NOT NULL,        -- MASTER, AMENDMENT, NDA, SLA
    TERMS_TEXT          VARCHAR(10000)  NOT NULL,        -- Full contract text / key clauses
    MAX_PRICE_ESCALATION_PCT  NUMBER(5,2),               -- e.g., 5.00 = 5%
    PAYMENT_TERMS       VARCHAR(30),
    START_DATE          DATE            NOT NULL,
    END_DATE            DATE            NOT NULL,
    AUTO_RENEW          BOOLEAN         DEFAULT FALSE,
    STATUS              VARCHAR(20)     DEFAULT 'ACTIVE', -- ACTIVE, EXPIRED, TERMINATED
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Supplier contract documents with extractable terms and clauses';

-- ============================================================================
-- SCHEMA: ANALYTICS — ML Results & Investigation Outputs
-- ============================================================================

USE SCHEMA ANALYTICS;

-- 9. ANOMALY_RESULTS — Detected anomalies
CREATE OR REPLACE TABLE ANOMALY_RESULTS (
    ANOMALY_ID          VARCHAR(30)     PRIMARY KEY,
    SOURCE_TABLE        VARCHAR(50)     NOT NULL,        -- e.g., CORE.INVOICES, CORE.PAYMENTS
    RECORD_ID           VARCHAR(20)     NOT NULL,        -- ID of the flagged record
    ANOMALY_CATEGORY    VARCHAR(30)     NOT NULL,        -- PRICE_SPIKE, DUPLICATE_PAYMENT, PHANTOM_VENDOR, TIMING_ANOMALY, VOLUME_SPIKE
    ANOMALY_SCORE       FLOAT           NOT NULL,        -- 0.0 to 1.0 confidence
    SEVERITY            VARCHAR(10)     NOT NULL,        -- CRITICAL, WARNING, INFO
    EXPECTED_VALUE      NUMBER(15,2),
    ACTUAL_VALUE        NUMBER(15,2),
    DEVIATION_PCT       FLOAT,
    DESCRIPTION         VARCHAR(500),
    IS_INVESTIGATED     BOOLEAN         DEFAULT FALSE,
    DETECTED_AT         TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Anomalies detected by ML models with severity classification';

-- 10. INVESTIGATION_LOG — Root cause findings
CREATE OR REPLACE TABLE INVESTIGATION_LOG (
    INVESTIGATION_ID    VARCHAR(30)     PRIMARY KEY,
    ANOMALY_ID          VARCHAR(30)     NOT NULL REFERENCES ANOMALY_RESULTS(ANOMALY_ID),
    SUPPLIER_ID         VARCHAR(20),
    ROOT_CAUSE          VARCHAR(500)    NOT NULL,
    ROOT_CAUSE_CATEGORY VARCHAR(50),                    -- FRAUD, CONTRACT_VIOLATION, MARKET_CONDITION, OPERATIONAL_ERROR, DATA_QUALITY
    SUPPLIER_RISK_SCORE FLOAT,                           -- 0-100 composite risk score
    EVIDENCE_SUMMARY    VARCHAR(5000)   NOT NULL,        -- Detailed evidence chain
    SENTIMENT_TREND     VARCHAR(200),                    -- e.g., "-0.2 → -0.6 → -0.8 (deteriorating)"
    CONTRACT_VIOLATION  BOOLEAN         DEFAULT FALSE,
    RECOMMENDED_ACTION  VARCHAR(500),
    INVESTIGATED_AT     TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Root cause investigation results with evidence chains';

-- ============================================================================
-- SCHEMA: AUDIT — Compliance & Action Tracking
-- ============================================================================

USE SCHEMA AUDIT;

-- 11. AUDIT_TRAIL — All agent actions
CREATE OR REPLACE TABLE AUDIT_TRAIL (
    AUDIT_ID            VARCHAR(30)     PRIMARY KEY,
    ACTION_TYPE         VARCHAR(30)     NOT NULL,        -- DETECT, INVESTIGATE, HOLD_PAYMENT, ESCALATE, NOTIFY, ADJUST_FORECAST, SCHEDULE_FOLLOWUP
    ACTION_CATEGORY     VARCHAR(20)     NOT NULL,        -- AUTO_EXECUTED, RECOMMENDED, ESCALATED
    RELATED_ANOMALY_ID  VARCHAR(30),
    RELATED_RECORD_ID   VARCHAR(20),
    DETAILS             VARCHAR(5000)   NOT NULL,
    OUTCOME             VARCHAR(20)     DEFAULT 'SUCCESS', -- SUCCESS, FAILED, PENDING
    EXECUTED_BY         VARCHAR(50)     DEFAULT 'FINOPS_AGENT',
    REVIEWED_BY         VARCHAR(100),
    EXECUTION_DURATION_MS NUMBER(10,0),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Immutable audit trail of all agent decisions and actions';

-- 12. NOTIFICATION_LOG — Notifications drafted and sent
CREATE OR REPLACE TABLE NOTIFICATION_LOG (
    NOTIFICATION_ID     VARCHAR(50)     PRIMARY KEY,
    RECIPIENT_ROLE      VARCHAR(50)     NOT NULL,
    ANOMALY_IDS         VARCHAR(1000)   NOT NULL,
    DRAFTED_MESSAGE     VARCHAR(5000)   NOT NULL,
    URGENCY             VARCHAR(20)     NOT NULL,
    NOTIFIED_AT         TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    STATUS              VARCHAR(20)     DEFAULT 'DRAFTED'
)
COMMENT = 'Log of all batched stakeholder notifications drafted by the AI';

-- ============================================================================
-- 5. CONFIGURATION & MAPPING (For Dynamic Rules & Data Quality)
-- ============================================================================

CREATE OR REPLACE TABLE CORE.BUSINESS_RULES (
    RULE_ID VARCHAR(50) PRIMARY KEY,
    RULE_CATEGORY VARCHAR(50),
    RULE_NAME VARCHAR(100),
    RULE_VALUE_NUMERIC NUMBER(18,2),
    RULE_VALUE_STRING VARCHAR(255),
    DESCRIPTION VARCHAR(500),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
COMMENT ON TABLE CORE.BUSINESS_RULES IS 'Dynamic thresholds and configuration rules';

CREATE OR REPLACE TABLE CORE.SUPPLIER_DOMAINS (
    DOMAIN_ID VARCHAR(50) PRIMARY KEY,
    SUPPLIER_ID VARCHAR(50) REFERENCES CORE.SUPPLIERS(SUPPLIER_ID),
    EMAIL_DOMAIN VARCHAR(100) NOT NULL,
    IS_PRIMARY BOOLEAN DEFAULT FALSE,
    VERIFIED_DATE DATE
);
COMMENT ON TABLE CORE.SUPPLIER_DOMAINS IS 'Entity resolution mapping for supplier email domains';

-- ============================================================================
-- VERIFY SETUP
-- ============================================================================

SELECT '✅ All 14 base tables created successfully' AS STATUS;

-- Quick verification query
SELECT 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    COMMENT
FROM SUPPLY_CHAIN_FINOPS.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN ('CORE', 'UNSTRUCTURED', 'ANALYTICS', 'AUDIT')
ORDER BY TABLE_SCHEMA, TABLE_NAME;
