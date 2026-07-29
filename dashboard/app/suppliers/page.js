import Sidebar from '../components/Sidebar';
import { SUPPLIERS, riskColor, riskLabel } from '../data';

export default function SuppliersPage() {
  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main-content">
        <header className="topbar">
          <div className="topbar-left">
            <h1 className="topbar-title">Supplier Risk Leaderboard</h1>
            <div className="topbar-sub">Composite scores calculated by Root Cause Agent (Batch Scorer)</div>
          </div>
          <div className="topbar-right">
            <div className="topbar-badge badge-neutral">30 Active Suppliers</div>
          </div>
        </header>

        <div className="page-content">
          <div className="card">
            <div className="card-header">
              <h2 className="card-title">Risk Assessment Scorecard</h2>
            </div>
            <div className="card-body" style={{ padding: 0 }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Supplier ID</th>
                    <th>Name</th>
                    <th>Composite Score (0-100)</th>
                    <th>Risk Tier</th>
                    <th>Anomalies</th>
                    <th style={{ width: 140 }}>Delivery (25)</th>
                    <th style={{ width: 140 }}>Financial (25)</th>
                    <th style={{ width: 140 }}>Relation (25)</th>
                    <th style={{ width: 140 }}>Compliance (25)</th>
                  </tr>
                </thead>
                <tbody>
                  {SUPPLIERS.sort((a,b) => a.composite - b.composite).map(s => {
                    const rc = riskColor(s.composite);
                    return (
                      <tr key={s.id} style={{ opacity: s.active ? 1 : 0.6 }}>
                        <td><div className="mono">{s.id}</div></td>
                        <td style={{ fontWeight: 600 }}>{s.name} {!s.active && <span className="badge badge-neutral" style={{ padding: '0 4px', fontSize: 10, marginLeft: 4 }}>INACTIVE</span>}</td>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                            <div style={{ fontWeight: 800, fontSize: 16, color: rc, width: 40 }}>{s.composite.toFixed(1)}</div>
                            <div className="progress-bar-track" style={{ width: 100 }}>
                              <div className="progress-bar-fill" style={{ width: `${s.composite}%`, background: rc }}></div>
                            </div>
                          </div>
                        </td>
                        <td>
                          <span className="badge" style={{ background: `${rc}1A`, color: rc, borderColor: `${rc}4D` }}>
                            {riskLabel(s.composite)}
                          </span>
                        </td>
                        <td style={{ color: s.anomalyCount > 0 ? 'var(--warning)' : 'var(--text-muted)', fontWeight: 600 }}>
                          {s.anomalyCount}
                        </td>
                        <td>
                          <div className="progress-bar-wrap">
                            <div className="progress-bar-track">
                              <div className="progress-bar-fill" style={{ width: `${(s.delivery/25)*100}%`, background: 'var(--text-secondary)' }}></div>
                            </div>
                            <div className="progress-label">{s.delivery.toFixed(1)}</div>
                          </div>
                        </td>
                        <td>
                          <div className="progress-bar-wrap">
                            <div className="progress-bar-track">
                              <div className="progress-bar-fill" style={{ width: `${(s.financial/25)*100}%`, background: 'var(--text-secondary)' }}></div>
                            </div>
                            <div className="progress-label">{s.financial.toFixed(1)}</div>
                          </div>
                        </td>
                        <td>
                          <div className="progress-bar-wrap">
                            <div className="progress-bar-track">
                              <div className="progress-bar-fill" style={{ width: `${(s.relationship/25)*100}%`, background: 'var(--text-secondary)' }}></div>
                            </div>
                            <div className="progress-label">{s.relationship.toFixed(1)}</div>
                          </div>
                        </td>
                        <td>
                          <div className="progress-bar-wrap">
                            <div className="progress-bar-track">
                              <div className="progress-bar-fill" style={{ width: `${(s.compliance/25)*100}%`, background: 'var(--text-secondary)' }}></div>
                            </div>
                            <div className="progress-label">{s.compliance.toFixed(1)}</div>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
