-- Tour Debrief Companion — per-dimension ratings for the fit score.
-- Adds the structured 0–100 ratings the comparison system scores against
-- (the `facts` column stays as human-readable prose). Idempotent.
--
-- Apply: `supabase db push` (CLI) or paste into the dashboard SQL Editor.

-- ── The ratings column ────────────────────────────────────────────────
-- jsonb of { dimension: 0–100 } for the scored vocabulary
-- (yard · commute · quiet · kitchen · light · parking). `budget` is derived
-- from price app-side and `note` is unscored, so neither is stored.
alter table listings add column if not exists ratings jsonb not null default '{}'::jsonb;

-- ── Backfill the 3 demo listings (fixed ids) ──────────────────────────
-- So an already-seeded project gets rated by running just this migration.
-- Ratings are consistent with each listing's `facts`. Re-runnable.
update listings set ratings = '{"yard":100,"commute":40,"quiet":100,"kitchen":90,"light":95,"parking":90}'::jsonb
  where id = '00000000-0000-0000-0000-000000000001';
update listings set ratings = '{"yard":5,"commute":100,"quiet":20,"kitchen":90,"light":50,"parking":75}'::jsonb
  where id = '00000000-0000-0000-0000-000000000002';
update listings set ratings = '{"yard":50,"commute":65,"quiet":100,"kitchen":15,"light":30,"parking":25}'::jsonb
  where id = '00000000-0000-0000-0000-000000000003';
