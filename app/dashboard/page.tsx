'use client';
import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

type Job={id:string;status:string;claim_number:string|null;vin:string|null;insurance_company:string|null;priority:string|null;customer_company_name:string|null;assigned_estimator_name:string|null;date_received:string|null;qc_status:string|null;customer_facing_notes:string|null;estimator_notes:string|null};

export default function Dashboard(){const[role,setRole]=useState<string>('');const[jobs,setJobs]=useState<Job[]>([]);
useEffect(()=>{(async()=>{const {data:userData}=await supabase.auth.getUser();if(!userData.user)return;const {data:profile}=await supabase.from('profiles').select('role').eq('id',userData.user.id).single();setRole(profile?.role||'');const {data}=await supabase.from('jobs_secure_view').select('*').order('created_at',{ascending:false});setJobs(data||[]);})();},[]);
async function signOut(){await supabase.auth.signOut();location.href='/login';}
return <main><div className='card'><h2>Dashboard: {role}</h2><button onClick={signOut}>Logout</button></div><div className='card'><h3>Jobs</h3><table className='table'><thead><tr><th>Status</th><th>Company</th><th>Estimator</th><th>Priority</th><th>Claim</th><th>VIN</th><th>Insurance</th><th>Date Received</th><th>QC</th><th>Customer Notes</th><th>Estimator Notes</th></tr></thead><tbody>{jobs.map(j=><tr key={j.id}><td>{j.status}</td><td>{j.customer_company_name}</td><td>{j.assigned_estimator_name}</td><td>{j.priority}</td><td>{j.claim_number}</td><td>{j.vin}</td><td>{j.insurance_company}</td><td>{j.date_received}</td><td>{j.qc_status}</td><td>{j.customer_facing_notes}</td><td>{j.estimator_notes}</td></tr>)}</tbody></table></div></main>}
