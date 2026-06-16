"""Supabase backend — the real one.

Used when SUPABASE_URL and SUPABASE_ANON_KEY are set. It takes an already-built
client (the factory in ``config`` constructs one and shares it with the image
store), so the optional ``supabase`` dependency is imported in exactly one place.
"""

from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import UUID

from ..models import Listing, NewListing
from ..repository import ListingNotFoundError

if TYPE_CHECKING:
    from supabase import Client

_TABLE = "listings"


class SupabaseListingRepository:
    """Maps the repository operations onto Supabase REST calls."""

    def __init__(self, client: "Client") -> None:
        self._client = client

    def list_listings(self) -> list[Listing]:
        resp = (
            self._client.table(_TABLE)
            .select("*")
            .order("price", desc=True)
            .execute()
        )
        return [Listing.model_validate(row) for row in resp.data]

    def get_listing(self, listing_id: UUID) -> Listing:
        resp = (
            self._client.table(_TABLE)
            .select("*")
            .eq("id", str(listing_id))
            .limit(1)
            .execute()
        )
        if not resp.data:
            raise ListingNotFoundError(listing_id)
        return Listing.model_validate(resp.data[0])

    def add_listing(self, new: NewListing) -> Listing:
        payload = new.model_dump(mode="json")
        resp = self._client.table(_TABLE).insert(payload).execute()
        return Listing.model_validate(resp.data[0])

    def set_image(self, listing_id: UUID, image_url: str) -> Listing:
        resp = (
            self._client.table(_TABLE)
            .update({"image_url": image_url})
            .eq("id", str(listing_id))
            .execute()
        )
        if not resp.data:
            raise ListingNotFoundError(listing_id)
        return Listing.model_validate(resp.data[0])
