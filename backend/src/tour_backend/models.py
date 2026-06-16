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

# Free-form, demo-only attributes (e.g. {"yard": "large, fenced"}). The comparison
# system (a later PR) reads structured ratings; here facts are just descriptive.
Facts = dict[str, str]


class NewListing(BaseModel):
    """A listing to create. No id/created_at — the store assigns those."""

    address: str = Field(min_length=1)
    price: int = Field(gt=0, description="List price in whole dollars.")
    beds: int = Field(ge=0)
    baths: float = Field(ge=0)
    sqft: int | None = Field(default=None, gt=0)
    headline: str | None = None
    facts: Facts = Field(default_factory=dict)
    image_url: str | None = Field(default=None, description="Public URL of the listing photo (Supabase Storage).")


class Listing(NewListing):
    """A stored listing: a NewListing plus its server-assigned identity."""

    id: UUID
    created_at: datetime
