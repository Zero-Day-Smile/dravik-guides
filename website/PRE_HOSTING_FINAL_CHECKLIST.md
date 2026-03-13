# Pre-Hosting Final Checklist (Website)

Use this right before making the website public.

## 1. Local build and env

- [ ] Run `npm run preflight` in `website`.
- [ ] (Optional) Run `npm run check:env` in `website`.
- [ ] (Optional) Run `npm run build` in `website`.
- [ ] Confirm required env vars are set:
  - [ ] `VITE_SUPABASE_URL`
  - [ ] `VITE_SUPABASE_PUBLISHABLE_KEY`
- [ ] Confirm no service-role keys are set in website env:
  - [ ] `SUPABASE_SERVICE_ROLE_KEY` is NOT set
  - [ ] `VITE_SUPABASE_SERVICE_ROLE_KEY` is NOT set

## 2. Supabase security

- [ ] RLS enabled on all app tables.
- [ ] Policies reviewed for user-owned data (`auth.uid() = user_id` where applicable).
- [ ] Admin role checks use only `app_metadata.role`.
- [ ] `supabase/admin_import_policies.sql` applied (if admin import is used).
- [ ] `supabase/admin_import_audit.sql` applied (if admin import audit is used).

## 3. Supabase auth URL config

In Supabase `Authentication -> URL Configuration`:

- [ ] `http://localhost:5173` added.
- [ ] `https://<your-pages-project>.pages.dev` added.
- [ ] `https://<your-custom-domain>` added (if using custom domain).
- [ ] Remove unused/old callback URLs.

## 4. Cloudflare Pages config

- [ ] Root directory: `website`
- [ ] Build command: `npm run build`
- [ ] Output directory: `dist`
- [ ] Node version: `20`
- [ ] Production env vars added:
  - [ ] `VITE_SUPABASE_URL`
  - [ ] `VITE_SUPABASE_PUBLISHABLE_KEY`
- [ ] Preview env vars added (same required vars)

## 5. Smoke test after deploy

- [ ] Home page loads.
- [ ] Explore/Guides pages load data.
- [ ] Sign up works.
- [ ] Sign in works.
- [ ] Dashboard loads for authenticated user.
- [ ] Sign out works.
- [ ] Browser console has no auth/env runtime errors.

## 6. Final hardening

- [ ] `.env` is ignored and not committed.
- [ ] `.gitignore` includes certs/keys/secrets/deploy-state patterns.
- [ ] Error monitoring enabled (Sentry or equivalent).
- [ ] Rollback path confirmed in Pages deployment history.

## 7. Go-live gate

Go live only if all boxes above are complete.

If any critical item fails (auth, RLS, secrets), pause launch and fix before sharing URL.
