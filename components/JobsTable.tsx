'use client';
import { useMemo, useState } from 'react';

type Job = Record<string, string | number | boolean | null>;

export function JobsTable({ jobs }: { jobs: Job[] }) {
  const [q, setQ] = useState('');
  const filtered = useMemo(() => jobs.filter((j) => JSON.stringify(j).toLowerCase().includes(q.toLowerCase())), [jobs, q]);
  return <>
    <div className="toolbar"><input placeholder="Search status/company/claim/VIN" value={q} onChange={(e)=>setQ(e.target.value)} /></div>
    <table><thead><tr>{Object.keys(filtered[0] || {}).map((k) => <th key={k}>{k}</th>)}</tr></thead>
    <tbody>{filtered.map((j, i) => <tr key={i} className={`status-${j.status ?? ''}`}>{Object.entries(j).map(([k,v]) => <td key={k}>{String(v ?? '')}</td>)}</tr>)}</tbody></table>
  </>;
}
