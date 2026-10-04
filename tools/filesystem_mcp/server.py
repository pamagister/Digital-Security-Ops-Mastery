from __future__ import annotations

import hashlib
import json
import os
import shutil
import stat
import tempfile
from collections import Counter
from pathlib import Path
from typing import Any

from fastmcp import FastMCP


mcp = FastMCP("Local Filesystem Tools")
_HASH_CHUNK_SIZE = 1024 * 1024
_DEFAULT_MAX_ENTRIES = 100_000


def _entry_type(mode: int) -> str:
    if stat.S_ISREG(mode):
        return "file"
    if stat.S_ISDIR(mode):
        return "directory"
    if stat.S_ISLNK(mode):
        return "symlink"
    return "other"


def _path_without_following_leaf(path: str) -> Path:
    candidate = Path(path).expanduser()
    if not candidate.name:
        return candidate.resolve(strict=True)
    parent = candidate.parent.resolve(strict=True)
    return parent / candidate.name


def _hash_file(path: Path, expected_stat: os.stat_result) -> str:
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    descriptor = os.open(path, flags)
    with os.fdopen(descriptor, "rb") as stream:
        opened_stat = os.fstat(stream.fileno())
        if not stat.S_ISREG(opened_stat.st_mode):
            raise OSError(f"Not a regular file: {path}")
        if (opened_stat.st_dev, opened_stat.st_ino) != (
            expected_stat.st_dev,
            expected_stat.st_ino,
        ):
            raise OSError(f"File changed while scanning: {path}")
        digest = hashlib.sha256()
        while chunk := stream.read(_HASH_CHUNK_SIZE):
            digest.update(chunk)
        final_stat = os.fstat(stream.fileno())
        if (opened_stat.st_size, opened_stat.st_mtime_ns) != (
            final_stat.st_size,
            final_stat.st_mtime_ns,
        ):
            raise OSError(f"File changed while hashing: {path}")
        return digest.hexdigest()


def _collect_entries(
    root: Path, recursive: bool, max_entries: int
) -> tuple[list[dict[str, Any]], list[dict[str, str]]]:
    if max_entries < 1:
        raise ValueError("max_entries must be at least 1")

    entries: list[dict[str, Any]] = []
    errors: list[dict[str, str]] = []
    pending = [root]

    while pending:
        directory = pending.pop()
        try:
            with os.scandir(directory) as scanned:
                children = sorted(scanned, key=lambda item: item.name)
        except OSError as error:
            errors.append({"path": str(directory), "error": str(error)})
            continue

        child_directories: list[Path] = []
        for child in children:
            child_path = Path(child.path)
            relative_path = child_path.relative_to(root).as_posix()
            try:
                info = child.stat(follow_symlinks=False)
                kind = _entry_type(info.st_mode)
                entry: dict[str, Any] = {
                    "path": relative_path,
                    "type": kind,
                    "size": info.st_size if kind == "file" else None,
                }
                if kind == "symlink":
                    entry["target"] = os.readlink(child_path)
                entries.append(entry)
                if recursive and kind == "directory":
                    child_directories.append(child_path)
            except OSError as error:
                errors.append({"path": relative_path, "error": str(error)})

            if len(entries) >= max_entries:
                if child is not children[-1] or pending or child_directories:
                    errors.append(
                        {
                            "path": str(root),
                            "error": f"Entry limit reached ({max_entries})",
                        }
                    )
                pending.clear()
                child_directories.clear()
                break

        pending.extend(reversed(child_directories))

    entries.sort(key=lambda item: item["path"])
    return entries, errors


@mcp.tool()
def list_entries(
    directory: str,
    recursive: bool = False,
    offset: int = 0,
    limit: int = 1000,
    max_entries: int = _DEFAULT_MAX_ENTRIES,
) -> dict[str, Any]:
    """List directory entries with relative paths, types, and pagination."""
    if offset < 0:
        raise ValueError("offset must not be negative")
    if limit < 1 or limit > 5000:
        raise ValueError("limit must be between 1 and 5000")

    root = Path(directory).expanduser().resolve(strict=True)
    if not root.is_dir():
        raise ValueError(f"Not a directory: {root}")
    entries, errors = _collect_entries(root, recursive, max_entries)
    page = entries[offset : offset + limit]
    return {
        "root": str(root),
        "entries": page,
        "total_entries": len(entries),
        "offset": offset,
        "next_offset": offset + limit if offset + limit < len(entries) else None,
        "complete": not errors,
        "errors": errors,
    }


