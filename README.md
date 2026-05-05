# Hail Surgeon Estimate Rewrite Portal (Phase 1)

Next.js + TypeScript + Supabase implementation with role-based dashboards and SQL migrations for secure RLS-first architecture.

## Run locally
1. Create `.env.local` with:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (optional for server admin actions)
- `DATABASE_URL` (optional, for direct SQL tooling)
- `SUPABASE_PROJECT_REF` (optional)
2. `npm install`
3. Apply SQL migration `supabase/migrations/20260505_phase1.sql` in Supabase SQL editor.
4. (Optional) Apply `supabase/seed/phase1_demo.sql` after replacing placeholder user UUIDs.
5. `npm run dev`

## Deploy
- Deploy to Vercel with the same env vars set in project settings.
- Run migration SQL in Supabase production project before traffic.

## Security notes
- RLS policies implemented for role-based job/file access.
- Buckets are private and intended to be accessed with signed URLs after access checks.
- Financial fields exist in DB for admin only and are omitted from customer/estimator dashboard selects.
