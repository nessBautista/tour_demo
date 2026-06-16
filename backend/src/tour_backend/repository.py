"""The storage seam.

Everything above the storage layer (the CLI today, the app tomorrow) talks to
this ``Protocol`` and never imports a concrete backend. That inversion is what
lets the in-memory and Supabase implementations be swapped by config alone, and
lets the tests run without a network.
"""

from __future__ import annotations

from typing import Protocol, runtime_checkable
from uuid import UUID

from .models import Listing, NewListing


class ListingNotFoundError(LookupError):
    """Raised when a listing id has no match."""

    def __init__(self, listing_id: UUID) -> None:
        super().__init__(f"No listing with id {listing_id}")
        self.listing_id = listing_id


class BackendUnavailableError(RuntimeError):
    """Raised when the configured backend can't be constructed (e.g. Supabase
    credentials are set but the optional client isn't installed)."""


@runtime_checkable
class ListingRepository(Protocol):
    """Read/append access to listings. Listings are immutable once created."""

    def list_listings(self) -> list[Listing]:
        """All listings, most expensive first."""
        ...

    def get_listing(self, listing_id: UUID) -> Listing:
        """One listing by id, or raise :class:`ListingNotFoundError`."""
        ...

    def add_listing(self, new: NewListing) -> Listing:
        """Persist a new listing and return it with its assigned id."""
        ...

    def set_image(self, listing_id: UUID, image_url: str) -> Listing:
        """Attach (or replace) a listing's photo URL and return the updated row.

        Raises :class:`ListingNotFoundError` if the id is unknown.
        """
        ...
