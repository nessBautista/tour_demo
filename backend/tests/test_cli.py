import pytest
from typer.testing import CliRunner

import tour_backend.cli as cli
from tour_backend.config import Backends
from tour_backend.image_store import LocalImageStore
from tour_backend.repositories.memory import InMemoryListingRepository

runner = CliRunner()


@pytest.fixture
def shared_repo(monkeypatch):
    """Pin the CLI to one in-memory repo so state survives across invocations
    (each `runner.invoke` rebuilds the app but shares this instance)."""
    # Give Rich a wide terminal so table cells aren't truncated in captured output.
    monkeypatch.setenv("COLUMNS", "200")
    repo = InMemoryListingRepository.seeded()
    backends = Backends(repo, LocalImageStore())
    monkeypatch.setattr(cli, "build_backends", lambda settings=None: backends)
    return repo


def test_list_shows_seeded_listings(shared_repo):
    result = runner.invoke(cli.app, ["list"])
    assert result.exit_code == 0
    assert "412 Alder Court, Maple Grove" in result.stdout


def test_add_then_list_includes_new_listing(shared_repo):
    add = runner.invoke(
        cli.app,
        ["add", "--address", "9 Oak St", "--price", "510000",
         "--beds", "3", "--baths", "2", "--fact", "yard=large"],
    )
    assert add.exit_code == 0, add.stdout
    assert "Added" in add.stdout

    listed = runner.invoke(cli.app, ["list"])
    assert "9 Oak St" in listed.stdout


def test_add_rejects_invalid_price(shared_repo):
    result = runner.invoke(
        cli.app,
        ["add", "--address", "9 Oak St", "--price", "-5",
         "--beds", "3", "--baths", "2"],
    )
    assert result.exit_code == 1
    assert "Invalid listing" in result.stdout


def test_show_missing_id_exits_nonzero(shared_repo):
    result = runner.invoke(
        cli.app, ["show", "11111111-1111-1111-1111-111111111111"]
    )
    assert result.exit_code == 1


def test_set_image_attaches_url(shared_repo, tmp_path):
    photo = tmp_path / "alder.jpg"
    photo.write_bytes(b"fake-jpeg-bytes")
    seed_id = "00000000-0000-0000-0000-000000000001"

    result = runner.invoke(cli.app, ["set-image", seed_id, str(photo)])
    assert result.exit_code == 0, result.stdout
    assert "Image set" in result.stdout

    from uuid import UUID

    assert shared_repo.get_listing(UUID(seed_id)).image_url is not None


def test_set_image_rejects_missing_file(shared_repo):
    seed_id = "00000000-0000-0000-0000-000000000001"
    result = runner.invoke(cli.app, ["set-image", seed_id, "/no/such/file.jpg"])
    assert result.exit_code != 0
