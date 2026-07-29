import streamlit as st
import pandas as pd
from datetime import datetime
from security import generate_audit_hmac
from mock_data import cortex_reports

def render_judge_mode():
    st.header("👨‍⚖️ Judge Evaluation Mode")
    st.markdown("Welcome! This guided mode walks you through the core value proposition of LedgerLink: **Detection, AI Investigation, and Safe Remediation**.")
    
    st.markdown("---")
    st.subheader("Step 1: The Anomaly (Detection)")
    st.info("The system has flagged **ANO-2026-001**, a massive price spike for supplier 'Dragon Polymers Ltd'.")
    
    col1, col2, col3 = st.columns(3)
    col1.metric("Historical Price", "$300 / unit")
    col2.metric("Invoiced Price", "$891 / unit", "+197%", delta_color="inverse")
    col3.metric("Supplier Risk Tier", "HIGH")
    
    st.markdown("---")
    st.subheader("Step 2: Cortex AI Investigation (Reasoning)")
    st.markdown("LedgerLink doesn't just flag numbers; it reads contracts and emails.")
    
    report = cortex_reports['ANO-2026-001']
    st.write(f"> {report['reasoning']}")
    
    with st.expander("View Evidence (Extracted by AI)"):
        for item in report['evidence']:
            st.markdown(f"- {item}")
            
    st.markdown("---")
    st.subheader("Step 3: Human-in-the-Loop Safety Gate")
    st.markdown("The Action Agent wants to execute the following remediation:")
    st.error(f"**Recommended Action:** {report['recommended_action']}")
    
    if "judge_action_executed" not in st.session_state:
        st.session_state.judge_action_executed = False
        
    if not st.session_state.judge_action_executed:
        if st.button("✅ Approve & Execute Action", type="primary"):
            st.session_state.judge_action_executed = True
            st.rerun()
    else:
        st.success("Action Approved! Payment held and Procurement alerted.")
        
        st.markdown("---")
        st.subheader("Step 4: Immutable Cryptographic Audit Trail")
        st.markdown("Enterprise finance requires strict auditing. LedgerLink signs every automated action with an HMAC SHA-256 signature to prevent tampering.")
        
        action = "HOLD_PAYMENT"
        target = "ANO-2026-001"
        agent = "$action-agent"
        sig = generate_audit_hmac(action, target, agent)
        
        audit_df = pd.DataFrame([{
            "Timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "Action": action,
            "Target": target,
            "Agent": agent,
            "Status": "SUCCESS",
            "HMAC_Signature": sig
        }])
        
        st.dataframe(audit_df, use_container_width=True)
        st.caption(f"Verified Signature Hash: `{sig}`")
        
        if st.button("Reset Judge Mode"):
            st.session_state.judge_action_executed = False
            st.rerun()
