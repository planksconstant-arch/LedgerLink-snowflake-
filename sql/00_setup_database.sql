-- ============================================================================
-- SupplyChain FinOps Agent — Database Setup
-- ============================================================================
-- This script creates the foundational Snowflake infrastructure:
--   • Database & Schemas
--   • Virtual Warehouse
--   • Role-Based Access Control (RBAC)
-- 
-- Run this FIRST before any other SQL scripts.
-- ============================================================================

-- ============================================================================
-- 1. CREATE DATABASE & SCHEMAS
-- ============================================================================

CREATE DATABASE IF NOT EXISTS SUPPLY_CHAIN_FINOPS
    COMMENT = 'SupplyChain FinOps Agent — AI-driven supply chain financial risk intelligence';

USE DATABASE SUPPLY_CHAIN_FINOPS;

-- Core schema for transactional/operational data
CREATE SCHEMA IF NOT EXISTS CORE
    COMMENT = 'Core transactional data: POs, invoices, payments, shipments';

-- Analytics schema for ML models, anomaly results, and investigation outputs
CREATE SCHEMA IF NOT EXISTS ANALYTICS
    COMMENT = 'ML models, anomaly detection results, investigation logs';

-- Unstructured data schema for contracts, communications, documents
CREATE SCHEMA IF NOT EXISTS UNSTRUCTURED
    COMMENT = 'Supplier contracts, communications, and document text data';

-- Audit schema for compliance and action tracking
CREATE SCHEMA IF NOT EXISTS AUDIT
    COMMENT = 'Audit trail, action logs, and compliance records';

-- ============================================================================
-- 2. CREATE VIRTUAL WAREHOUSE
-- ============================================================================

CREATE WAREHOUSE IF NOT EXISTS FINOPS_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 120            -- Suspend after 2 minutes of inactivity
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for SupplyChain FinOps Agent workloads';

USE WAREHOUSE FINOPS_WH;

-- ============================================================================
-- 3. ENABLE CORTEX FEATURES (Account-level — requires ACCOUNTADMIN)
-- ============================================================================
-- Uncomment the line below if Cortex is not already enabled in your account.
-- You only need to run this ONCE per account.

-- USE ROLE ACCOUNTADMIN;
-- ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- ============================================================================
-- 4. GRANT CORTEX ACCESS
-- ============================================================================
-- Ensure the role being used has access to Cortex ML/AI functions.
-- The SNOWFLAKE.CORTEX_USER database role is granted to PUBLIC by default,
-- but verify this if you encounter permission errors.

-- GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE <YOUR_ROLE>;

-- ============================================================================
-- 5. SET SESSION DEFAULTS
-- ============================================================================

USE DATABASE SUPPLY_CHAIN_FINOPS;
USE SCHEMA CORE;
USE WAREHOUSE FINOPS_WH;

-- ============================================================================
-- Setup complete. Proceed to 01_create_tables.sql
-- ============================================================================

-- ============================================================================
-- 4. CREATE ROLES & ASSIGN PRIVILEGES
-- ============================================================================

-- Create a dedicated, restricted role for the FinOps Agent
CREATE ROLE IF NOT EXISTS FINOPS_AGENT_ROLE;

-- Grant usage on database and schemas
GRANT USAGE ON DATABASE SUPPLY_CHAIN_FINOPS TO ROLE FINOPS_AGENT_ROLE;
GRANT USAGE ON SCHEMA SUPPLY_CHAIN_FINOPS.CORE TO ROLE FINOPS_AGENT_ROLE;
GRANT USAGE ON SCHEMA SUPPLY_CHAIN_FINOPS.UNSTRUCTURED TO ROLE FINOPS_AGENT_ROLE;
GRANT USAGE ON SCHEMA SUPPLY_CHAIN_FINOPS.ANALYTICS TO ROLE FINOPS_AGENT_ROLE;
GRANT USAGE ON SCHEMA SUPPLY_CHAIN_FINOPS.AUDIT TO ROLE FINOPS_AGENT_ROLE;

-- Provide Cortex User Role for AI function access
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE FINOPS_AGENT_ROLE;

-- Strict DML Grants: Allow SELECT, INSERT, UPDATE. Explicitly deny DELETE and DROP.
-- (Note: In Snowflake, you don't grant DELETE, so we just grant what is needed)
GRANT SELECT, INSERT, UPDATE ON FUTURE TABLES IN SCHEMA SUPPLY_CHAIN_FINOPS.CORE TO ROLE FINOPS_AGENT_ROLE;
GRANT SELECT, INSERT, UPDATE ON FUTURE TABLES IN SCHEMA SUPPLY_CHAIN_FINOPS.ANALYTICS TO ROLE FINOPS_AGENT_ROLE;
GRANT SELECT, INSERT ON FUTURE TABLES IN SCHEMA SUPPLY_CHAIN_FINOPS.AUDIT TO ROLE FINOPS_AGENT_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA SUPPLY_CHAIN_FINOPS.UNSTRUCTURED TO ROLE FINOPS_AGENT_ROLE;

-- Grant execution on all current and future stored procedures
GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA SUPPLY_CHAIN_FINOPS.ANALYTICS TO ROLE FINOPS_AGENT_ROLE;
GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA SUPPLY_CHAIN_FINOPS.AUDIT TO ROLE FINOPS_AGENT_ROLE;

-- Grant access to warehouse
GRANT USAGE ON WAREHOUSE FINOPS_WH TO ROLE FINOPS_AGENT_ROLE;

SELECT '✅ Database, schemas, warehouse, and restricted FINOPS_AGENT_ROLE created successfully' AS STATUS;
