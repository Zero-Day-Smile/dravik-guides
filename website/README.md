# Dravik Website

This folder contains the website-only app for Dravik.
It is intended to ship first, with the mobile app added later against the same Supabase backend.

## Stack

- React 18 + TypeScript + Vite
- Tailwind + shadcn/ui
- Supabase (auth + data)
- Cloudflare Pages (recommended production host)

## Local development

1. Install dependencies:

```bash
cd website
npm install
```

2. Create env file:

```bash
cp .env.example .env
```

3. Set required values in `.env`:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`

4. Run dev server:

```bash
npm run dev
```

5. Build for production:

```bash
npm run build
```

## Environment safety

- `npm run check:env` validates required vars.
- Build fails if required Supabase vars are missing.
- `npm run preflight` runs env validation + production build + artifact sanity checks.
- Service-role keys are blocked by env validation (`SUPABASE_SERVICE_ROLE_KEY`, `VITE_SUPABASE_SERVICE_ROLE_KEY`).

## Supabase setup

- Run `supabase/setup_full.sql` in a new project for schema + policies + baseline data.
- Optional richer seed data: `supabase/seed_rich.sql`.
- Optional admin import policies: `supabase/admin_import_policies.sql`.

## Deploy (Cloudflare Pages)

Use the guide in `website/DEPLOYMENT.md`.

Quick settings:

- Build command: `npm run build`
- Build output directory: `dist`
- Root directory: `website`
- Node version: `20`
- Env vars: `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`, optional `VITE_SUPABASE_PROJECT_ID`

Repository deployment helpers:

- `.nvmrc` pins Node `20`
- `wrangler.toml` provides Pages CLI build output config

## Security checklist

Use `website/SECURITY_CHECKLIST.md` before sharing production links.

## Final go-live checklist

Use `website/PRE_HOSTING_FINAL_CHECKLIST.md` for a quick pre-hosting pass.
