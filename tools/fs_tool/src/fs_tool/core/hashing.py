"""Streaming SHA-256 hashing for fs-tool."""

from __future__ import annotations

import errno
import hashlib
import os
import stat
from pathlib import Path
from typing import Any

from fs_tool.utils.errors import ChecksumMismatchError, ConcurrencyError, NotAFileError

_HASH_CHUNK_SIZE = 1024 * 1024  # 1 MB


def hash_file(
    path: Path,
    *,
    expected_size: int | None = None,
    expected_mtime_ns: int | None = None,
    expected_stat: os.stat_result | None = None,
    chunk_size: int = _HASH_CHUNK_SIZE,
) -> str:
    """
    Compute SHA-256 of a regular file with concurrency detection.

    Args:
        path: Path to the file (must be a regular file, symlinks not followed)
        expected_size: If provided, verify file size hasn't changed
        expected_mtime_ns: If provided, verify mtime hasn't changed
        chunk_size: Read chunk size in bytes

    Returns:
        Hex digest of SHA-256 hash

    Raises:
        NotAFileError: If path is not a regular file
        ConcurrencyError: If file changes during hashing
    """
    # Open without following symlinks
    path_stat = path.lstat()
    if not stat.S_ISREG(path_stat.st_mode):
        raise NotAFileError(f"Not a regular file: {path}", path)
    if expected_stat is not None and (
        path_stat.st_dev,
        path_stat.st_ino,
    ) != (expected_stat.st_dev, expected_stat.st_ino):
        raise ConcurrencyError(f"File identity changed while hashing: {path}")
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    try:
        fd = os.open(path, flags)
    except OSError as error:
        if error.errno == errno.ELOOP:
            raise NotAFileError(f"Not a regular file: {path}", path) from error
        raise
    try:
        with os.fdopen(fd, "rb") as stream:
            opened_stat = os.fstat(stream.fileno())

            if not stat.S_ISREG(opened_stat.st_mode):
                raise NotAFileError(f"Not a regular file: {path}", path)

            # Verify against expected stat if provided
            if expected_size is not None and opened_stat.st_size != expected_size:
                raise ConcurrencyError(f"File size changed while hashing: {path}")
            if expected_mtime_ns is not None and opened_stat.st_mtime_ns != expected_mtime_ns:
                raise ConcurrencyError(f"File mtime changed while hashing: {path}")
            if (
                opened_stat.st_dev,
                opened_stat.st_ino,
            ) != (path_stat.st_dev, path_stat.st_ino):
                raise ConcurrencyError(f"File identity changed while hashing: {path}")

            digest = hashlib.sha256()
            while chunk := stream.read(chunk_size):
                digest.update(chunk)

            # Final verification
            final_stat = os.fstat(stream.fileno())
            if opened_stat.st_size != final_stat.st_size:
                raise ConcurrencyError(f"File size changed during hashing: {path}")
            if opened_stat.st_mtime_ns != final_stat.st_mtime_ns:
                raise ConcurrencyError(f"File mtime changed during hashing: {path}")

            return digest.hexdigest()
    finally:
        try:
            os.close(fd)
        except OSError:
            pass


def hash_bytes(data: bytes) -> str:
    """Compute SHA-256 of bytes."""
    return hashlib.sha256(data).hexdigest()


def verify_hash(path: Path, expected_hash: str, **kwargs) -> bool:
    """
    Verify file hash matches expected.

    Returns True if matches, raises ChecksumMismatchError if not.
    """
    actual = hash_file(path, **kwargs)
    if actual != expected_hash:
        raise ChecksumMismatchError(path, expected_hash, actual)
    return True


def canonical_json_hash(obj: Any) -> str:
    """Compute deterministic SHA-256 of JSON-serializable object."""
    import json

    canonical = json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode(
        "utf-8"
    )
    return hashlib.sha256(canonical).hexdigest()