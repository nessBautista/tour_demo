from uuid import UUID, uuid4

import pytest

from tour_backend.image_store import ImageStore, LocalImageStore
from tour_backend.repository import ListingNotFoundError

SEED_ID = UUID("00000000-0000-0000-0000-000000000001")


def test_local_store_satisfies_protocol():
    assert isinstance(LocalImageStore(), ImageStore)


def test_local_store_returns_file_url(tmp_path):
    photo = tmp_path / "alder.jpg"
    photo.write_bytes(b"bytes")
    url = LocalImageStore().upload(photo)
    assert url.startswith("file://")
    assert url.endswith("alder.jpg")


def test_local_store_rejects_missing_file(tmp_path):
    with pytest.raises(FileNotFoundError):
        LocalImageStore().upload(tmp_path / "nope.jpg")


def test_repo_set_image_updates_url(repo):
    updated = repo.set_image(SEED_ID, "https://example.test/photo.jpg")
    assert updated.image_url == "https://example.test/photo.jpg"
    assert repo.get_listing(SEED_ID).image_url == "https://example.test/photo.jpg"


def test_repo_set_image_unknown_id_raises(repo):
    with pytest.raises(ListingNotFoundError):
        repo.set_image(uuid4(), "https://example.test/photo.jpg")
