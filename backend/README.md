# Listings backend

The data layer for the Tour Debrief Companion demo: house listings, a storage
abstraction with two interchangeable backends, and a CLI to exercise them.

This is **PR 1 (`backend/listings`)** — listings only. Later PRs add tours,
impressions, buyer memory, and events. See [`docs/SOLUTION.md`](../docs/SOLUTION.md)
for the whole problem and solution.

## Design

One rule: nothing above the storage layer knows where listings live.

```
cli  ──depends on──▶  ListingRepository (Protocol)  ◀──implements──┬─ InMemoryListingRepository  (default; tests, offline)
       │                          ▲                                └─ SupabaseListingRepository  (real backend)
       │                          │
       └──depends on──▶  ImageStore (Protocol)       ◀──implements──┬─ LocalImageStore           (default; tests, offline)
                                  │                                 └─ SupabaseImageStore        (Storage bucket)
                       build_backends(Settings)  ── picks a matching (repo, image store) pair from the environment
```

- **`models.py`** — `NewListing` (input) and `Listing` (stored: adds `id` + `created_at`). Validation lives in the types (`price > 0`, etc.). A listing carries an `image_url`, never image bytes.
- **`repository.py`** — the `ListingRepository` protocol and `ListingNotFoundError`. The seam everything else codes against.
- **`repositories/memory.py`** — in-memory backend, seeded with the 3 demo listings. No network, no secrets — what the tests and the offline CLI use.
- **`repositories/supabase.py`** — Supabase backend; takes an injected client.
- **`image_store.py`** — the same seam for photo bytes: `LocalImageStore` (returns a `file://` URL offline) and `SupabaseImageStore` (uploads to a public Storage bucket, returns the public URL).
- **`config.py`** — `Settings` (reads `SUPABASE_*`) and `build_backends`, the only place that picks concrete implementations. It returns a *pair* so the repo and image store always match, sharing one Supabase client.
- **`seed_data.py`** / **`supabase/seed.sql`** — the same 3 listings (same ids) in Python and SQL, so the two backends are interchangeable.

Why the abstraction for a small feature: it's what keeps the demo testable offline
and lets the real backend land without touching a line of caller code.

## Quickstart

Requires [uv](https://docs.astral.sh/uv/).

```bash
uv sync                  # create the venv, install deps
uv run pytest            # tests run fully offline (in-memory backend)

uv run tour-backend list                          # the 3 seeded listings
uv run tour-backend add --address "9 Oak St" \
    --price 510000 --beds 3 --baths 2 --fact yard=large
uv run tour-backend show <id>                     # one listing, with facts
uv run tour-backend set-image <id> ./photo.jpg    # upload + attach a photo
```

With no credentials set, the CLI uses the seeded in-memory backend (state lasts
for one command). The header line tells you which backend is active.

## Pointing at a real Supabase project

```bash
uv sync --extra supabase           # install the Supabase client
cp .env.example .env               # then fill in URL + anon key
# apply migrations + seed (Supabase SQL Editor, or `supabase db push`):
#   supabase/migrations/0001_listings.sql      # listings table
#   supabase/migrations/0002_listing_images.sql  # image_url + Storage bucket + policies
#   supabase/seed.sql                          # 3 demo listings
```

With `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env`, the same CLI commands now
read and write the hosted project — including `set-image`, which uploads to the
`listing-images` Storage bucket created by `0002`.

> Use the **anon/public** key (a long `eyJ…` JWT or an `sb_publishable_…` key) and the
> base project URL `https://<ref>.supabase.co` — not the management `sbp_…` token,
> and not a URL with a `/rest/v1/` path.

## Secrets

Only `.env.example` is committed; `.env` is gitignored. Use the **anon** key
(row-level-security scoped) — never the `service_role` key. The seed data is
fictional; there is no real MLS data in this repo.
