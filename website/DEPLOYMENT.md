# Website Deployment Runbook (Cloudflare Pages)

This runbook is for the website-only launch of Dravik.

## 1. Prerequisites

- GitHub repository connected to Cloudflare account
- Supabase project created and initialized
- Domain (optional for first launch)

## 2. Supabase setup

1. Open Supabase SQL editor.
2. Run `supabase/setup_full.sql`.
3. Optional: run `supabase/seed_rich.sql`.
4. Optional admin policies: run `supabase/admin_import_policies.sql`.
5. In `Authentication -> URL Configuration`, add:
   - `http://localhost:5173`
   - `https://<your-project>.pages.dev`
   - `https://<your-custom-domain>` (when configured)

## 3. Cloudflare Pages project

1. Go to `Workers & Pages -> Create -> Pages`.
2. Connect GitHub repository.
3. Set build config:
   - Root directory: `website`
   - Build command: `npm run build`
   - Build output directory: `dist`
   - Node.js version: `20`

## 4. Environment variables (Pages)

Set for Production and Preview:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`
- `VITE_SUPABASE_PROJECT_ID` (optional)

Important:

- Do not add `SUPABASE_SERVICE_ROLE_KEY` to Pages.
- Do not add `VITE_SUPABASE_SERVICE_ROLE_KEY` anywhere in website env.

## 5. Deploy validation

After deployment:

1. Open `https://<your-project>.pages.dev`.
2. Validate core paths:
   - Home page
   - Explore/Guides pages
   - Auth page sign-in/sign-up
   - Dashboard for authenticated user
3. Validate browser console has no missing env warnings.
4. Validate Supabase reads succeed (destinations/categories/trips).

## 6. Custom domain

1. Add domain in Cloudflare Pages custom domains.
2. Ensure SSL mode is Full (strict).
3. Add custom domain to Supabase Auth URL allowlist.

## 7. Rollback strategy

- Keep previous successful Pages deployment as rollback target.
- Roll back through Pages deployment history if critical regression appears.

## 8. Release flow

- `main`: production
- `develop` (optional): preview/staging
- Protect `main` with required build checks.
