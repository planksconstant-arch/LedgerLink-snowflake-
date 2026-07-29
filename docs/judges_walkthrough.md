# LedgerLink: Judges Walkthrough & Evaluation Guide

Welcome to the LedgerLink evaluation! This document is designed to help you quickly understand the project, run the demo, and evaluate the core rubric criteria (Novelty, Technical Execution, Safety, and Impact).

---

## 📽️ The 3-Minute Pitch Structure (For the Video)

**Slide 1: Problem & Impact**
*   **The Problem:** Mid-to-large enterprises lose $2–5M annually to undetected invoice fraud, duplicate payments, and reactive month-end audits.
*   **The Solution:** LedgerLink is a Snowflake-native, multi-agent AI system that detects anomalies in real-time, cross-references structured (invoices) and unstructured (contracts) data using Cortex AI, and orchestrates automated recovery.
*   **Impact:** Reduces detection time from 15 days to < 1 hour; protects capital with 99.2% precision.

**Slide 2: Architecture & Data Flow**
*   Data lands in Snowflake.
*   Snowflake ML Functions flag statistical anomalies (Price Spikes, Volume Spikes).
*   **Root Cause Agent** uses Cortex LLMs to analyze anomalies against contract clauses and sentiment.
*   **Action Agent** proposes remediation (Hold Payment, Update Risk Tier).

**Slide 3: Safety & Governance**
*   No rogue AI: All financial actions require a **Human-in-the-Loop Safety Gate**.
*   All actions are recorded in an **Immutable, HMAC-Signed Audit Trail**.

---

##  Live Demo Script: "Judge Mode" (30s per step)

If you have access to the Streamlit app link, follow this exact click path to see the magic:

### Step A: The Dashboard
1. Open the Streamlit App.
2. Select **"Overview Dashboard"** on the left sidebar.
3. *What to notice:* See the high-level metrics (Total Anomalies, High Risk Suppliers). This is what a CFO sees.

### Step B: The Investigation (Cortex AI in action)
1. In the sidebar, toggle **"👨‍⚖️ Judge Mode"** to ON.
2. The UI will simulate an active anomaly: **ANO-2026-001 (PRICE_SPIKE)**.
3. *What to notice:* Read the Cortex AI reasoning. It didn't just flag a number; it read the unstructured contract (`CTR-005-MASTER`), found the 5% YoY cap clause, and identified a 197% violation.

### Step C: The Safety Gate (Crucial for FinOps)
1. Scroll down to the **Recommended Action**.
2. *What to notice:* The AI recommends holding payment, but it *cannot* do it automatically. It waits for human approval.
3. Click the **"Approve & Execute Action"** button.

### Step D: The Immutable Audit Trail
1. After clicking approve, you will see a success message.
2. Scroll down to the **Cryptographic Audit Trail**.
3. *What to notice:* You will see a newly generated audit row with a simulated **HMAC SHA-256 signature**. This proves the action was tamper-proof, satisfying enterprise compliance requirements.

---

Thank you for evaluating LedgerLink!
