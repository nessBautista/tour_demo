-- Demo seed — 3 curated listings (no real MLS data). Mirrors
-- src/tour_backend/seed_data.py exactly (same ids) so the in-memory backend and
-- a seeded Supabase project are interchangeable.
--
-- Hosted project: paste into the dashboard SQL Editor after the migration.
-- (Supabase only auto-runs seed.sql on a local `supabase db reset`.)

-- image_url is left null; attach photos after seeding with `tour-backend set-image`.
insert into listings (id, address, price, beds, baths, sqft, headline, facts) values
  (
    '00000000-0000-0000-0000-000000000001',
    '412 Alder Court, Maple Grove',
    485000, 3, 2.0, 1640,
    'Sun-drenched corner lot with a big yard',
    '{
      "light": "south-facing, large windows throughout",
      "yard": "generous fenced backyard, mature trees",
      "commute": "35 min to downtown",
      "quiet": "quiet cul-de-sac",
      "kitchen": "updated 2022",
      "parking": "2-car garage"
    }'::jsonb
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    '88 Foundry Lane #4B, Riverside District',
    529000, 2, 2.0, 1180,
    'Modern condo, 12 minutes from downtown',
    '{
      "light": "east-facing, morning light only",
      "yard": "shared rooftop terrace, no private outdoor space",
      "commute": "12 min to downtown, light rail at the corner",
      "quiet": "street-facing bedroom, some traffic hum",
      "kitchen": "open-plan, brand new appliances",
      "parking": "1 deeded garage spot"
    }'::jsonb
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    '1735 Bellview Avenue, Old Town',
    449000, 4, 1.5, 1820,
    'Character craftsman on a quiet street, kitchen needs love',
    '{
      "light": "west-facing, dim mornings",
      "yard": "small but private, room for a garden",
      "commute": "25 min to downtown",
      "quiet": "very quiet residential street",
      "kitchen": "original 1990s, renovation likely",
      "parking": "street parking only"
    }'::jsonb
  );
