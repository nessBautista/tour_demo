import pytest
from pydantic import ValidationError

from tour_backend.models import NewListing


def test_minimal_listing_defaults_facts_to_empty():
    listing = NewListing(address="9 Oak St", price=510_000, beds=3, baths=2)
    assert listing.facts == {}
    assert listing.sqft is None


@pytest.mark.parametrize(
    "field,value",
    [("price", 0), ("price", -1), ("beds", -1), ("baths", -0.5), ("address", "")],
)
def test_rejects_out_of_range_values(field, value):
    base = {"address": "9 Oak St", "price": 510_000, "beds": 3, "baths": 2}
    base[field] = value
    with pytest.raises(ValidationError):
        NewListing(**base)
