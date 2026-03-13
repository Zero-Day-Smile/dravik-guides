# Website Security Checklist (Pre-Launch)

Use this checklist before sharing the public website URL.

## Supabase

- [ ] RLS enabled on all app tables (`categories`, `destinations`, `profiles`, `reviews`, `saved_destinations`, `trips`).
- [ ] Public read policies only where intended.
- [ ] User-owned write policies use `auth.uid() = user_id` checks.
- [ ] Admin-only import policies applied only if needed.
- [ ] Auth URL allowlist includes only trusted origins.
- [ ] No test/demo users with elevated roles left active.

## Secrets and keys

- [ ] Website env contains only publishable key (`VITE_SUPABASE_PUBLISHABLE_KEY`).
- [ ] No service-role keys in repo, Pages vars, or frontend code.
- [ ] `.env` is not committed.

## Website app

- [ ] Build passes with `npm run build`.
- [ ] Env validation passes with `npm run check:env`.
- [ ] Auth flows tested (sign-up, sign-in, sign-out, session restore).
- [ ] Route guards tested for dashboard/admin pages.

## Production operations

- [ ] Error monitoring enabled (Sentry or equivalent).
- [ ] Preview deployments enabled for non-main branches.
- [ ] Rollback path verified in Cloudflare Pages deployment history.
- [ ] Basic incident contact/process documented.

## Optional hardening

- [ ] Edge Functions for sensitive operations (risk scoring, SOS, admin imports).
- [ ] Rate limits on write-heavy endpoints.
- [ ] Abuse monitoring for auth and form endpoints.
