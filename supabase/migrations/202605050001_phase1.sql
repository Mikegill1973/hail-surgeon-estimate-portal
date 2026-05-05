create extension if not exists pgcrypto;
create type app_role as enum ('admin','qc_manager','estimator','customer');
create type job_status as enum ('New Upload','Assigned','Started','Waiting on Missing Info','Customer Uploaded Missing Info','Rewrite Completed','QC Review','Revision Needed','Approved / Customer Ready','Cancelled');
create table public.customer_companies(id uuid primary key default gen_random_uuid(),name text not null unique,created_at timestamptz default now());
create table public.profiles(id uuid primary key references auth.users(id) on delete cascade,role app_role not null,full_name text,company_id uuid references public.customer_companies(id),created_at timestamptz default now());
create table public.estimate_rewrite_jobs(
id uuid primary key default gen_random_uuid(),customer_company_id uuid not null references public.customer_companies(id),assigned_estimator_id uuid references public.profiles(id),created_by uuid not null references public.profiles(id),status job_status not null default 'New Upload',priority text default 'Normal',claim_number text,vin text,insurance_company text,date_received date default current_date,qc_status text default 'Pending',customer_facing_notes text,internal_admin_notes text,estimator_notes text,
customer_price_charged numeric,amount_charged_to_customer numeric,estimator_pay_type text,estimator_pay_amount numeric,processing_fee numeric,other_job_cost numeric,gross_profit numeric,invoice_status text,payment_status text,payment_processor text,payment_link text,processor_transaction_id text,payroll_status text,billing_notes text,payroll_notes text,
created_at timestamptz default now(),updated_at timestamptz default now());
create table public.job_files(id uuid primary key default gen_random_uuid(),job_id uuid not null references public.estimate_rewrite_jobs(id) on delete cascade,file_type text not null check(file_type in ('original_estimate','customer_photo','supporting_document','completed_rewrite')),bucket_name text not null,storage_path text not null,uploaded_by uuid not null references public.profiles(id),created_at timestamptz default now());
create table public.job_activity(id bigint generated always as identity primary key,job_id uuid not null references public.estimate_rewrite_jobs(id) on delete cascade,actor_id uuid not null references public.profiles(id),activity_type text not null,notes text,created_at timestamptz default now());
create index on public.estimate_rewrite_jobs(status); create index on public.estimate_rewrite_jobs(customer_company_id); create index on public.estimate_rewrite_jobs(assigned_estimator_id);
alter table public.customer_companies enable row level security; alter table public.profiles enable row level security; alter table public.estimate_rewrite_jobs enable row level security; alter table public.job_files enable row level security; alter table public.job_activity enable row level security;
create function public.current_role() returns app_role language sql stable as $$ select role from public.profiles where id = auth.uid() $$;
create function public.current_company() returns uuid language sql stable as $$ select company_id from public.profiles where id = auth.uid() $$;
create policy admin_all_jobs on public.estimate_rewrite_jobs for all using (public.current_role()='admin') with check (public.current_role()='admin');
create policy customer_company_jobs on public.estimate_rewrite_jobs for select using (public.current_role()='customer' and customer_company_id=public.current_company());
create policy estimator_assigned_jobs on public.estimate_rewrite_jobs for select using (public.current_role()='estimator' and assigned_estimator_id=auth.uid());
create policy estimator_update_jobs on public.estimate_rewrite_jobs for update using (public.current_role()='estimator' and assigned_estimator_id=auth.uid()) with check (public.current_role()='estimator' and assigned_estimator_id=auth.uid());
create policy qc_jobs on public.estimate_rewrite_jobs for select using (public.current_role()='qc_manager' and status in ('QC Review','Revision Needed','Approved / Customer Ready'));
create policy qc_update on public.estimate_rewrite_jobs for update using (public.current_role() in ('qc_manager','admin')) with check (public.current_role() in ('qc_manager','admin'));
create policy company_profiles on public.profiles for select using (id=auth.uid() or public.current_role()='admin');
create policy files_visibility on public.job_files for select using (exists(select 1 from public.estimate_rewrite_jobs j where j.id=job_id and ((public.current_role()='admin') or (public.current_role()='customer' and j.customer_company_id=public.current_company() and not (file_type='completed_rewrite' and j.status<>'Approved / Customer Ready')) or (public.current_role()='estimator' and j.assigned_estimator_id=auth.uid()) or (public.current_role()='qc_manager' and j.status in ('QC Review','Revision Needed','Approved / Customer Ready')))));
create policy files_insert on public.job_files for insert with check (public.current_role() in ('admin','customer','estimator','qc_manager'));
create policy activity_visibility on public.job_activity for select using (public.current_role()='admin' or exists(select 1 from public.estimate_rewrite_jobs j where j.id=job_id and (j.customer_company_id=public.current_company() or j.assigned_estimator_id=auth.uid() or public.current_role()='qc_manager')));
create or replace function public.set_updated_at() returns trigger language plpgsql as $$begin new.updated_at=now(); return new; end$$;
create trigger trg_jobs_updated before update on public.estimate_rewrite_jobs for each row execute function public.set_updated_at();
insert into storage.buckets(id,name,public) values ('original-estimates','original-estimates',false),('customer-photos','customer-photos',false),('supporting-documents','supporting-documents',false),('completed-rewrites','completed-rewrites',false) on conflict do nothing;
create policy "storage read" on storage.objects for select using (bucket_id in ('original-estimates','customer-photos','supporting-documents','completed-rewrites'));
create view public.jobs_secure_view as
select j.id,j.status,j.claim_number,j.vin,j.insurance_company,j.priority,j.date_received,j.qc_status,j.customer_facing_notes,
case when public.current_role() in ('admin','qc_manager','estimator') then j.estimator_notes else null end estimator_notes,
cc.name as customer_company_name,p.full_name as assigned_estimator_name,j.created_at
from public.estimate_rewrite_jobs j left join public.customer_companies cc on cc.id=j.customer_company_id left join public.profiles p on p.id=j.assigned_estimator_id
where (public.current_role()='admin') or (public.current_role()='customer' and j.customer_company_id=public.current_company()) or (public.current_role()='estimator' and j.assigned_estimator_id=auth.uid()) or (public.current_role()='qc_manager' and j.status in ('QC Review','Revision Needed','Approved / Customer Ready'));
