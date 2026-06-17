"""Domain models for a house listing.

``NewListing`` is the input shape (what a caller provides to create one);
``Listing`` is the stored shape (it adds the server-assigned ``id`` and
``created_at``). Modelling them separately keeps "you can't set the id by hand"
true at the type level rather than by convention.
"""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

# Free-form, demo-only attributes (e.g. {"yard": "large, fenced"}). Descriptive
# prose for humans; the comparison system reads the structured `Ratings` below.
Facts = dict[str, str]


class Ratings(BaseModel):
    """0–100 rating per scored dimension — the home side of the fit score.

    The closed comparison vocabulary, minus two: `budget` is derived from `price`
    app-side, and `note` is unscored — so neither is stored here. Higher always
    means "more of the trait" (more yard, shorter commute, quieter, …).
    """

    yard: int = Field(default=0, ge=0, le=100)
    commute: int = Field(default=0, ge=0, le=100)
    quiet: int = Field(default=0, ge=0, le=100)
    kitchen: int = Field(default=0, ge=0, le=100)
    light: int = Field(default=0, ge=0, le=100)
    parking: int = Field(default=0, ge=0, le=100)


class NewListing(BaseModel):
    """A listing to create. No id/created_at — the store assigns those."""

    address: str = Field(min_length=1)
    price: int = Field(gt=0, description="List price in whole dollars.")
    beds: int = Field(ge=0)
    baths: float = Field(ge=0)
    sqft: int | None = Field(default=None, gt=0)
    headline: str | None = None
    facts: Facts = Field(default_factory=dict)
    ratings: Ratings = Field(default_factory=Ratings, description="0–100 per scored dimension; the scorer's input.")
    image_url: str | None = Field(default=None, description="Public URL of the listing photo (Supabase Storage).")


class Listing(NewListing):
    """A stored listing: a NewListing plus its server-assigned identity."""

    id: UUID
    created_at: datetime
