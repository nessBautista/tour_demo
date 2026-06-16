"""The three demo listings, as canonical Python data.

These mirror ``supabase/seed.sql`` one-to-one (same ids) so the in-memory
backend and a freshly seeded Supabase project look identical. They stage the
comparison demo: a big-yard suburban home, a no-yard downtown condo, and a quiet
fixer-upper.
"""

from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID

from .models import Listing

_SEEDED_AT = datetime(2026, 6, 9, tzinfo=timezone.utc)

SEED_LISTINGS: list[Listing] = [
    Listing(
        id=UUID("00000000-0000-0000-0000-000000000001"),
        created_at=_SEEDED_AT,
        address="412 Alder Court, Maple Grove",
        price=485_000,
        beds=3,
        baths=2.0,
        sqft=1640,
        headline="Sun-drenched corner lot with a big yard",
        facts={
            "light": "south-facing, large windows throughout",
            "yard": "generous fenced backyard, mature trees",
            "commute": "35 min to downtown",
            "quiet": "quiet cul-de-sac",
            "kitchen": "updated 2022",
            "parking": "2-car garage",
        },
    ),
    Listing(
        id=UUID("00000000-0000-0000-0000-000000000002"),
        created_at=_SEEDED_AT,
        address="88 Foundry Lane #4B, Riverside District",
        price=529_000,
        beds=2,
        baths=2.0,
        sqft=1180,
        headline="Modern condo, 12 minutes from downtown",
        facts={
            "light": "east-facing, morning light only",
            "yard": "shared rooftop terrace, no private outdoor space",
            "commute": "12 min to downtown, light rail at the corner",
            "quiet": "street-facing bedroom, some traffic hum",
            "kitchen": "open-plan, brand new appliances",
            "parking": "1 deeded garage spot",
        },
    ),
    Listing(
        id=UUID("00000000-0000-0000-0000-000000000003"),
        created_at=_SEEDED_AT,
        address="1735 Bellview Avenue, Old Town",
        price=449_000,
        beds=4,
        baths=1.5,
        sqft=1820,
        headline="Character craftsman on a quiet street, kitchen needs love",
        facts={
            "light": "west-facing, dim mornings",
            "yard": "small but private, room for a garden",
            "commute": "25 min to downtown",
            "quiet": "very quiet residential street",
            "kitchen": "original 1990s, renovation likely",
            "parking": "street parking only",
        },
    ),
]
