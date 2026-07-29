import hmac
import hashlib
import time

SECRET_KEY = b"ledgerlink_demo_secret_key_2026"

def generate_audit_hmac(action: str, target: str, agent: str) -> str:
    """
    Simulates a cryptographic HMAC signature for an audit trail row.
    This ensures that once an agent takes an action, the audit log cannot be 
    tampered with without breaking the signature.
    """
    timestamp = str(time.time())
    payload = f"{action}|{target}|{agent}|{timestamp}".encode('utf-8')
    
    signature = hmac.new(SECRET_KEY, payload, hashlib.sha256).hexdigest()
    return signature

def verify_audit_hmac(action: str, target: str, agent: str, timestamp: str, signature: str) -> bool:
    """
    Verifies the integrity of an audit row.
    """
    payload = f"{action}|{target}|{agent}|{timestamp}".encode('utf-8')
    expected_signature = hmac.new(SECRET_KEY, payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected_signature, signature)
