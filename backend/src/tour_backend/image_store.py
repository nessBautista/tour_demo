"""The image-bytes seam.

Listing rows only ever hold a URL string; the actual photo bytes live behind
this ``ImageStore`` — the same inversion the repository uses. ``LocalImageStore``
needs no network (so the offline CLI and tests can exercise the upload path);
``SupabaseImageStore`` pushes to a public Storage bucket.
"""

from __future__ import annotations

import mimetypes
from pathlib import Path
from typing import TYPE_CHECKING, Protocol, runtime_checkable
from uuid import uuid4

if TYPE_CHECKING:
    from supabase import Client


@runtime_checkable
class ImageStore(Protocol):
    def upload(self, file_path: Path) -> str:
        """Store the image and return a URL that resolves to it."""
        ...


class LocalImageStore:
    """Offline fallback: nothing is uploaded; the file's own ``file://`` URL is
    returned so the rest of the pipeline (set the row's image_url) still runs."""

    def upload(self, file_path: Path) -> str:
        path = Path(file_path)
        if not path.is_file():
            raise FileNotFoundError(path)
        return path.resolve().as_uri()


class SupabaseImageStore:
    """Uploads to a public Supabase Storage bucket and returns the public URL."""

    def __init__(self, client: "Client", bucket: str = "listing-images") -> None:
        self._client = client
        self._bucket = bucket

    def upload(self, file_path: Path) -> str:
        path = Path(file_path)
        if not path.is_file():
            raise FileNotFoundError(path)
        # Unique object name keeps uploads idempotent-safe (no overwrite races).
        object_name = f"{uuid4().hex}{path.suffix.lower()}"
        content_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        bucket = self._client.storage.from_(self._bucket)
        bucket.upload(object_name, path.read_bytes(), {"content-type": content_type})
        return bucket.get_public_url(object_name)
