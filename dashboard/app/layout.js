import './globals.css';

export const metadata = {
  title: 'LedgerLink | Snowflake',
  description: 'AI-driven multi-agent supply chain financial risk intelligence powered by Snowflake Cortex',
  keywords: 'supply chain, finops, anomaly detection, snowflake, cortex ai',
};

export const viewport = {
  width: 'device-width',
  initialScale: 1,
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
      </head>
      <body>{children}</body>
    </html>
  );
}
