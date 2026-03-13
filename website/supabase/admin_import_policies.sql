-- Apply this once to allow admin users to import categories/destinations from the web app.
-- Requires users to have app_metadata.role = 'admin' in Supabase Auth.

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  -- Only trust app_metadata for authorization decisions.
  -- user_metadata can be user-controlled and must not grant admin access.
  SELECT COALESCE((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$;

DROP POLICY IF EXISTS "Admins can insert categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can update categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can insert destinations" ON public.destinations;
DROP POLICY IF EXISTS "Admins can update destinations" ON public.destinations;

CREATE POLICY "Admins can insert categories"
ON public.categories
FOR INSERT
WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update categories"
ON public.categories
FOR UPDATE
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "Admins can insert destinations"
ON public.destinations
FOR INSERT
WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update destinations"
ON public.destinations
FOR UPDATE
USING (public.is_admin())
WITH CHECK (public.is_admin());
