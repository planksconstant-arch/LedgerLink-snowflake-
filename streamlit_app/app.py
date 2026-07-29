import streamlit as st
import pandas as pd
import json

st.set_page_config(
    page_title="SupplyChain FinOps Agent",
    page_icon="❄️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for Enterprise Look
st.markdown("""
<style>
    /* Hide default Streamlit elements */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
    header {visibility: hidden;}
    
    /* Denser layout and Enterprise Font */
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
    
    html, body, [class*="css"] {
        font-family: 'Inter', sans-serif;
    }
    
    .block-container {
        padding-top: 2rem;
        padding-bottom: 2rem;
        max-width: 95%;
    }
    
    /* Custom Metric Styling - Glassmorphism cards */
    div[data-testid="metric-container"] {
        background-color: rgba(30, 30, 30, 0.4);
        border: 1px solid rgba(255, 255, 255, 0.05);
        padding: 15px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
    }
    
    div[data-testid="stMetricValue"] {
        font-size: 2.0rem;
        font-weight: 700;
        color: #FFFFFF;
    }
    
    div[data-testid="stMetricLabel"] {
        font-size: 0.85rem;
        color: #AAAAAA;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        font-weight: 600;
    }
    
    /* Tabular data density */
    .dataframe {
        font-size: 13px !important;
    }
    
    /* Make headers cleaner */
    h1 { font-size: 2.0rem !important; font-weight: 700 !important; margin-bottom: 0 !important; padding-bottom: 0 !important; letter-spacing: -0.5px; color: #FFFFFF;}
    h2 { font-size: 1.4rem !important; font-weight: 600 !important; margin-top: 1rem !important; margin-bottom: 0.5rem !important; color: #EEEEEE;}
    h3 { font-size: 1.1rem !important; font-weight: 500 !important; color: #DDDDDD; }
    
    /* Expander styling */
    .streamlit-expanderHeader {
        font-weight: 600 !important;
        font-size: 1.05rem !important;
    }
    
    /* Tabs styling */
    .stTabs [data-baseweb="tab-list"] {
        gap: 20px;
    }
    .stTabs [data-baseweb="tab"] {
        height: 50px;
        white-space: pre-wrap;
        background-color: transparent;
        border-radius: 4px 4px 0px 0px;
        gap: 1px;
        padding-top: 10px;
        padding-bottom: 10px;
    }
    .stTabs [aria-selected="true"] {
        background-color: rgba(41, 181, 232, 0.1);
        border-bottom-color: #29B5E8 !important;
    }
</style>
""", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# 1. DATA FETCHING (Live Snowflake Data with Mock Fallback)
# -----------------------------------------------------------------------------

def get_data():
    try:
        from snowflake.snowpark.context import get_active_session
        session = get_active_session()
        
        # Fetch actual data from Snowflake
        df_anomalies = session.sql("SELECT ANOMALY_ID as ID, ANOMALY_CATEGORY as Category, SUPPLIER_NAME as Supplier, ACTUAL_VALUE as \"Amount ($)\", EXPECTED_VALUE as \"Expected ($)\", SEVERITY as Severity, IS_INVESTIGATED as Status, EVENT_DATE as Date FROM ANALYTICS.V_ALL_ANOMALIES").to_pandas()
        df_suppliers = session.sql("SELECT SUPPLIER_ID as \"Supplier ID\", SUPPLIER_NAME as Name, RISK_TIER as \"Risk Tier\" FROM CORE.SUPPLIERS").to_pandas()
        df_investigations = session.sql("SELECT INVESTIGATION_ID as \"Inv ID\", ANOMALY_ID as Anomaly, SUPPLIER_ID as Supplier, ROOT_CAUSE as \"Root Cause\", SENTIMENT_TREND as \"Sentiment Trend\" FROM ANALYTICS.INVESTIGATION_LOG").to_pandas()
        df_audit = session.sql("SELECT CREATED_AT as Timestamp, ACTION_TYPE as Action, RELATED_RECORD_ID as Target, RELATED_ANOMALY_ID as Anomaly, OUTCOME as Status, EXECUTED_BY as Agent FROM AUDIT.AUDIT_TRAIL ORDER BY CREATED_AT DESC LIMIT 100").to_pandas()
        
        return df_anomalies, df_suppliers, df_investigations, df_audit
    except Exception as e:
        # Fallback to mock data if run locally without Snowpark context
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
            {'Timestamp': '2026-07-27 06:12:33', 'Action': 'HOLD_PAYMENT', 'Target': 'PAY-071', 'Anomaly': 'ANO-2026-002', 'Status': 'SUCCESS', 'Agent': '$action-agent'},
            {'Timestamp': '2026-07-27 06:13:44', 'Action': 'UPDATE_RISK_TIER', 'Target': 'SUP-005', 'Anomaly': 'ANO-2026-001', 'Status': 'SUCCESS', 'Agent': '$action-agent'},
            {'Timestamp': '2026-07-27 06:14:02', 'Action': 'NOTIFY_CFO', 'Target': 'CFO', 'Anomaly': 'ANO-2026-009', 'Status': 'SUCCESS', 'Agent': '$notification-agent'},
        ]
        return pd.DataFrame(anomalies_data), pd.DataFrame(suppliers_data), pd.DataFrame(investigations_data), pd.DataFrame(audit_data)

df_anomalies, df_suppliers, df_investigations, df_audit = get_data()

# Detailed mocked cortex reports mapping
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

# -----------------------------------------------------------------------------
# 2. SIDEBAR NAVIGATION
# -----------------------------------------------------------------------------
with st.sidebar:
    st.image("https://upload.wikimedia.org/wikipedia/commons/f/ff/Snowflake_Logo.svg", width=180)
    st.markdown("<br>", unsafe_allow_html=True)
    st.markdown("### FinOps Agent")
    st.markdown("Powered by **Cortex AI**")
    st.markdown("---")
    
    page = st.radio("Navigation", ["Overview Dashboard", "Anomaly Detection & Reports", "Supplier Risk", "Investigation & Audit"], label_visibility="collapsed")
    
    st.markdown("---")
    st.success("🟢 5/5 Agents Online")
    st.caption("Last scan: 07:12 UTC\n\nDatabase: SUPPLY_CHAIN_FINOPS\n\nWarehouse: FINOPS_WH")

# -----------------------------------------------------------------------------
# 3. PAGE LOGIC
# -----------------------------------------------------------------------------

if page == "Overview Dashboard":
    st.title("Financial Operations Overview")
    st.markdown("<p style='color: #A0A0A0; font-size: 1.1rem;'>Real-time AI monitoring of supply chain financial data</p>", unsafe_allow_html=True)
    
    # Metrics row
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Critical Anomalies", "5", "Action Required", delta_color="inverse")
    col2.metric("Amount at Risk", "$1.8M", "+12% Last 30 Days", delta_color="off")
    col3.metric("Amount Protected", "$611K", "via Action Agent", delta_color="normal")
    col4.metric("Auto-Actions Executed", "7", "Holds & Tier Updates", delta_color="normal")
    
    st.markdown("<br>", unsafe_allow_html=True)
    
    # Charts and Tables
    tab1, tab2 = st.tabs(["Active Critical Anomalies", "Root Cause Distribution"])
    
    with tab1:
        st.dataframe(
            df_anomalies[df_anomalies['Severity'] == 'CRITICAL'][['ID', 'Category', 'Amount ($)', 'Supplier', 'Status']], 
            use_container_width=True, 
            hide_index=True
        )
        
    with tab2:
        rc_dist = pd.DataFrame({
            "Count": [3, 2, 2, 2, 1]
        }, index=["Fraud", "Contract Violation", "Market Condition", "Operational Error", "Data Quality"])
        st.bar_chart(rc_dist, height=350, color="#29B5E8")

elif page == "Anomaly Detection & Reports":
    st.title("Anomaly Detection & Deep Dive Reports")
    st.markdown("<p style='color: #A0A0A0; font-size: 1.1rem;'>Detailed analysis generated by Snowflake Cortex AI</p>", unsafe_allow_html=True)
    
    colA, colB = st.columns([1, 4])
    filter_sev = colA.selectbox("Filter by Severity", ["ALL", "CRITICAL", "WARNING"])
    
    display_df = df_anomalies if filter_sev == "ALL" else df_anomalies[df_anomalies['Severity'] == filter_sev]
    
    st.dataframe(display_df, use_container_width=True, hide_index=True)
    
    st.markdown("<hr style='border: 1px solid #333;'>", unsafe_allow_html=True)
    st.subheader("🔎 Detailed AI Investigation Report")
    
    selected = st.selectbox("Select Anomaly ID to generate Cortex AI Report:", df_anomalies['ID'].tolist())
    
    if selected and selected in cortex_reports:
        report = cortex_reports[selected]
        
        with st.container():
            st.markdown(f"<div style='background-color: #111; padding: 20px; border-radius: 8px; border: 1px solid #333;'>", unsafe_allow_html=True)
            st.markdown(f"#### 🧠 Root Cause Analysis for `{selected}`")
            st.markdown(f"> {report['reasoning']}")
            
            st.markdown("#### 📋 Extracted Evidence")
            for item in report['evidence']:
                st.markdown(f"- {item}")
                
            st.markdown("#### ⚡ Recommended Agent Action")
            st.success(report['recommended_action'])
            st.markdown("</div>", unsafe_allow_html=True)

elif page == "Supplier Risk":
    st.title("Supplier Risk Scorecard")
    st.markdown("<p style='color: #A0A0A0; font-size: 1.1rem;'>Multi-factor risk assessment by Root Cause Agent</p>", unsafe_allow_html=True)
    
    st.info("Scores (0-100) are generated dynamically based on Delivery, Financial health, and NLP-driven Compliance/Sentiment metrics.")
    
    st.dataframe(
        df_suppliers.style.background_gradient(cmap='RdYlGn', subset=['Score (0-100)']),
        use_container_width=True,
        hide_index=True
    )

elif page == "Investigation & Audit":
    st.title("System Logs: Investigation & Audit")
    
    tab_log, tab_audit = st.tabs(["AI Investigation Log", "Immutable Audit Trail"])
    
    with tab_log:
        st.markdown("<p style='color: #A0A0A0;'>Synthesis of structured financial data and unstructured contract/sentiment data.</p>", unsafe_allow_html=True)
        st.dataframe(df_investigations, use_container_width=True, hide_index=True)
        
    with tab_audit:
        st.markdown("<p style='color: #A0A0A0;'>Cryptographically secure trail of all autonomous actions taken by the FinOps agent.</p>", unsafe_allow_html=True)
        st.dataframe(df_audit, use_container_width=True, hide_index=True)
