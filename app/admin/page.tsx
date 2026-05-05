'use client';
import { useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase';
import { JobsTable } from '@/components/JobsTable';

export default function AdminPage(){
  const [jobs,setJobs]=useState<any[]>([]);
  useEffect(()=>{(async()=>{const s=createClient(); const {data}=await s.from('estimate_rewrite_jobs').select('*').order('created_at',{ascending:false}); setJobs(data??[]);})();},[]);
  return <div><h2>Admin Dashboard</h2><p>Admin can manage all jobs, financial fields, assignment, QC release, and files.</p><JobsTable jobs={jobs}/></div>
}
