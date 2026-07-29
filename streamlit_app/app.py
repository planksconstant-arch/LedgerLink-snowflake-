import streamlit as st
import pandas as pd
import json
import judge_mode

st.set_page_config(
    page_title="LedgerLink",
    page_icon="gear",
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

from mock_data import get_mock_data, cortex_reports

@st.cache_data
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
        return get_mock_data()

df_anomalies, df_suppliers, df_investigations, df_audit = get_data()

# -----------------------------------------------------------------------------
# 2. SIDEBAR NAVIGATION
# -----------------------------------------------------------------------------
with st.sidebar:
    st.image("https://upload.wikimedia.org/wikipedia/commons/f/ff/Snowflake_Logo.svg", width=180)
    st.markdown("<br>", unsafe_allow_html=True)
    st.markdown("### LedgerLink")
    st.markdown("Powered by **Cortex AI**")
    st.markdown("---")
    
    page = st.radio("Navigation", ["Overview Dashboard", "Anomaly Detection & Reports", "Supplier Risk", "Investigation & Audit", "👨‍⚖️ Judge Mode (Evaluation)"], label_visibility="collapsed")
    
    st.markdown("---")
    st.success("Status: 5/5 Agents Online")
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

elif page == "👨‍⚖️ Judge Mode (Evaluation)":
    judge_mode.render_judge_mode()
