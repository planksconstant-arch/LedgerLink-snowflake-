import Sidebar from '../../components/Sidebar';
import { ANOMALIES, ANOMALY_DETAILS, fmtFull, categoryLabel, severityClass } from '../../data';
import Link from 'next/link';

export default function AnomalyDetail({ params }) {
  const anomaly = ANOMALIES.find(a => a.id === params.id) || ANOMALIES[0];
  const details = ANOMALY_DETAILS[params.id] || ANOMALY_DETAILS['ANO-2026-001'];

  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main-content">
        <header className="topbar">
          <div className="topbar-left" style={{ flexDirection: 'row', alignItems: 'center', gap: 16 }}>
            <Link href="/anomalies" className="btn" style={{ padding: '4px 8px', fontSize: 11 }}>← Back</Link>
            <h1 className="topbar-title mono">{anomaly.id}</h1>
          </div>
          <div className="topbar-right">
            <span className={`badge ${severityClass(anomaly.severity)}`}>{anomaly.severity}</span>
          </div>
        </header>

        <div className="page-content">
          <div className="grid-3">
            <div className="detail-section">
              <div className="detail-label">Supplier</div>
              <div className="detail-value">{anomaly.supplier}</div>
              <div className="mono" style={{ fontSize: 11, color: 'var(--text-muted)' }}>{anomaly.supplierId}</div>
            </div>
            <div className="detail-section">
              <div className="detail-label">Anomaly Category</div>
              <div className="detail-value">{categoryLabel(anomaly.category)}</div>
              <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Root Cause: {anomaly.rootCause}</div>
            </div>
            <div className="detail-section">
              <div className="detail-label">Financial Impact</div>
              <div className="detail-value mono" style={{ color: 'var(--critical)' }}>{fmtFull(anomaly.amount)}</div>
              <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Expected: {fmtFull(anomaly.expected)} (+{anomaly.deviation}%)</div>
            </div>
          </div>

          <div className="card">
            <div className="card-header">
              <h2 className="card-title">
                <span className="badge badge-info">Cortex AI</span>
                Investigation & Reasoning
              </h2>
            </div>
            <div className="card-body">
              <div className="cortex-output">
                {details.cortexReasoning}
              </div>

              <div className="grid-3" style={{ marginTop: 24, gap: 16 }}>
                <div style={{ padding: 16, background: 'rgba(255,255,255,0.02)', borderRadius: 6, border: '1px solid var(--border)' }}>
                  <div className="detail-label">Contract Evidence (UNSTRUCTURED)</div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{details.evidence.contractClause}</div>
                </div>
                <div style={{ padding: 16, background: 'rgba(255,255,255,0.02)', borderRadius: 6, border: '1px solid var(--border)' }}>
                  <div className="detail-label">Sentiment Shift</div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Score: <span className="mono">{details.evidence.sentimentScore}</span></div>
                  <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Based on {details.evidence.relatedEmails} recent emails</div>
                </div>
                <div style={{ padding: 16, background: 'rgba(255,255,255,0.02)', borderRadius: 6, border: '1px solid var(--border)' }}>
                  <div className="detail-label">System State</div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Detected: {anomaly.date}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Status: {anomaly.status}</div>
                </div>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="card-header">
              <h2 className="card-title">Action Timeline</h2>
            </div>
            <div className="card-body">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Timestamp</th>
                    <th>Action</th>
                    <th>Target</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {details.actionsTaken.map(act => (
                    <tr key={act.id}>
                      <td className="mono">{act.timestamp}</td>
                      <td>{act.action}</td>
                      <td className="mono">{act.target}</td>
                      <td><span className="badge badge-success">{act.status}</span></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
