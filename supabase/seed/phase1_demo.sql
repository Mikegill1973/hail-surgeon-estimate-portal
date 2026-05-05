-- Replace UUIDs with real auth.users ids in your environment.
insert into public.customer_companies (id, company_name, body_shop_name, body_shop_city, body_shop_state, main_contact_name, main_contact_email)
values ('11111111-1111-1111-1111-111111111111','Demo Auto Group','Demo Body Shop','Dallas','TX','Demo Contact','demo@example.com')
on conflict do nothing;

insert into public.profiles (id,email,full_name,role,company_id) values
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','admin@demo.local','Admin User','admin',null),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','estimator@demo.local','Estimator User','estimator',null)
on conflict do nothing;

insert into public.estimate_rewrite_jobs (id,company_id,status,priority,rewrite_type,estimate_type,claim_number,vin,insurance_company_name,customer_contact_name)
values ('22222222-2222-2222-2222-222222222222','11111111-1111-1111-1111-111111111111','New Upload','Standard','Full Rewrite','Original Estimate','CLM-1001','1HGBH41JXMN109186','Sample Insurance','Jane Doe')
on conflict do nothing;
