import Sidebar from '../components/Sidebar';
import { INVESTIGATIONS, rootCauseColor } from '../data';

export default function InvestigationsPage() {
  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main-content">
        <header className="topbar">
          <div className="topbar-left">
            <h1 className="topbar-title">Investigation Log</h1>
            <div className="topbar-sub">Structured + Unstructured data synthesis via Root Cause Agent</div>
          </div>
          <div className="topbar-right">
            <div className="topbar-badge badge-info">Cortex AI Reasoning Active</div>
          </div>
        </header>

        <div className="page-content">
          <div className="card">
            <div className="card-header">
              <h2 className="card-title">Completed Investigations</h2>
            </div>
            <div className="card-body" style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
              {INVESTIGATIONS.map(inv => (
                <div key={inv.id} style={{ background: 'var(--bg-secondary)', border: '1px solid var(--border)', borderRadius: 12, padding: 20 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
                        <span className="mono" style={{ fontSize: 13, color: 'var(--text-primary)' }}>{inv.id}</span>
                        <span className="badge badge-neutral">{inv.anomalyId}</span>
                        {inv.aiInvestigated && <span className="badge badge-info" style={{ gap: 4 }}>✨ AI Investigated</span>}
                      </div>
                      <div style={{ fontSize: 15, fontWeight: 600, color: 'var(--text-primary)' }}>{inv.supplier}</div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 6 }}>{inv.timestamp}</div>
                      <div className="badge" style={{ background: `${rootCauseColor(inv.category)}1A`, color: rootCauseColor(inv.category), borderColor: `${rootCauseColor(inv.category)}4D` }}>
                        Root Cause: {inv.category}
                      </div>
                    </div>
                  </div>

                  <div className="grid-3" style={{ gap: 24, marginBottom: 16 }}>
                    <div>
                      <div className="section-label">Evidence Summary</div>
                      <div style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.5 }}>{inv.rootCause}</div>
                    </div>
                    <div>
                      <div className="section-label">Unstructured Analysis</div>
                      <div className="score-row">
                        <div className="score-row-header"><span className="score-row-label">Contract Violation:</span> <span className="score-row-val" style={{ color: inv.contractViolation ? 'var(--critical)' : 'var(--success)' }}>{inv.contractViolation ? 'YES' : 'NO'}</span></div>
                        <div className="score-row-header"><span className="score-row-label">Sentiment Trend:</span> <span className="score-row-val mono" style={{ fontSize: 11 }}>{inv.sentimentTrend}</span></div>
                        <div className="score-row-header"><span className="score-row-label">Confidence:</span> <span className="score-row-val" style={{ color: 'var(--success)' }}>{inv.confidence}</span></div>
                      </div>
                    </div>
                    <div>
                      <div className="section-label">AI Recommendation</div>
                      <div style={{ fontSize: 13, color: 'var(--text-primary)', fontWeight: 500, background: 'rgba(41,181,232,0.06)', padding: 12, borderRadius: 8, border: '1px solid rgba(41,181,232,0.1)' }}>
                        {inv.recommendedAction}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
