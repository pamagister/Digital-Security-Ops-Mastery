"""Path utilities for fs-tool."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

from fs_tool.utils.errors import (
    NotADirectoryError,
    NotAFileError,
    NotFoundError,
    OverlapError,
    PathError,
)


def expand_path(path: str | Path) -> Path:
    """Expand user (~) and environment variables, return Path."""
    if isinstance(path, Path):
        return path.expanduser()
    return Path(os.path.expandvars(os.path.expanduser(str(path))))


def resolve_strict(path: str | Path) -> Path:
    """Resolve path strictly (must exist), following symlinks for directories."""
    expanded = expand_path(path)
    return expanded.resolve(strict=True)


def resolve_nofollow_leaf(path: str | Path) -> Path:
    """
    Resolve path without following the final component if it's a symlink.
    Used for operations that should not follow symlinks on the target.
    """
    candidate = expand_path(path)
    if not candidate.name:
        return candidate.resolve(strict=True)
    parent = candidate.parent.resolve(strict=True)
    return parent / candidate.name


def validate_directory(path: str | Path, must_exist: bool = True) -> Path:
    """Validate and return a directory path."""
    expanded = expand_path(path)
    if must_exist:
        if not expanded.exists():
            raise NotFoundError(f"Directory not found: {expanded}", expanded)
        if not expanded.is_dir():
            raise NotADirectoryError(f"Not a directory: {expanded}", expanded)
    return expanded


def validate_file(path: str | Path, must_exist: bool = True) -> Path:
    """Validate and return a file path."""
    expanded = expand_path(path)
    if must_exist:
        if not expanded.exists():
            raise NotFoundError(f"File not found: {expanded}", expanded)
        if not expanded.is_file():
            raise NotAFileError(f"Not a regular file: {expanded}", expanded)
    return expanded


def validate_no_overlap(sources: list[Path], destination: Path) -> None:
    """Ensure source directories don't overlap with destination."""
    dest_resolved = destination.resolve()
    for source in sources:
        src_resolved = source.resolve()
        if src_resolved == dest_resolved:
            raise OverlapError(
                f"Source and destination directories must not overlap: {src_resolved}",
                details={"source": str(src_resolved), "destination": str(dest_resolved)},
            )
        if src_resolved.is_relative_to(dest_resolved):
            raise OverlapError(
                f"Source and destination directories must not overlap: {src_resolved}",
                details={"source": str(src_resolved), "destination": str(dest_resolved)},
            )
        if dest_resolved.is_relative_to(src_resolved):
            raise OverlapError(
                f"Source and destination directories must not overlap: {dest_resolved}",
                details={"source": str(src_resolved), "destination": str(dest_resolved)},
            )


def deduplicate_sources(sources: list[Path]) -> list[Path]:
    """
    Remove sources that are subdirectories of other sources.
    Returns sources sorted by path, with nested sources removed.
    """
    resolved = sorted({s.resolve() for s in sources}, key=str)
    keep: list[Path] = []
    for src in resolved:
        if not any(src != other and src.is_relative_to(other) for other in resolved):
            keep.append(src)
    return keep


def get_origins(absolute_path: Path, sources: list[Path]) -> list[dict[str, str]]:
    """Get all source roots that contain the given absolute path."""
    origins = []
    for source in sources:
        if absolute_path.is_relative_to(source):
            origins.append(
                {
                    "root": str(source),
                    "path": absolute_path.relative_to(source).as_posix(),
                }
            )
    return origins


def is_filesystem_root(path: Path) -> bool:
    """Check if path is a filesystem root (e.g., / on Linux)."""
    return path == Path(path.anchor)


def safe_relpath(path: Path, root: Path) -> str:
    """Get relative path as POSIX string, handling edge cases."""
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return str(path)