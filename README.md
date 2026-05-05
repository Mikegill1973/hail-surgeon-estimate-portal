# Hail Surgeon Estimate Rewrite Portal (Phase 1)

## Setup
1. Install dependencies: `npm install`
2. Configure env vars:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (optional for server actions)
- `DATABASE_URL` (optional)
- `SUPABASE_PROJECT_REF` (optional)
3. Run dev server: `npm run dev`

## Supabase migrations
- Put SQL in `supabase/migrations`.
- Apply with Supabase CLI: `supabase db push`.

## Deployment
- Deploy to Vercel.
- Set same env vars in project settings.
- Ensure Supabase RLS is enabled and migration applied.

## Security notes
- No secrets hard-coded.
- Buckets are private.
- RLS scopes data by role/company/assignment.
- Financial fields are only on base table; dashboard uses `jobs_secure_view` without financial columns.

## Phase 1 workflow
Customer upload -> Admin assign -> Estimator start/complete -> QC approve/revise -> Customer download after Approved.
