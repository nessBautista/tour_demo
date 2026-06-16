"""Listings backend for the Tour Debrief Companion demo.

The package is deliberately layered so the storage choice is an implementation
detail. The flow is: a CLI (and, later, the app) depends only on the
``ListingRepository`` protocol; a config-driven factory picks the concrete
backend (in-memory by default, Supabase when configured).
"""

from .models import Listing, NewListing
from .repository import ListingNotFoundError, ListingRepository

__all__ = [
    "Listing",
    "NewListing",
    "ListingRepository",
    "ListingNotFoundError",
]
