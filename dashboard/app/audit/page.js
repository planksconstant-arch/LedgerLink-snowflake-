import Sidebar from '../components/Sidebar';
import { AUDIT_TRAIL, fmt } from '../data';

export default function AuditPage() {
  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main-content">
        <header className="topbar">
          <div className="topbar-left">
            <h1 className="topbar-title">Audit Trail</h1>
            <div className="topbar-sub">Immutable log of all agent actions, holds, and notifications</div>
          </div>
          <div className="topbar-right">
            <div className="topbar-badge badge-neutral">Action & Notification Agents</div>
          </div>
        </header>

        <div className="page-content">
          <div className="card">
            <div className="card-header">
              <h2 className="card-title">Action Execution History</h2>
            </div>
            <div className="card-body">
              <div className="timeline">
                {AUDIT_TRAIL.map(item => (
                  <div key={item.id} className="timeline-item">
                    <div className="timeline-dot" style={{ 
                      borderColor: item.type === 'AUTO_EXECUTED' ? 'var(--snow-blue)' : 'var(--warning)',
                      background: item.type === 'AUTO_EXECUTED' ? 'var(--bg-card)' : 'var(--warning-dim)',
                      color: item.type === 'AUTO_EXECUTED' ? 'var(--snow-blue)' : 'var(--warning)'
                    }}>
                      {item.action === 'HOLD_PAYMENT' ? '🛑' : item.action.includes('NOTIFY') ? '📢' : item.action === 'FLAG_INVOICE' ? '🚩' : item.action === 'ESCALATE' ? '✋' : '⚙'}
                    </div>
                    <div className="timeline-content">
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                        <div>
                          <div className="timeline-action">
                            {item.action} 
                            <span style={{ margin: '0 8px', color: 'var(--text-muted)', fontWeight: 400 }}>→</span>
                            <span className="mono" style={{ fontSize: 12, color: 'var(--text-primary)' }}>{item.target}</span>
                          </div>
                          <div className="timeline-meta">
                            Triggered by <span className="mono">{item.anomalyId}</span> via {item.agent}
                          </div>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 4 }}>{item.timestamp}</div>
                          {item.type === 'AUTO_EXECUTED' 
                            ? <span className="badge badge-success" style={{ fontSize: 10, padding: '2px 8px' }}>AUTO-EXECUTED</span>
                            : <span className="badge badge-warning" style={{ fontSize: 10, padding: '2px 8px' }}>ESCALATED</span>
                          }
                        </div>
                      </div>
                      
                      <div style={{ marginTop: 12, padding: 12, background: 'var(--bg-secondary)', borderRadius: 8, border: '1px solid var(--border)' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>{item.reason}</span>
                          {item.amount && <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-primary)' }}>Impact: {fmt(item.amount)}</span>}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