@mcp.tool()
def create_inventory(
    directory: str, max_entries: int = _DEFAULT_MAX_ENTRIES
) -> dict[str, Any]:
    """Create a deterministic tree inventory with a SHA-256 for each regular file."""
    root = Path(directory).expanduser().resolve(strict=True)
    if not root.is_dir():
        raise ValueError(f"Not a directory: {root}")

    entries, errors = _collect_entries(root, recursive=True, max_entries=max_entries)
    for entry in entries:
        if entry["type"] != "file":
            continue
        try:
            file_path = root / entry["path"]
            file_stat = file_path.lstat()
            entry["sha256"] = _hash_file(file_path, file_stat)
        except OSError as error:
            errors.append({"path": entry["path"], "error": str(error)})

    complete = not errors
    tree_hash = None
    if complete:
        canonical = json.dumps(
            entries, ensure_ascii=False, sort_keys=True, separators=(",", ":")
        ).encode("utf-8")
        tree_hash = hashlib.sha256(canonical).hexdigest()

    return {
        "root": str(root),
        "complete": complete,
        "entry_count": len(entries),
        "tree_sha256": tree_hash,
        "entries": entries,
        "errors": errors,
    }


@mcp.tool()
def compare_files_by_content(
    source_directories: list[str],
    destination_directory: str,
    max_entries: int = _DEFAULT_MAX_ENTRIES,
) -> dict[str, Any]:
    """Find source files not preserved in the destination by content, regardless of path."""
    if not source_directories:
        raise ValueError("At least one source directory is required")
    if max_entries < 1:
        raise ValueError("max_entries must be at least 1")

    sources = sorted(
        {
            Path(directory).expanduser().resolve(strict=True)
            for directory in source_directories
        },
        key=str,
    )
    destination = Path(destination_directory).expanduser().resolve(strict=True)
    if not destination.is_dir():
        raise ValueError(f"Not a directory: {destination}")
    for source in sources:
        if not source.is_dir():
            raise ValueError(f"Not a directory: {source}")
        if (
            source == destination
            or source.is_relative_to(destination)
            or destination.is_relative_to(source)
        ):
            raise ValueError(
                f"Source and destination directories must not overlap: {source}, {destination}"
            )

    scan_sources = [
        source
        for source in sources
        if not any(
            source != other and source.is_relative_to(other) for other in sources
        )
    ]
    source_entries: dict[str, dict[str, Any]] = {}
    errors: list[dict[str, str]] = []
    unsupported_entries: list[dict[str, Any]] = []
    for source in scan_sources:
        inventory = create_inventory(str(source), max_entries=max_entries)
        errors.extend(
            {"root": str(source), **error} for error in inventory["errors"]
        )
        for entry in inventory["entries"]:
            if entry["type"] not in {"file", "symlink"}:
                if entry["type"] == "other":
                    unsupported_entries.append(
                        {"root": str(source), "path": entry["path"], "type": "other"}
                    )
                continue

            absolute_file_path = source / entry["path"]
            absolute_path = str(absolute_file_path)
            origins = [
                {
                    "root": str(root),
                    "path": absolute_file_path.relative_to(root).as_posix(),
                }
                for root in sources
                if absolute_file_path.is_relative_to(root)
            ]
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

    destination_inventory = create_inventory(
        str(destination), max_entries=max_entries
    )
    errors.extend(
        {"root": str(destination), **error}
        for error in destination_inventory["errors"]
    )

    def signature(entry: dict[str, Any]) -> tuple[str, str | None]:
        value = entry["sha256"] if entry["type"] == "file" else entry["target"]
        return entry["type"], value

    available = Counter(
        signature(entry)
        for entry in destination_inventory["entries"]
        if entry["type"] in {"file", "symlink"}
    )
    missing_entries: list[dict[str, Any]] = []
    ordered_sources = sorted(
        source_entries.values(),
        key=lambda entry: (
            entry["type"],
            entry["sha256"] or entry["target"] or "",
            entry["origins"][0]["root"],
            entry["origins"][0]["path"],
        ),
    )
    for entry in ordered_sources:
        entry_signature = signature(entry)
        if available[entry_signature]:
            available[entry_signature] -= 1
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


