"""Core filesystem operations for fs-tool."""

from __future__ import annotations

import os
import stat
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from fs_tool.utils.errors import NotAFileError, NotADirectoryError
from fs_tool.utils.paths import expand_path


@dataclass(frozen=True)
class Entry:
    """Filesystem entry with metadata."""

    path: str  # Relative to root, POSIX format
    type: str  # "file", "directory", "symlink", "other"
    size: int | None = None
    target: str | None = None  # For symlinks
    sha256: str | None = None  # For files


def entry_type_from_mode(mode: int) -> str:
    """Determine entry type from stat mode."""
    if stat.S_ISREG(mode):
        return "file"
    if stat.S_ISDIR(mode):
        return "directory"
    if stat.S_ISLNK(mode):
        return "symlink"
    return "other"


def collect_entries(
    root: Path,
    *,
    recursive: bool = False,
    max_entries: int = 100_000,
) -> tuple[list[Entry], list[dict[str, str]]]:
    """
    Collect directory entries with optional recursion.

    Args:
        root: Root directory (must exist and be a directory)
        recursive: Recursively scan subdirectories
        max_entries: Maximum entries to collect (safety limit)

    Returns:
        Tuple of (entries, errors)

    Raises:
        NotADirectoryError: If root is not a directory
        EntryLimitError: If max_entries exceeded (also in errors)
    """
    if not root.is_dir():
        raise NotADirectoryError(f"Not a directory: {root}", root)
    if max_entries < 1:
        raise ValueError("max_entries must be at least 1")

    entries: list[Entry] = []
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
                kind = entry_type_from_mode(info.st_mode)

                entry = Entry(
                    path=relative_path,
                    type=kind,
                    size=info.st_size if kind == "file" else None,
                )

                if kind == "symlink":
                    entry = Entry(
                        path=relative_path,
                        type=kind,
                        target=os.readlink(child_path),
                    )

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

    # Sort by path for determinism
    entries.sort(key=lambda e: e.path)
    return entries, errors


def read_text_file(
    path: Path,
    max_bytes: int = 65536,
    encoding: str = "utf-8",
) -> str:
    """
    Read a text file with size limit, rejecting symlinks.

    Args:
        path: File path (symlinks not followed)
        max_bytes: Maximum bytes to read
        encoding: Text encoding

    Returns:
        File content as string

    Raises:
        NotAFileError: If not a regular file
        ValueError: If file exceeds max_bytes
    """
    if max_bytes < 1 or max_bytes > 1_000_000:
        raise ValueError("max_bytes must be between 1 and 1000000")

    info = path.lstat()
    if not stat.S_ISREG(info.st_mode):
        raise NotAFileError(f"Not a regular file: {path}", path)
    if info.st_size > max_bytes:
        raise ValueError(f"File exceeds max_bytes ({max_bytes}): {path}")

    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(path, flags)
    try:
        with os.fdopen(fd, "rb") as stream:
            content = stream.read(max_bytes + 1)
        if len(content) > max_bytes:
            raise ValueError(f"File exceeds max_bytes ({max_bytes}): {path}")
        return content.decode(encoding)
    finally:
        try:
            os.close(fd)
        except OSError:
            pass


def get_file_info(path: Path) -> dict[str, Any]:
    """
    Get file metadata without following final symlink.

    Returns dict with: path, type, size, modified_ns, mode, target (for symlinks)
    """
    info = path.lstat()
    kind = entry_type_from_mode(info.st_mode)

    result: dict[str, Any] = {
        "path": str(path),
        "type": kind,
        "size": info.st_size,
        "modified_ns": info.st_mtime_ns,
        "mode": stat.S_IMODE(info.st_mode),
    }
    if kind == "symlink":
        result["target"] = os.readlink(path)
    return result