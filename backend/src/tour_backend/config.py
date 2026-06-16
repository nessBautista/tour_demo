"""Configuration and the backend factory.

``Settings`` reads SUPABASE_* from the environment (or a local .env). The single
``build_backends`` entry point is the only place that knows about concrete
implementations: it returns a (repository, image store) pair so the two always
match — Supabase-backed together, or in-memory + local together — and shares one
Supabase client between them.
"""

from __future__ import annotations

from typing import NamedTuple

from pydantic_settings import BaseSettings, SettingsConfigDict

from .image_store import ImageStore, LocalImageStore
from .repositories.memory import InMemoryListingRepository
from .repository import BackendUnavailableError, ListingRepository


class Backends(NamedTuple):
    repo: ListingRepository
    images: ImageStore


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="SUPABASE_", env_file=".env", extra="ignore"
    )

    url: str | None = None
    anon_key: str | None = None

    @property
    def has_supabase(self) -> bool:
        return bool(self.url and self.anon_key)


def build_backends(settings: Settings | None = None) -> Backends:
    """Return the configured (repository, image store) pair: Supabase if
    credentials are present, otherwise the seeded in-memory + local pair."""
    settings = settings or Settings()
    if not settings.has_supabase:
        return Backends(InMemoryListingRepository.seeded(), LocalImageStore())

    try:
        from supabase import create_client
    except ModuleNotFoundError as exc:
        raise BackendUnavailableError(
            "Supabase credentials are set but the 'supabase' client isn't "
            "installed. Install it with:  uv sync --extra supabase\n"
            "(or unset SUPABASE_URL / SUPABASE_ANON_KEY to use the in-memory backend.)"
        ) from exc

    from .image_store import SupabaseImageStore
    from .repositories.supabase import SupabaseListingRepository

    assert settings.url and settings.anon_key  # narrowed by has_supabase
    client = create_client(settings.url, settings.anon_key)
    return Backends(SupabaseListingRepository(client), SupabaseImageStore(client))
