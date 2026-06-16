"""Command-line interface for the listings backend.

    tour-backend list                      # show all listings
    tour-backend show <id>                 # show one listing
    tour-backend add --address ...         # append a listing
    tour-backend set-image <id> <file>     # upload + attach a photo

The CLI depends only on the ``ListingRepository`` / ``ImageStore`` protocols;
``build_backends`` chooses them from the environment. With no SUPABASE_* set it
runs against the seeded in-memory backend, so every command works offline.
"""

from __future__ import annotations

from pathlib import Path
from uuid import UUID

import typer
from pydantic import ValidationError
from rich.console import Console
from rich.table import Table

from .config import Backends, Settings, build_backends
from .image_store import ImageStore
from .models import Listing, NewListing
from .repository import (
    BackendUnavailableError,
    ListingNotFoundError,
    ListingRepository,
)

app = typer.Typer(
    help="Listings backend for the Tour Debrief Companion demo.",
    no_args_is_help=True,
    add_completion=False,
)
console = Console()


@app.callback()
def _main(ctx: typer.Context) -> None:
    settings = Settings()
    try:
        ctx.obj = build_backends(settings)
    except BackendUnavailableError as exc:
        console.print(f"[red]{exc}[/red]")
        raise typer.Exit(code=1)
    backend = "Supabase" if settings.has_supabase else "in-memory (seeded)"
    console.print(f"[dim]backend: {backend}[/dim]")


def _backends(ctx: typer.Context) -> Backends:
    return ctx.obj


def _repo(ctx: typer.Context) -> ListingRepository:
    return ctx.obj.repo


def _images(ctx: typer.Context) -> ImageStore:
    return ctx.obj.images


def _render(listings: list[Listing]) -> None:
    if not listings:
        console.print("[yellow]No listings.[/yellow]")
        return
    table = Table(title=f"{len(listings)} listing(s)")
    table.add_column("address")
    table.add_column("price", justify="right")
    table.add_column("beds", justify="right")
    table.add_column("baths", justify="right")
    table.add_column("img", justify="center")
    table.add_column("id", style="dim")
    for l in listings:
        table.add_row(
            l.address,
            f"${l.price:,}",
            str(l.beds),
            f"{l.baths:g}",
            "[green]✓[/green]" if l.image_url else "",
            str(l.id),
        )
    console.print(table)


@app.command("list")
def list_listings(ctx: typer.Context) -> None:
    """List all listings, most expensive first."""
    _render(_repo(ctx).list_listings())


@app.command("show")
def show_listing(ctx: typer.Context, listing_id: UUID) -> None:
    """Show one listing, including its facts."""
    try:
        listing = _repo(ctx).get_listing(listing_id)
    except ListingNotFoundError as exc:
        console.print(f"[red]{exc}[/red]")
        raise typer.Exit(code=1)
    console.print_json(listing.model_dump_json())


@app.command("add")
def add_listing(
    ctx: typer.Context,
    address: str = typer.Option(..., help="Street address."),
    price: int = typer.Option(..., help="List price in whole dollars."),
    beds: int = typer.Option(..., help="Number of bedrooms."),
    baths: float = typer.Option(..., help="Number of bathrooms."),
    sqft: int | None = typer.Option(None, help="Interior square footage."),
    headline: str | None = typer.Option(None, help="One-line summary."),
    fact: list[str] = typer.Option(
        None, "--fact", help="Descriptive fact as key=value (repeatable)."
    ),
    image: Path | None = typer.Option(
        None, "--image", help="Path to a photo to upload and attach.", exists=True,
        dir_okay=False,
    ),
) -> None:
    """Add a listing. Example:

    tour-backend add --address "9 Oak St" --price 510000 --beds 3 --baths 2 --fact yard=large
    """
    try:
        facts = dict(_parse_fact(f) for f in (fact or []))
        image_url = _images(ctx).upload(image) if image else None
        new = NewListing(
            address=address,
            price=price,
            beds=beds,
            baths=baths,
            sqft=sqft,
            headline=headline,
            facts=facts,
            image_url=image_url,
        )
    except (ValidationError, ValueError) as exc:
        console.print(f"[red]Invalid listing:[/red] {exc}")
        raise typer.Exit(code=1)

    listing = _repo(ctx).add_listing(new)
    console.print(f"[green]Added[/green] {listing.address} ([dim]{listing.id}[/dim])")


@app.command("set-image")
def set_image(
    ctx: typer.Context,
    listing_id: UUID,
    image: Path = typer.Argument(
        ..., help="Path to the photo to upload.", exists=True, dir_okay=False
    ),
) -> None:
    """Upload a photo and attach it to an existing listing."""
    try:
        image_url = _images(ctx).upload(image)
        listing = _repo(ctx).set_image(listing_id, image_url)
    except ListingNotFoundError as exc:
        console.print(f"[red]{exc}[/red]")
        raise typer.Exit(code=1)
    console.print(f"[green]Image set[/green] for {listing.address}")
    console.print(f"[dim]{listing.image_url}[/dim]")


def _parse_fact(raw: str) -> tuple[str, str]:
    key, sep, value = raw.partition("=")
    if not sep or not key:
        raise ValueError(f"fact must be key=value, got {raw!r}")
    return key.strip(), value.strip()