@mcp.tool()
def get_file_info(path: str) -> dict[str, Any]:
    """Return filesystem metadata without following a final-component symlink."""
    target = _path_without_following_leaf(path)
    info = target.lstat()
    kind = _entry_type(info.st_mode)
    result: dict[str, Any] = {
        "path": str(target),
        "type": kind,
        "size": info.st_size,
        "modified_ns": info.st_mtime_ns,
        "mode": stat.S_IMODE(info.st_mode),
    }
    if kind == "symlink":
        result["target"] = os.readlink(target)
    return result


@mcp.tool()
def read_text_file(path: str, max_bytes: int = 65536) -> str:
    """Read a UTF-8 text file up to max_bytes; reject symlinks and oversized files."""
    if max_bytes < 1 or max_bytes > 1_000_000:
        raise ValueError("max_bytes must be between 1 and 1000000")
    target = _path_without_following_leaf(path)
    info = target.lstat()
    if not stat.S_ISREG(info.st_mode):
        raise ValueError(f"Not a regular file: {target}")
    if info.st_size > max_bytes:
        raise ValueError(f"File exceeds max_bytes ({max_bytes}): {target}")

    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    descriptor = os.open(target, flags)
    with os.fdopen(descriptor, "rb") as stream:
        content = stream.read(max_bytes + 1)
    if len(content) > max_bytes:
        raise ValueError(f"File exceeds max_bytes ({max_bytes}): {target}")
    return content.decode("utf-8")


@mcp.tool()
def create_directory(path: str) -> str:
    """Create a directory and missing parents; fail if the target already exists."""
    target = Path(path).expanduser()
    target.mkdir(parents=True, exist_ok=False)
    return str(target.resolve(strict=True))


@mcp.tool()
def copy_file(source: str, destination: str) -> str:
    """Copy a regular file without following source symlinks or overwriting targets."""
    source_path = _path_without_following_leaf(source)
    source_stat = source_path.lstat()
    if not stat.S_ISREG(source_stat.st_mode):
        raise ValueError(f"Source is not a regular file: {source_path}")

    destination_path = _path_without_following_leaf(destination)
    if os.path.lexists(destination_path):
        raise FileExistsError(f"Destination already exists: {destination_path}")

    descriptor, temporary_name = tempfile.mkstemp(
        prefix=".filesystem-mcp-", dir=destination_path.parent
    )
    temporary_path = Path(temporary_name)
    try:
        source_flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
        with os.fdopen(descriptor, "wb") as output_stream:
            source_descriptor = os.open(source_path, source_flags)
            with os.fdopen(source_descriptor, "rb") as input_stream:
                opened_stat = os.fstat(input_stream.fileno())
                if (opened_stat.st_dev, opened_stat.st_ino) != (
                    source_stat.st_dev,
                    source_stat.st_ino,
                ):
                    raise OSError(f"Source changed while copying: {source_path}")
                shutil.copyfileobj(input_stream, output_stream, _HASH_CHUNK_SIZE)
                output_stream.flush()
                os.fsync(output_stream.fileno())
                final_stat = os.fstat(input_stream.fileno())
                if (opened_stat.st_size, opened_stat.st_mtime_ns) != (
                    final_stat.st_size,
                    final_stat.st_mtime_ns,
                ):
                    raise OSError(f"Source changed while copying: {source_path}")
            shutil.copystat(source_path, temporary_path, follow_symlinks=False)
        os.link(temporary_path, destination_path, follow_symlinks=False)
    finally:
        temporary_path.unlink(missing_ok=True)
    return str(destination_path)


@mcp.tool()
def move_path(source: str, destination: str) -> str:
    """Move or rename a file or directory; fail if the destination already exists."""
    source_path = _path_without_following_leaf(source)
    if not os.path.lexists(source_path):
        raise FileNotFoundError(source_path)
    if source_path == Path(source_path.anchor):
        raise ValueError("Refusing to move a filesystem root")

    destination_path = _path_without_following_leaf(destination)
    if os.path.lexists(destination_path):
        raise FileExistsError(f"Destination already exists: {destination_path}")
    source_path.rename(destination_path)
    return str(destination_path)


if __name__ == "__main__":
    mcp.run()
