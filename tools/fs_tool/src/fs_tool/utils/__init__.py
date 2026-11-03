"""Utility modules for fs-tool."""

from __future__ import annotations

from fs_tool.utils.errors import (
    AlreadyExistsError,
    ChecksumMismatchError,
    ConcurrencyError,
    EntryLimitError,
    FSError,
    NotADirectoryError,
    NotAFileError,
    NotFoundError,
    OverlapError,
    PathError,
    SafetyError,
    UnsupportedEntryError,
    VerificationError,
)
from fs_tool.utils.paths import (
    deduplicate_sources,
    expand_path,
    get_origins,
    is_filesystem_root,
    resolve_nofollow_leaf,
    resolve_strict,
    safe_relpath,
    validate_directory,
    validate_file,
    validate_no_overlap,
)

__all__ = [
    # errors
    "FSError",
    "SafetyError",
    "VerificationError",
    "PathError",
    "NotFoundError",
    "NotADirectoryError",
    "NotAFileError",
    "AlreadyExistsError",
    "OverlapError",
    "EntryLimitError",
    "UnsupportedEntryError",
    "ConcurrencyError",
    "ChecksumMismatchError",
    # paths
    "expand_path",
    "resolve_strict",
    "resolve_nofollow_leaf",
    "validate_directory",
    "validate_file",
    "validate_no_overlap",
    "deduplicate_sources",
    "get_origins",
    "is_filesystem_root",
    "safe_relpath",
]