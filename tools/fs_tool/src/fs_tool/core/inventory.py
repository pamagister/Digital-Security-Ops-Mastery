"""Inventory creation and tree hashing for fs-tool."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from fs_tool.core.filesystem import Entry, collect_entries
from fs_tool.core.hashing import canonical_json_hash, hash_file
from fs_tool.utils.paths import validate_directory


def create_inventory(
    directory: str | Path,
    *,
    max_entries: int = 100_000,
) -> dict[str, Any]:
    """
    Create a deterministic tree inventory with SHA-256 for each regular file.

    Args:
        directory: Root directory to inventory
        max_entries: Maximum entries to scan

    Returns:
        Dict with: root, complete, entry_count, tree_sha256, entries, errors
    """
    root = validate_directory(directory)
    entries, errors = collect_entries(root, recursive=True, max_entries=max_entries)

    # Hash all regular files
    for i, entry in enumerate(entries):
        if entry.type != "file":
            continue
        try:
            file_path = root / entry.path
            file_stat = file_path.lstat()
            sha256 = hash_file(file_path, expected_stat=file_stat)
            # Create new Entry with hash (Entries are frozen dataclass)
            entries[i] = Entry(
                path=entry.path,
                type=entry.type,
                size=entry.size,
                target=entry.target,
                sha256=sha256,
            )
        except OSError as error:
            errors.append({"path": entry.path, "error": str(error)})

    complete = not errors
    tree_hash = None
    if complete:
        # Convert to serializable format for canonical JSON
        serializable = [_entry_dict(entry) for entry in entries]
        tree_hash = canonical_json_hash(serializable)

    return {
        "root": str(root),
        "complete": complete,
        "entry_count": len(entries),
        "tree_sha256": tree_hash,
        "entries": [_entry_dict(entry) for entry in entries],
        "errors": errors,
    }


def _entry_dict(entry: Entry) -> dict[str, Any]:
    result: dict[str, Any] = {
        "path": entry.path,
        "type": entry.type,
        "size": entry.size,
    }
    if entry.type == "file":
        if entry.sha256 is not None:
            result["sha256"] = entry.sha256
    elif entry.type == "symlink":
        result["target"] = entry.target
    return result


def inventory_to_entries(inventory: dict[str, Any]) -> list[Entry]:
    """Convert inventory entries to Entry objects."""
    entries = []
    for e in inventory["entries"]:
        entries.append(
            Entry(
                path=e["path"],
                type=e["type"],
                size=e.get("size"),
                target=e.get("target"),
                sha256=e.get("sha256"),
            )
        )
    return entries