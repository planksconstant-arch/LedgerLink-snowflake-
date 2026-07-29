'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

const SnowflakeLogo = () => (
  <svg width="28" height="28" viewBox="0 0 100 100" fill="none">
    <path d="M50 5 L50 95 M5 50 L95 50 M19 19 L81 81 M81 19 L19 81" stroke="#29B5E8" strokeWidth="12" strokeLinecap="round"/>
    <circle cx="50" cy="5"  r="6" fill="#29B5E8"/>
    <circle cx="50" cy="95" r="6" fill="#29B5E8"/>
    <circle cx="5"  cy="50" r="6" fill="#29B5E8"/>
    <circle cx="95" cy="50" r="6" fill="#29B5E8"/>
    <circle cx="19" cy="19" r="6" fill="#00D4FF"/>
    <circle cx="81" cy="81" r="6" fill="#00D4FF"/>
    <circle cx="81" cy="19" r="6" fill="#00D4FF"/>
    <circle cx="19" cy="81" r="6" fill="#00D4FF"/>
  </svg>
);

const NAV = [
  { href: '/', label: 'Dashboard', icon: '▦' },
  { href: '/anomalies', label: 'Anomaly Detection', icon: '⚠' },
  { href: '/suppliers', label: 'Supplier Risk', icon: '◎' },
  { href: '/investigations', label: 'Investigation Log', icon: '🔬' },
  { href: '/audit', label: 'Audit Trail', icon: '◈' },
];

export default function Sidebar() {
  const path = usePathname();

  return (
    <aside className="sidebar">
      <div className="sidebar-logo">
        <SnowflakeLogo />
        <div className="sidebar-logo-text">
          <span className="brand">Snowflake Cortex</span>
          <span className="product">FinOps Agent</span>
        </div>
      </div>

      <div className="sidebar-section">
        <div className="sidebar-section-label">Navigation</div>
        {NAV.map(({ href, label, icon }) => (
          <Link
            key={href}
            href={href}
            className={`nav-item${path === href ? ' active' : ''}`}
          >
            <span className="nav-icon" style={{ fontSize: 15, lineHeight: 1 }}>{icon}</span>
            {label}
          </Link>
        ))}
      </div>

      <div className="sidebar-footer">
        <div className="agent-status-pill">
          <div className="pulse-dot" />
          5 Agents Active
        </div>
        <div style={{ marginTop: 10, fontSize: 11, color: 'var(--text-muted)', lineHeight: 1.5, paddingLeft: 2 }}>
          Last scan: <span style={{ color: 'var(--text-secondary)' }}>07:12 UTC</span><br/>
          DB: <span style={{ color: 'var(--snow-blue)', fontFamily: 'monospace' }}>SUPPLY_CHAIN_FINOPS</span>
        </div>
      </div>
    </aside>
  );
}
