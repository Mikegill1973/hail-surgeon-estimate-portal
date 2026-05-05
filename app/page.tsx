import Link from 'next/link';
export default function Home() {
  return <div className="card"><h1>Hail Surgeon Estimate Rewrite Portal</h1><p>Use role dashboards:</p><ul><li><Link href="/admin">Admin</Link></li><li><Link href="/customer">Customer</Link></li><li><Link href="/estimator">Estimator</Link></li><li><Link href="/qc">QC</Link></li></ul></div>;
}
