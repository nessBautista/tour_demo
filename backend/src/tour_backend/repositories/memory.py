"""In-memory backend — the default.

It needs no network and no secrets, which makes it the backend the tests and the
offline CLI run against. It is the executable reference for what the Supabase
backend must also do.
"""

from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID, uuid4

from ..models import Listing, NewListing
from ..repository import ListingNotFoundError
from ..seed_data import SEED_LISTINGS


class InMemoryListingRepository:
    """Holds listings in a dict. State lives for the process lifetime only."""

    def __init__(self, listings: list[Listing] | None = None) -> None:
        self._listings: dict[UUID, Listing] = {l.id: l for l in (listings or [])}

    @classmethod
    def seeded(cls) -> "InMemoryListingRepository":
        """A repository pre-loaded with the demo listings."""
        return cls(list(SEED_LISTINGS))

    def list_listings(self) -> list[Listing]:
        return sorted(self._listings.values(), key=lambda l: l.price, reverse=True)

    def get_listing(self, listing_id: UUID) -> Listing:
        try:
            return self._listings[listing_id]
        except KeyError:
            raise ListingNotFoundError(listing_id) from None

    def add_listing(self, new: NewListing) -> Listing:
        listing = Listing(
            id=uuid4(),
            created_at=datetime.now(timezone.utc),
            **new.model_dump(),
        )
        self._listings[listing.id] = listing
        return listing

    def set_image(self, listing_id: UUID, image_url: str) -> Listing:
        listing = self.get_listing(listing_id)
        updated = listing.model_copy(update={"image_url": image_url})
        self._listings[listing_id] = updated
        return updated
