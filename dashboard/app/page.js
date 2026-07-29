import Sidebar from './components/Sidebar';
import { STATS, PIPELINE_AGENTS, ANOMALIES, fmt, severityClass, categoryLabel } from './data';
import Link from 'next/link';

export default function Dashboard() {
  const topAnomalies = ANOMALIES.filter(a => a.severity === 'CRITICAL').slice(0, 4);

  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main-content">
        <header className="topbar">
          <div className="topbar-left">
            <h1 className="topbar-title">Overview</h1>
          </div>
          <div className="topbar-right">
            <span className="badge badge-neutral">Last Scan: 07:12 UTC</span>
          </div>
        </header>

        <div className="page-content">
          <div className="metrics-grid">
            <div className="metric-card">
              <div className="metric-label">Critical Anomalies</div>
              <div className="metric-value" style={{ color: 'var(--critical)', marginTop: 8 }}>{STATS.criticalCount}</div>
            </div>
            <div className="metric-card">
              <div className="metric-label">Amount at Risk</div>
              <div className="metric-value" style={{ color: 'var(--warning)', marginTop: 8 }}>{fmt(STATS.amountAtRisk)}</div>
            </div>
            <div className="metric-card">
              <div className="metric-label">Amount Protected</div>
              <div className="metric-value" style={{ color: 'var(--success)', marginTop: 8 }}>{fmt(STATS.amountProtected)}</div>
            </div>
            <div className="metric-card">
              <div className="metric-label">Auto-Actions Taken</div>
              <div className="metric-value" style={{ color: 'var(--info)', marginTop: 8 }}>{STATS.actionsTaken}</div>
            </div>
          </div>

          <div className="card">
            <div className="card-header">
              <h2 className="card-title">Orchestration Pipeline</h2>
            </div>
            <div className="card-body">
              <div className="pipeline-container">
                {PIPELINE_AGENTS.map((agent, i) => (
                  <div key={agent.id} style={{ display: 'flex', alignItems: 'center' }}>
                    <div className="pipeline-node">
                      <div className="pipeline-node-box">
                        {agent.name.replace('\n', ' ')}
                      </div>
                      <div style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{agent.result}</div>
                    </div>
                    {i < PIPELINE_AGENTS.length - 1 && <div className="pipeline-connector"></div>}
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="grid-2">
            <div className="card">
              <div className="card-header">
                <h2 className="card-title">Critical Anomalies</h2>
                <Link href="/anomalies" className="btn" style={{ padding: '4px 8px', fontSize: 11 }}>View All →</Link>
              </div>
              <div className="card-body" style={{ padding: 0 }}>
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Category</th>
                      <th>Amount</th>
                    </tr>
                  </thead>
                  <tbody>
                    {topAnomalies.map(a => (
                      <tr key={a.id} className="clickable">
                        <td><Link href={`/anomalies/${a.id}`} className="mono" style={{ color: 'var(--text-primary)', textDecoration: 'none' }}>{a.id}</Link></td>
                        <td>{categoryLabel(a.category)}</td>
                        <td className="mono">{fmt(a.amount)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="card">
              <div className="card-header">
                <h2 className="card-title">Root Cause Distribution</h2>
                <span className="badge badge-neutral">Cortex AI</span>
              </div>
              <div className="card-body">
                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Fraud</span>
                    <span className="mono" style={{ color: 'var(--critical)' }}>3</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Contract Violation</span>
                    <span className="mono" style={{ color: 'var(--warning)' }}>2</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Market Condition</span>
                    <span className="mono" style={{ color: 'var(--purple)' }}>2</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Operational Error</span>
                    <span className="mono" style={{ color: 'var(--info)' }}>2</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Data Quality</span>
                    <span className="mono" style={{ color: 'var(--text-muted)' }}>1</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
