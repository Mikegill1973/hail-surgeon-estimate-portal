create extension if not exists pgcrypto;

create type public.app_role as enum ('admin','qc_manager','estimator','customer');

create table if not exists public.customer_companies (
  id uuid primary key default gen_random_uuid(), company_name text not null, body_shop_name text, body_shop_address text, body_shop_city text, body_shop_state text, body_shop_zip text,
  main_contact_name text, main_contact_email text, main_contact_phone text, active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null, full_name text, role public.app_role not null, company_id uuid references public.customer_companies(id), active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create sequence if not exists public.job_number_seq;

create table if not exists public.estimate_rewrite_jobs (
 id uuid primary key default gen_random_uuid(), job_number text unique not null default ('HS-ER-' || lpad(nextval('public.job_number_seq')::text, 6, '0')),
 company_id uuid not null references public.customer_companies(id), status text not null default 'New Upload', priority text not null default 'Standard', rewrite_type text not null default 'Full Rewrite', estimate_type text not null default 'Original Estimate', date_received timestamptz not null default now(), due_date timestamptz,
 assigned_estimator_id uuid references public.profiles(id), assigned_by uuid references public.profiles(id), date_assigned timestamptz,
 estimator_started boolean not null default false,start_time timestamptz,estimator_completed boolean not null default false,completed_time timestamptz,total_turnaround_minutes integer,
 qc_status text not null default 'Not Reviewed',qc_reviewed_by uuid references public.profiles(id),qc_review_date timestamptz,qc_notes text,revision_needed boolean not null default false,revision_request text,customer_download_ready boolean not null default false,approved_released_date timestamptz,released_by uuid references public.profiles(id),
 customer_contact_name text, customer_contact_email text, customer_contact_phone text, vehicle_owner_name text, ro_number text, stock_number text, vin text, vehicle_year text, vehicle_make text, vehicle_model text, vehicle_trim text, vehicle_color text, mileage text, insurance_company_name text, claim_number text, policy_number text, estimate_number text, supplement_number text, loss_date date, inspection_date date, original_estimate_platform text,
 original_estimate_amount numeric, final_estimate_amount numeric, increase_found numeric, deductible numeric, adjuster_name text, adjuster_email text, adjuster_phone text,
 missing_photos_needed boolean not null default false, missing_information_needed boolean not null default false, missing_info_request text, missing_info_requested_date timestamptz, missing_info_received_date timestamptz, customer_uploaded_missing_info boolean not null default false, customer_upload_complete boolean not null default false,
 customer_notes text, customer_facing_notes text, estimator_notes text, internal_admin_notes text,
 customer_price_charged numeric, amount_charged_to_customer numeric, estimator_pay_type text, estimator_pay_amount numeric, processing_fee numeric, other_job_cost numeric, gross_profit numeric, invoice_status text, payment_status text, payment_processor text, payment_link text, processor_transaction_id text, payroll_status text, billing_notes text, payroll_notes text,
 created_by uuid references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.job_files (
 id uuid primary key default gen_random_uuid(), job_id uuid not null references public.estimate_rewrite_jobs(id) on delete cascade, company_id uuid not null references public.customer_companies(id), uploaded_by uuid references public.profiles(id),
 file_type text not null, bucket text not null, storage_path text not null, original_file_name text not null, mime_type text not null, file_size bigint,
 visible_to_customer boolean not null default false, visible_to_estimator boolean not null default false, visible_to_admin boolean not null default true,
 created_at timestamptz not null default now()
);

create table if not exists public.job_activity (
 id uuid primary key default gen_random_uuid(), job_id uuid not null references public.estimate_rewrite_jobs(id) on delete cascade, user_id uuid references public.profiles(id), action text not null, old_value text, new_value text, notes text, created_at timestamptz not null default now()
);

create or replace function public.current_role() returns public.app_role language sql stable as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.current_company_id() returns uuid language sql stable as $$
  select company_id from public.profiles where id = auth.uid()
$$;

alter table public.profiles enable row level security;
alter table public.estimate_rewrite_jobs enable row level security;
alter table public.job_files enable row level security;
alter table public.job_activity enable row level security;
alter table public.customer_companies enable row level security;

create policy admin_all_profiles on public.profiles for all using (public.current_role()='admin') with check (public.current_role()='admin');
create policy self_profile on public.profiles for select using (id=auth.uid());

create policy jobs_admin_all on public.estimate_rewrite_jobs for all using (public.current_role()='admin') with check (public.current_role()='admin');
create policy jobs_qc_select on public.estimate_rewrite_jobs for select using (public.current_role() in ('qc_manager','admin'));
create policy jobs_customer_select on public.estimate_rewrite_jobs for select using (public.current_role()='customer' and company_id=public.current_company_id());
create policy jobs_estimator_select on public.estimate_rewrite_jobs for select using (public.current_role()='estimator' and assigned_estimator_id=auth.uid());
create policy jobs_customer_insert on public.estimate_rewrite_jobs for insert with check (public.current_role()='customer' and company_id=public.current_company_id());
create policy jobs_customer_update_limited on public.estimate_rewrite_jobs for update using (public.current_role()='customer' and company_id=public.current_company_id()) with check (public.current_role()='customer' and company_id=public.current_company_id());
create policy jobs_estimator_update_limited on public.estimate_rewrite_jobs for update using (public.current_role()='estimator' and assigned_estimator_id=auth.uid()) with check (public.current_role()='estimator' and assigned_estimator_id=auth.uid());

create policy files_admin_all on public.job_files for all using (public.current_role()='admin') with check (public.current_role()='admin');
create policy files_qc_select on public.job_files for select using (public.current_role() in ('qc_manager','admin'));
create policy files_customer_select on public.job_files for select using (public.current_role()='customer' and company_id=public.current_company_id() and (file_type <> 'completed_rewrite_pdf' or exists(select 1 from public.estimate_rewrite_jobs j where j.id=job_id and j.customer_download_ready=true and j.qc_status in ('Approved','Customer Ready'))));
create policy files_estimator_select on public.job_files for select using (public.current_role()='estimator' and visible_to_estimator=true and exists(select 1 from public.estimate_rewrite_jobs j where j.id=job_id and j.assigned_estimator_id=auth.uid()));
create policy files_customer_insert on public.job_files for insert with check (public.current_role()='customer' and company_id=public.current_company_id());
create policy files_estimator_insert on public.job_files for insert with check (public.current_role()='estimator' and exists(select 1 from public.estimate_rewrite_jobs j where j.id=job_id and j.assigned_estimator_id=auth.uid()));

create policy activity_admin_qc_select on public.job_activity for select using (public.current_role() in ('admin','qc_manager'));
create policy activity_customer_select on public.job_activity for select using (public.current_role()='customer' and exists(select 1 from public.estimate_rewrite_jobs j where j.id=job_id and j.company_id=public.current_company_id()));
create policy activity_estimator_select on public.job_activity for select using (public.current_role()='estimator' and exists(select 1 from public.estimate_rewrite_jobs j where j.id=job_id and j.assigned_estimator_id=auth.uid()));
create policy activity_insert on public.job_activity for insert with check (auth.uid()=user_id);

create index if not exists idx_jobs_company_id on public.estimate_rewrite_jobs(company_id);
create index if not exists idx_jobs_assigned_estimator_id on public.estimate_rewrite_jobs(assigned_estimator_id);
create index if not exists idx_jobs_status on public.estimate_rewrite_jobs(status);
create index if not exists idx_jobs_qc_status on public.estimate_rewrite_jobs(qc_status);
create index if not exists idx_jobs_claim_number on public.estimate_rewrite_jobs(claim_number);
create index if not exists idx_jobs_vin on public.estimate_rewrite_jobs(vin);
create index if not exists idx_jobs_insurance_company_name on public.estimate_rewrite_jobs(insurance_company_name);
create index if not exists idx_jobs_date_received on public.estimate_rewrite_jobs(date_received);
create index if not exists idx_job_files_job_id on public.job_files(job_id);
create index if not exists idx_job_files_company_id on public.job_files(company_id);

insert into storage.buckets (id, name, public) values
 ('original-estimates','original-estimates',false),
 ('customer-photos','customer-photos',false),
 ('supporting-documents','supporting-documents',false),
 ('completed-rewrites','completed-rewrites',false)
on conflict (id) do nothing;

create policy storage_admin_all on storage.objects for all using (bucket_id in ('original-estimates','customer-photos','supporting-documents','completed-rewrites') and public.current_role()='admin') with check (bucket_id in ('original-estimates','customer-photos','supporting-documents','completed-rewrites') and public.current_role()='admin');
create policy storage_qc_read on storage.objects for select using (bucket_id in ('original-estimates','customer-photos','supporting-documents','completed-rewrites') and public.current_role() in ('qc_manager','admin'));
create policy storage_customer_access on storage.objects for select using (public.current_role()='customer' and exists(select 1 from public.job_files jf join public.estimate_rewrite_jobs j on j.id=jf.job_id where jf.bucket=bucket_id and jf.storage_path=name and j.company_id=public.current_company_id() and (jf.file_type<>'completed_rewrite_pdf' or (j.customer_download_ready=true and j.qc_status in ('Approved','Customer Ready')))));
create policy storage_customer_upload on storage.objects for insert with check (public.current_role()='customer' and bucket_id in ('original-estimates','customer-photos','supporting-documents'));
create policy storage_estimator_access on storage.objects for select using (public.current_role()='estimator' and exists(select 1 from public.job_files jf join public.estimate_rewrite_jobs j on j.id=jf.job_id where jf.bucket=bucket_id and jf.storage_path=name and j.assigned_estimator_id=auth.uid()));
create policy storage_estimator_upload_completed on storage.objects for insert with check (public.current_role()='estimator' and bucket_id='completed-rewrites');
