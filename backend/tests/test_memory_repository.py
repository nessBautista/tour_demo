from uuid import UUID, uuid4

import pytest

from tour_backend.models import NewListing
from tour_backend.repository import ListingNotFoundError, ListingRepository


def test_seeded_repo_satisfies_the_protocol(repo):
    assert isinstance(repo, ListingRepository)


def test_list_returns_seed_sorted_by_price_desc(repo):
    prices = [l.price for l in repo.list_listings()]
    assert prices == [529_000, 485_000, 449_000]


def test_get_known_listing(repo):
    listing = repo.get_listing(UUID("00000000-0000-0000-0000-000000000001"))
    assert listing.address == "412 Alder Court, Maple Grove"


def test_get_missing_listing_raises(repo):
    missing = uuid4()
    with pytest.raises(ListingNotFoundError) as exc:
        repo.get_listing(missing)
    assert exc.value.listing_id == missing


def test_add_assigns_id_and_persists(repo):
    before = len(repo.list_listings())
    created = repo.add_listing(
        NewListing(address="9 Oak St", price=510_000, beds=3, baths=2)
    )
    assert isinstance(created.id, UUID)
    assert len(repo.list_listings()) == before + 1
    assert repo.get_listing(created.id) == created
