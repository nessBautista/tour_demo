import pytest

from tour_backend.repositories.memory import InMemoryListingRepository


@pytest.fixture
def repo() -> InMemoryListingRepository:
    """A fresh, seeded in-memory repository per test."""
    return InMemoryListingRepository.seeded()
