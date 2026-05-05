'use client';
import { useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase';
import { JobsTable } from '@/components/JobsTable';

const columns='id,job_number,status,priority,rewrite_type,estimate_type,date_received,due_date,claim_number,vin,insurance_company_name,missing_info_request,revision_request,estimator_notes';
export default function EstimatorPage(){
  const [jobs,setJobs]=useState<any[]>([]);
  useEffect(()=>{(async()=>{const s=createClient(); const {data}=await s.from('estimate_rewrite_jobs').select(columns).order('date_received',{ascending:false}); setJobs(data??[]);})();},[]);
  return <div><h2>Estimator Dashboard</h2><JobsTable jobs={jobs}/></div>
}
