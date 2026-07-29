#!/bin/bash
# ============================================================================
# LedgerLink — End-to-End Demo Script
# ============================================================================
# This script demonstrates the complete workflow using the CoCo CLI.
# 
# Prerequisites:
#   1. Snowflake CoCo CLI installed (cortex command available)
#   2. Snowflake connection configured
#   3. SQL setup scripts executed (00-05)
#
# Usage:
#   chmod +x demo/run_demo.sh
#   ./demo/run_demo.sh
# ============================================================================

set -e

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║     ❄️  LedgerLink — Live Demo                       ║"
echo "║     Powered by Snowflake CoCo CLI                                 ║"
echo "║                                                                    ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""

# ----------------------------------------------------------------------------
# STEP 1: Setup the database and load data
# ----------------------------------------------------------------------------
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 STEP 1: Setting up database and loading data..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Running SQL setup scripts..."
echo "  (In production, these would already be deployed)"
echo ""

# Run SQL setup scripts
# Uncomment these lines if you want to auto-run SQL setup
# cortex -p "Execute the SQL file sql/00_setup_database.sql against my Snowflake account"
# cortex -p "Execute the SQL file sql/01_create_tables.sql"
# cortex -p "Execute the SQL file sql/02_seed_data.sql"
# cortex -p "Execute the SQL file sql/03_create_ml_models.sql"
# cortex -p "Execute the SQL file sql/04_cortex_functions.sql"
# cortex -p "Execute the SQL file sql/05_audit_and_tasks.sql"

echo "  ✅ Database setup complete"
echo ""

# ----------------------------------------------------------------------------
# STEP 2: Run the full orchestrated workflow
# ----------------------------------------------------------------------------
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧠 STEP 2: Running full orchestrated workflow..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  This invokes the master orchestrator skill which chains:"
echo "    1. 🔍 Anomaly Detective (ML + rule-based detection)"
echo "    2. 📊 Root Cause Analyst (cross-data investigation)"
echo "    3. ⚡ Action Executor (recovery + audit trail)"
echo ""

# Option A: Full orchestration via CoCo CLI
cortex -w "$(dirname "$0")/.." -p '
$orchestrate-supply-chain

Run a complete financial risk assessment on the SUPPLY_CHAIN_FINOPS database.

Phase 1 - DETECTION: Scan all invoices and payments from the last 60 days for anomalies.
Use both ML-based detection (ANOMALY_DETECTION models) and rule-based checks
(duplicates, phantom vendors, timing issues, payment method changes).

Phase 2 - INVESTIGATION: For each CRITICAL and WARNING anomaly found, perform a
root cause investigation. Correlate with supplier communications (sentiment analysis),
contract terms, shipment performance, and price history. Calculate supplier risk scores.

Phase 3 - ACTION: Execute appropriate recovery actions based on business rules.
Hold suspicious payments, update supplier risk tiers, flag invoices for review,
and draft stakeholder notifications. Respect authority thresholds.

Phase 4 - REPORT: Generate a comprehensive executive summary with all findings,
actions taken, and items requiring human review.
'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Demo complete! Review the output above for the full assessment."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  📁 Audit trail: SELECT * FROM AUDIT.AUDIT_TRAIL ORDER BY CREATED_AT DESC;"
echo "  📊 Risk scores: SELECT * FROM ANALYTICS.V_SUPPLIER_RISK_SCORECARD;"
echo "  🔍 Anomalies:   SELECT * FROM ANALYTICS.ANOMALY_RESULTS;"
echo ""
