-- Dravik app frontend tables for Supabase-backed mobile webview
-- Safe to run multiple times; objects are created if they do not exist.

create extension if not exists pgcrypto;

create table if not exists public.trails (
  id text primary key,
  name text not null,
  location text not null,
  country text not null,
  difficulty text not null check (difficulty in ('easy', 'moderate', 'hard', 'expert')),
  distance numeric not null,
  elevation integer not null,
  duration text not null,
  rating numeric not null,
  lat double precision not null,
  lng double precision not null,
  description text not null,
  image text not null,
  best_season text not null,
  highlights jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.guides (
  id text primary key,
  title text not null,
  category text not null,
  excerpt text not null,
  read_time text not null,
  difficulty text not null,
  icon text not null,
  content text not null,
  sections jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.countries (
  id text primary key,
  name text not null,
  code text not null,
  capital text not null,
  region text not null,
  population bigint not null,
  languages jsonb not null default '[]'::jsonb,
  currency text not null,
  timezone text not null,
  visa_required boolean not null default false,
  safety_rating numeric not null,
  best_trekking_season text not null,
  climate text not null,
  emergency_number text not null,
  description text not null,
  image text not null,
  highlights jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.trips (
  id text primary key,
  user_id uuid references auth.users(id) on delete set null,
  name text not null,
  destination text not null,
  start_date date not null,
  end_date date not null,
  status text not null check (status in ('planning', 'upcoming', 'active', 'completed')),
  trails jsonb not null default '[]'::jsonb,
  notes text not null default '',
  estimated_budget numeric,
  members jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.gear_items (
  id text primary key,
  user_id uuid references auth.users(id) on delete set null,
  name text not null,
  category text not null,
  weight integer not null,
  packed boolean not null default false,
  essential boolean not null default false,
  condition text check (condition in ('new', 'good', 'worn', 'damaged')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.achievements (
  id text primary key,
  user_id uuid references auth.users(id) on delete set null,
  name text not null,
  description text not null,
  icon text not null,
  unlocked boolean not null default false,
  unlocked_date date,
  criteria text not null,
  points integer not null,
  rarity text not null check (rarity in ('common', 'rare', 'epic', 'legendary')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.activity_logs (
  id text primary key,
  user_id uuid references auth.users(id) on delete set null,
  date date not null,
  type text not null check (type in ('trek', 'hike', 'climb', 'camp')),
  trail_id text,
  distance numeric not null,
  elevation integer not null,
  duration integer not null,
  calories integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trails_set_updated_at on public.trails;
create trigger trails_set_updated_at before update on public.trails for each row execute function public.set_updated_at();
drop trigger if exists guides_set_updated_at on public.guides;
create trigger guides_set_updated_at before update on public.guides for each row execute function public.set_updated_at();
drop trigger if exists countries_set_updated_at on public.countries;
create trigger countries_set_updated_at before update on public.countries for each row execute function public.set_updated_at();
drop trigger if exists trips_set_updated_at on public.trips;
create trigger trips_set_updated_at before update on public.trips for each row execute function public.set_updated_at();
drop trigger if exists gear_items_set_updated_at on public.gear_items;
create trigger gear_items_set_updated_at before update on public.gear_items for each row execute function public.set_updated_at();
drop trigger if exists achievements_set_updated_at on public.achievements;
create trigger achievements_set_updated_at before update on public.achievements for each row execute function public.set_updated_at();
drop trigger if exists activity_logs_set_updated_at on public.activity_logs;
create trigger activity_logs_set_updated_at before update on public.activity_logs for each row execute function public.set_updated_at();

alter table public.trails enable row level security;
alter table public.guides enable row level security;
alter table public.countries enable row level security;
alter table public.trips enable row level security;
alter table public.gear_items enable row level security;
alter table public.achievements enable row level security;
alter table public.activity_logs enable row level security;

-- Public read-only catalog data.
drop policy if exists "public read trails" on public.trails;
create policy "public read trails" on public.trails for select using (true);
drop policy if exists "public read guides" on public.guides;
create policy "public read guides" on public.guides for select using (true);
drop policy if exists "public read countries" on public.countries;
create policy "public read countries" on public.countries for select using (true);

-- Per-user ownership for mutable records.
drop policy if exists "users read own trips" on public.trips;
create policy "users read own trips" on public.trips for select using (auth.uid() = user_id);
drop policy if exists "users write own trips" on public.trips;
create policy "users write own trips" on public.trips for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "users read own gear" on public.gear_items;
create policy "users read own gear" on public.gear_items for select using (auth.uid() = user_id);
drop policy if exists "users write own gear" on public.gear_items;
create policy "users write own gear" on public.gear_items for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "users read own achievements" on public.achievements;
create policy "users read own achievements" on public.achievements for select using (auth.uid() = user_id);
drop policy if exists "users write own achievements" on public.achievements;
create policy "users write own achievements" on public.achievements for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "users read own activity_logs" on public.activity_logs;
create policy "users read own activity_logs" on public.activity_logs for select using (auth.uid() = user_id);
drop policy if exists "users write own activity_logs" on public.activity_logs;
create policy "users write own activity_logs" on public.activity_logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_trips_user_id on public.trips(user_id);
create index if not exists idx_gear_items_user_id on public.gear_items(user_id);
create index if not exists idx_achievements_user_id on public.achievements(user_id);
create index if not exists idx_activity_logs_user_id on public.activity_logs(user_id);
