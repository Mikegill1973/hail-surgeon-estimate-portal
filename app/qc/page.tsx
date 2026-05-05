'use client';
import { useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase';
import { JobsTable } from '@/components/JobsTable';

export default function QcPage(){
  const [jobs,setJobs]=useState<any[]>([]);
  useEffect(()=>{(async()=>{const s=createClient(); const {data}=await s.from('estimate_rewrite_jobs').select('id,job_number,status,qc_status,assigned_estimator_id,revision_request,qc_notes').in('status',['QC Review','Revision Needed']).order('updated_at',{ascending:false}); setJobs(data??[]);})();},[]);
  return <div><h2>QC Dashboard</h2><JobsTable jobs={jobs}/></div>
}
