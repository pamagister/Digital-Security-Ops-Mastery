"""Content-based directory comparison for fs-tool."""

from __future__ import annotations

from collections import Counter
from pathlib import Path
from typing import Any

from fs_tool.core.inventory import create_inventory
from fs_tool.utils.errors import OverlapError
from fs_tool.utils.paths import (
    deduplicate_sources,
    get_origins,
    validate_directory,
    validate_no_overlap,
)


def signature(entry: dict[str, Any]) -> tuple[str, str | None]:
    """Generate comparison signature for an entry."""
    if entry["type"] == "file":
        return "file", entry.get("sha256")
    if entry["type"] == "symlink":
        return "symlink", entry.get("target")
    return "other", None


def compare_files_by_content(
    source_directories: list[str | Path],
    destination_directory: str | Path,
    *,
    max_entries: int = 100_000,
) -> dict[str, Any]:
    """
    Find source files not preserved in destination by content.

    Compares regular files by SHA-256 and symlinks by target text,
    independent of names and paths. Duplicate content counted per occurrence.
    Overlapping source directories deduplicated by absolute path.

    Args:
        source_directories: One or more source directories
        destination_directory: Destination directory to compare against
        max_entries: Maximum entries per inventory

    Returns:
        Dict with: complete, source_entry_count, matched_entry_count,
                   missing_entry_count, missing_entries, unsupported_entries, errors
    """
    if not source_directories:
        raise ValueError("At least one source directory is required")
    if max_entries < 1:
        raise ValueError("max_entries must be at least 1")

    sources = sorted(
        {validate_directory(d) for d in source_directories},
        key=str,
    )
    destination = validate_directory(destination_directory)

    # Check overlap
    validate_no_overlap(sources, destination)

    # Deduplicate nested sources
    scan_sources = deduplicate_sources(sources)

    source_entries: dict[str, dict[str, Any]] = {}
    errors: list[dict[str, str]] = []
    unsupported_entries: list[dict[str, Any]] = []

    # Scan all sources
    for source in scan_sources:
        inventory = create_inventory(str(source), max_entries=max_entries)
        errors.extend({"root": str(source), **error} for error in inventory["errors"])

        for entry in inventory["entries"]:
            if entry["type"] not in {"file", "symlink"}:
                if entry["type"] == "other":
                    unsupported_entries.append(
                        {"root": str(source), "path": entry["path"], "type": "other"}
                    )
                continue

            absolute_path = str(source / entry["path"])
            origins = get_origins(Path(absolute_path), sources)

            record = source_entries.setdefault(
                absolute_path,
                {
                    "type": entry["type"],
                    "sha256": entry.get("sha256"),
                    "target": entry.get("target"),
                    "origins": origins,
                },
            )
            record["origins"] = origins

    # Scan destination
    destination_inventory = create_inventory(str(destination), max_entries=max_entries)
    errors.extend(
        {"root": str(destination), **error} for error in destination_inventory["errors"]
    )

    # Build available signatures counter
    available = Counter(
        signature(entry)
        for entry in destination_inventory["entries"]
        if entry["type"] in {"file", "symlink"}
    )

    # Find missing entries
    missing_entries: list[dict[str, Any]] = []
    ordered_sources = sorted(
        source_entries.values(),
        key=lambda e: (
            e["type"],
            e["sha256"] or e["target"] or "",
            e["origins"][0]["root"],
            e["origins"][0]["path"],
        ),
    )

    for entry in ordered_sources:
        entry_sig = signature(entry)
        if available[entry_sig]:
            available[entry_sig] -= 1
            continue

        missing = {"type": entry["type"], "origins": entry["origins"]}
        if entry["type"] == "file":
            missing["sha256"] = entry["sha256"]
        else:
            missing["target"] = entry["target"]
        missing_entries.append(missing)

    complete = not errors and not unsupported_entries

    return {
        "complete": complete,
        "source_entry_count": len(source_entries),
        "matched_entry_count": len(source_entries) - len(missing_entries),
        "missing_entry_count": len(missing_entries),
        "missing_entries": missing_entries,
        "unsupported_entries": unsupported_entries,
        "errors": errors,
    }