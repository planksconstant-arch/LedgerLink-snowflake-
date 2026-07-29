import pytest
from streamlit_app.mock_data import get_mock_data

def test_mock_data_structure():
    """Verify that the mock data fallback returns the correct DataFrames."""
    df_anomalies, df_suppliers, df_investigations, df_audit = get_mock_data()
    
    # Test Anomalies DataFrame
    assert not df_anomalies.empty
    assert 'ID' in df_anomalies.columns
    assert 'Severity' in df_anomalies.columns
    
    # Test Suppliers DataFrame
    assert not df_suppliers.empty
    assert 'Name' in df_suppliers.columns
    assert 'Score (0-100)' in df_suppliers.columns
    
    # Test Investigations DataFrame
    assert not df_investigations.empty
    assert 'Inv ID' in df_investigations.columns
    
    # Test Audit DataFrame
    assert not df_audit.empty
    assert 'HMAC_Signature' in df_audit.columns

def test_mock_data_types():
    """Verify that the numeric columns in mock data are correctly typed."""
    _, df_suppliers, _, _ = get_mock_data()
    
    # Ensure Score is numeric
    assert df_suppliers['Score (0-100)'].dtype in ['int64', 'float64']
