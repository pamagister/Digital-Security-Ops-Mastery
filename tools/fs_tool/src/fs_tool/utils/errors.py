"""Custom exceptions for fs-tool."""

from __future__ import annotations

from pathlib import Path
from typing import Any


class FSError(Exception):
    """Base exception for fs-tool errors."""

    def __init__(self, message: str, *, details: dict[str, Any] | None = None):
        super().__init__(message)
        self.message = message
        self.details = details or {}


class SafetyError(FSError):
    """Raised when an operation would violate safety guarantees."""

    pass


class VerificationError(FSError):
    """Raised when content verification fails."""

    pass


class PathError(FSError):
    """Raised for path-related errors (not found, not a directory, etc.)."""

    def __init__(self, message: str, path: Path | str, **details):
        super().__init__(message, details={"path": str(path), **details})
        self.path = Path(path)


class NotFoundError(PathError):
    """Raised when a path does not exist."""

    pass


class NotADirectoryError(PathError):
    """Raised when a path exists but is not a directory."""

    pass


class NotAFileError(PathError):
    """Raised when a path exists but is not a regular file."""

    pass


class AlreadyExistsError(PathError):
    """Raised when destination already exists (no-overwrite policy)."""

    pass


class OverlapError(FSError):
    """Raised when source and destination directories overlap."""

    pass


class EntryLimitError(FSError):
    """Raised when entry limit is reached during scanning."""

    pass


class UnsupportedEntryError(FSError):
    """Raised when an unsupported filesystem entry type is encountered."""

    pass


class ConcurrencyError(VerificationError):
    """Raised when a file changes during an operation."""

    pass


class ChecksumMismatchError(VerificationError):
    """Raised when computed checksum doesn't match expected."""

    def __init__(self, path: Path, expected: str, actual: str):
        super().__init__(
            f"Checksum mismatch for {path}",
            details={"path": str(path), "expected": expected, "actual": actual},
        )
        self.path = path
        self.expected = expected
        self.actual = actual