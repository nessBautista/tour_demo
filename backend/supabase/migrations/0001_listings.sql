-- Tour Debrief Companion — listings table.
-- This PR covers listings only; later PRs add tours, impressions, memory, events.
--
-- Apply: `supabase db push` (CLI) or paste into the dashboard SQL Editor.

create table listings (
  id          uuid primary key default gen_random_uuid(),
  address     text    not null,
  price       integer not null check (price > 0),
  beds        integer not null check (beds >= 0),
  baths       numeric(3, 1) not null check (baths >= 0),
  sqft        integer check (sqft > 0),
  headline    text,
  facts       jsonb   not null default '{}'::jsonb,
  image_url   text,  -- public Supabase Storage URL; set via `tour-backend set-image`
  created_at  timestamptz not null default now()
);

-- Row level security: enabled, with permissive anon policies.
-- DEMO-ONLY posture — anyone with the URL + anon key can read all rows and
-- insert. Acceptable for single-user seeded demo data; production would scope
-- policies to auth.uid(). `TO anon` is deliberate; never drop the role clause.
alter table listings enable row level security;

create policy "anon_select" on listings for select to anon using (true);
create policy "anon_insert" on listings for insert to anon with check (true);
