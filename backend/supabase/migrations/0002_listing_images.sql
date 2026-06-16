-- Tour Debrief Companion — listing images via Supabase Storage.
-- Adds: a public image bucket, the policies the anon key needs to upload, and an
-- update policy so a listing's image_url can be set after creation.
--
-- Idempotent. Safe to run on a project created before image_url existed (it
-- reconciles the column) and on a fresh project (the guards no-op).
--
-- Apply: `supabase db push` (CLI) or paste into the dashboard SQL Editor.

-- ── Reconcile the column (no-op on fresh projects) ────────────────────
alter table listings drop column if exists image_name;
alter table listings add  column if not exists image_url text;

-- ── Let the anon role set a listing's image after creation ────────────
drop policy if exists "anon_update" on listings;
create policy "anon_update" on listings for update to anon using (true) with check (true);

-- ── Public bucket for listing photos ──────────────────────────────────
-- public = true serves objects without auth (read). DEMO-ONLY posture, like the
-- table policies: anyone with the anon key can upload here.
insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true)
on conflict (id) do nothing;

drop policy if exists "listing_images_insert" on storage.objects;
create policy "listing_images_insert" on storage.objects
  for insert to anon with check (bucket_id = 'listing-images');

-- Public buckets are already world-readable; this select policy makes anon reads
-- explicit and mirrors the table's posture.
drop policy if exists "listing_images_select" on storage.objects;
create policy "listing_images_select" on storage.objects
  for select to anon using (bucket_id = 'listing-images');
