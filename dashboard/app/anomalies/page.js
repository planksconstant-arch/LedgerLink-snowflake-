import Sidebar from '../components/Sidebar';
import { ANOMALIES, fmtFull, severityClass, categoryLabel } from '../data';
import Link from 'next/link';

export default function AnomaliesPage() {
  return (
    <div className="app-shell">
      <Sidebar />
      <main className="main-content">
        <header className="topbar">
          <div className="topbar-left">
            <h1 className="topbar-title">Anomaly Detection</h1>
          </div>
          <div className="topbar-right">
            <span className="badge badge-neutral">10 Total Anomalies</span>
          </div>
        </header>

        <div className="page-content">
          <div className="card">
            <div className="card-header">
              <h2 className="card-title">Detected Anomalies</h2>
              <div style={{ display: 'flex', gap: 12 }}>
                <button className="btn">Filter: CRITICAL</button>
                <button className="btn" style={{ background: '#29B5E8', color: '#fff', borderColor: '#29B5E8' }}>Run Scan</button>
              </div>
            </div>
            <div className="card-body" style={{ padding: 0 }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Date</th>
                    <th>Category</th>
                    <th>Supplier</th>
                    <th>Amount at Risk</th>
                    <th>Severity</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {ANOMALIES.map(a => (
                    <tr key={a.id} className="clickable">
                      <td>
                        <Link href={`/anomalies/${a.id}`} className="mono" style={{ color: 'var(--text-primary)', textDecoration: 'none' }}>
                          {a.id}
                        </Link>
                      </td>
                      <td style={{ color: 'var(--text-secondary)' }}>{a.date}</td>
                      <td>{categoryLabel(a.category)}</td>
                      <td style={{ color: 'var(--text-secondary)' }}>{a.supplier}</td>
                      <td className="mono">{fmtFull(a.amount)}</td>
                      <td>
                        <span className={`badge ${severityClass(a.severity)}`}>{a.severity}</span>
                      </td>
                      <td>
                        {a.status === 'INVESTIGATED' && <span className="badge badge-info">Investigated</span>}
                        {a.status === 'HOLD' && <span className="badge badge-success">Hold Applied</span>}
                        {a.status === 'ESCALATED' && <span className="badge badge-warning">Escalated</span>}
                        {a.status === 'FLAGGED' && <span className="badge badge-neutral">Flagged</span>}
                        {a.status === 'ACTION_TAKEN' && <span className="badge badge-purple">Action Taken</span>}
                        {a.status === 'REVIEWED' && <span className="badge badge-neutral">Reviewed</span>}
                        {a.status === 'MONITORING' && <span className="badge badge-neutral">Monitoring</span>}
                      </td>
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
