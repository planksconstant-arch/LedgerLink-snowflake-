#!/usr/bin/env python3
"""
Batch Supplier Risk Scorer
==========================
Wraps the core risk_scorer.py to process a list of SupplierMetrics objects
in a single call, returning a dict keyed by supplier_id.

Used by the $root-cause-agent to score ALL affected suppliers in one shot
instead of calling calculate_risk_score() per supplier in a sequential loop.

Usage:
    from batch_scorer import batch_score_suppliers
    results = batch_score_suppliers([metrics1, metrics2, ...])
    # results = {"SUP-001": RiskScore(...), "SUP-005": RiskScore(...)}
"""

import json
import sys
import os
from typing import List, Dict

# Import from the shared root-cause-analyst scripts
# (batch_scorer lives alongside risk_scorer in the same scripts/ directory)
_THIS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _THIS_DIR)

from risk_scorer import SupplierMetrics, RiskScore, calculate_risk_score, score_to_dict


def batch_score_suppliers(metrics_list: List[SupplierMetrics]) -> Dict[str, RiskScore]:
    """
    Score multiple suppliers in a single call.

    Args:
        metrics_list: List of SupplierMetrics dataclass instances.

    Returns:
        A dict mapping supplier_id → RiskScore.
        Duplicate supplier_ids in the input are overwritten (last one wins).
    """
    results: Dict[str, RiskScore] = {}
    for metrics in metrics_list:
        results[metrics.supplier_id] = calculate_risk_score(metrics)
    return results


def batch_score_to_dict(scores: Dict[str, RiskScore]) -> Dict[str, dict]:
    """Convert a batch result to a JSON-serialisable dict of dicts."""
    return {supplier_id: score_to_dict(score) for supplier_id, score in scores.items()}


def get_high_risk_supplier_ids(
    scores: Dict[str, RiskScore],
    threshold: float = 50.0
) -> List[str]:
    """
    Return supplier_ids whose composite score is below the threshold.
    Default threshold 50 = HIGH_RISK or worse.
    """
    return [
        sid for sid, score in scores.items()
        if score.composite_score < threshold
    ]


def get_critical_risk_supplier_ids(scores: Dict[str, RiskScore]) -> List[str]:
    """Return supplier_ids assessed as CRITICAL_RISK (composite < 30)."""
    return get_high_risk_supplier_ids(scores, threshold=30.0)


def summarize_batch(scores: Dict[str, RiskScore]) -> dict:
    """
    Produce an orchestrator-friendly summary of the batch scoring run.

    Example output:
    {
        "total_scored": 4,
        "risk_distribution": {
            "LOW_RISK": 2,
            "MEDIUM_RISK": 1,
            "HIGH_RISK": 1,
            "CRITICAL_RISK": 0
        },
        "critical_suppliers": [],
        "high_risk_suppliers": ["SUP-005"],
        "avg_composite_score": 61.2
    }
    """
    distribution: Dict[str, int] = {
        "LOW_RISK": 0,
        "MEDIUM_RISK": 0,
        "HIGH_RISK": 0,
        "CRITICAL_RISK": 0,
    }
    total_composite = 0.0

    for score in scores.values():
        distribution[score.risk_assessment] = distribution.get(score.risk_assessment, 0) + 1
        total_composite += score.composite_score

    n = len(scores)
    return {
        "total_scored": n,
        "risk_distribution": distribution,
        "critical_suppliers": get_critical_risk_supplier_ids(scores),
        "high_risk_suppliers": get_high_risk_supplier_ids(scores),
        "avg_composite_score": round(total_composite / n, 1) if n > 0 else 0.0,
    }


# ─── Example / Self-Test ────────────────────────────────────────────────────

if __name__ == "__main__":
    """
    Self-test: Score the 3 known high-risk suppliers from the demo dataset.
    Expected: SUP-005 → HIGH_RISK or CRITICAL_RISK, SUP-001 and SUP-008 → MEDIUM/HIGH.
    """

    test_metrics = [
        # SUP-005 — Dragon Polymers (known high-risk)
        SupplierMetrics(
            supplier_id="SUP-005",
            supplier_name="Dragon Polymers Ltd",
            total_shipments=6,
            avg_delay_days=5.2,
            max_delay_days=10,
            late_delivery_rate=0.67,
            total_invoices=8,
            total_invoiced_amount=1_200_000.00,
            unmatched_invoices=1,
            disputed_invoices=0,
            avg_sentiment=-0.44,
            latest_sentiment=-0.85,
            sentiment_delta=-1.55,   # Previously caused overflow — now clamped to -2.0
            risk_tier="HIGH",
            is_active=True,
            has_active_contract=True,
            contract_violations=1,
        ),
        # SUP-001 — Duplicate payment supplier (moderate risk)
        SupplierMetrics(
            supplier_id="SUP-001",
            supplier_name="AlphaChem Industries",
            total_shipments=12,
            avg_delay_days=1.5,
            max_delay_days=4,
            late_delivery_rate=0.08,
            total_invoices=15,
            total_invoiced_amount=2_500_000.00,  # Large volume — no longer penalised (Fix #8)
            unmatched_invoices=0,
            disputed_invoices=1,
            avg_sentiment=0.2,
            latest_sentiment=0.1,
            sentiment_delta=-0.1,
            risk_tier="MEDIUM",
            is_active=True,
            has_active_contract=True,
            contract_violations=0,
        ),
        # SUP-008 — Phantom vendor (inactive, no contract)
        SupplierMetrics(
            supplier_id="SUP-008",
            supplier_name="Phantom Supplies Co",
            total_shipments=0,
            avg_delay_days=0.0,
            max_delay_days=0,
            late_delivery_rate=0.0,
            total_invoices=1,
            total_invoiced_amount=93_960.00,
            unmatched_invoices=0,
            disputed_invoices=0,
            avg_sentiment=0.0,
            latest_sentiment=0.0,
            sentiment_delta=0.0,
            risk_tier="CRITICAL",
            is_active=False,          # Inactive supplier
            has_active_contract=False, # No active contract — Fix #9: won't go deeply negative
            contract_violations=0,
        ),
    ]

    scores = batch_score_suppliers(test_metrics)
    summary = summarize_batch(scores)

    print("=" * 60)
    print("  BATCH RISK SCORING RESULTS")
    print("=" * 60)
    for supplier_id, score in scores.items():
        d = score_to_dict(score)
        print(f"\n  {supplier_id} — {d['supplier_name']}")
        print(f"    Composite Score: {d['scores']['composite']}/100 ({d['risk_assessment']})")
        print(f"    Delivery:        {d['scores']['delivery']}/25")
        print(f"    Financial:       {d['scores']['financial']}/25")
        print(f"    Relationship:    {d['scores']['relationship']}/25")
        print(f"    Compliance:      {d['scores']['compliance']}/25")
        if d['risk_factors'] != ["No significant risk factors identified"]:
            print(f"    Risk Factors:")
            for f in d['risk_factors']:
                print(f"      ⚠  {f}")

    print("\n" + "=" * 60)
    print("  BATCH SUMMARY")
    print("=" * 60)
    print(json.dumps(summary, indent=2))
