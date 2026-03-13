-- Admin import audit trail for website upload/import flow.
-- Run this once in Supabase SQL editor.

CREATE TABLE IF NOT EXISTS public.import_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  actor_email TEXT,
  source_format TEXT NOT NULL DEFAULT 'csv' CHECK (source_format IN ('csv', 'json')),
  status TEXT NOT NULL CHECK (status IN ('success', 'failed')),
  total_rows INTEGER NOT NULL DEFAULT 0,
  categories_created INTEGER NOT NULL DEFAULT 0,
  destinations_processed INTEGER NOT NULL DEFAULT 0,
  destinations_created INTEGER NOT NULL DEFAULT 0,
  destinations_updated INTEGER NOT NULL DEFAULT 0,
  warnings_count INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.import_runs ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  -- Only trust app_metadata for authorization decisions.
  -- user_metadata can be user-controlled and must not grant admin access.
  SELECT COALESCE((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$;

DROP POLICY IF EXISTS "Admins can insert import runs" ON public.import_runs;
DROP POLICY IF EXISTS "Admins can view import runs" ON public.import_runs;

CREATE POLICY "Admins can insert import runs"
ON public.import_runs
FOR INSERT
WITH CHECK (public.is_admin());

CREATE POLICY "Admins can view import runs"
ON public.import_runs
FOR SELECT
USING (public.is_admin());

CREATE INDEX IF NOT EXISTS idx_import_runs_created_at ON public.import_runs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_import_runs_actor_user_id ON public.import_runs(actor_user_id);
