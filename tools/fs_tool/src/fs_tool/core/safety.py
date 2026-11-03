"""Safety utilities for atomic filesystem operations."""

from __future__ import annotations

import ctypes
import errno
import os
import shutil
import stat
import tempfile
from pathlib import Path

from fs_tool.core.hashing import hash_file
from fs_tool.utils.errors import (
    AlreadyExistsError,
    ConcurrencyError,
    NotAFileError,
    SafetyError,
)
from fs_tool.utils.paths import resolve_nofollow_leaf


def atomic_copy(
    source: str | Path,
    destination: str | Path,
    *,
    verify: bool = True,
    chunk_size: int = 1024 * 1024,
) -> Path:
    """
    Atomically copy a regular file without following source symlinks.

    Uses temp file + os.link + fsync for atomicity.
    Refuses to overwrite existing destination.

    Args:
        source: Source file path (symlinks not followed)
        destination: Destination file path
        verify: If True, verify content hash matches after copy
        chunk_size: Copy chunk size

    Returns:
        Destination path

    Raises:
        NotAFileError: If source is not a regular file
        AlreadyExistsError: If destination exists
        ConcurrencyError: If source changes during copy
    """
    source_path = resolve_nofollow_leaf(source)
    source_stat = source_path.lstat()

    if not stat.S_ISREG(source_stat.st_mode):
        raise NotAFileError(f"Source is not a regular file: {source_path}", source_path)

    destination_path = resolve_nofollow_leaf(destination)
    if destination_path.exists() or destination_path.is_symlink():
        raise AlreadyExistsError(
            f"Destination already exists: {destination_path}", destination_path
        )

    # Compute source hash before copy if verification requested
    source_hash = None
    if verify:
        source_hash = hash_file(
            source_path,
            expected_size=source_stat.st_size,
            expected_mtime_ns=source_stat.st_mtime_ns,
            chunk_size=chunk_size,
        )

    # Create temp file in destination directory
    fd, temp_name = tempfile.mkstemp(
        prefix=".fs-tool-", suffix=".tmp", dir=destination_path.parent
    )
    temp_path = Path(temp_name)

    try:
        # Copy with verification
        source_flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
        source_fd = os.open(source_path, source_flags)
        try:
            with os.fdopen(fd, "wb") as out_stream:
                with os.fdopen(source_fd, "rb") as in_stream:
                    opened_stat = os.fstat(in_stream.fileno())
                    if (opened_stat.st_dev, opened_stat.st_ino) != (
                        source_stat.st_dev,
                        source_stat.st_ino,
                    ):
                        raise ConcurrencyError(f"Source changed while copying: {source_path}")

                    shutil.copyfileobj(in_stream, out_stream, chunk_size)
                    out_stream.flush()
                    os.fsync(out_stream.fileno())

                    final_stat = os.fstat(in_stream.fileno())
                    if (opened_stat.st_size, opened_stat.st_mtime_ns) != (
                        final_stat.st_size,
                        final_stat.st_mtime_ns,
                    ):
                        raise ConcurrencyError(f"Source changed while copying: {source_path}")
        finally:
            try:
                os.close(source_fd)
            except OSError:
                pass

        # Preserve metadata (without following symlinks)
        shutil.copystat(source_path, temp_path, follow_symlinks=False)

        # Atomic replace via hard link (fails if destination exists)
        try:
            os.link(temp_path, destination_path, follow_symlinks=False)
        except FileExistsError:
            raise AlreadyExistsError(
                f"Destination already exists: {destination_path}", destination_path
            )

        # Verify destination hash if requested
        if verify and source_hash:
            dest_hash = hash_file(
                destination_path,
                expected_size=source_stat.st_size,
                expected_mtime_ns=source_stat.st_mtime_ns,
                chunk_size=chunk_size,
            )
            if dest_hash != source_hash:
                # Clean up on verification failure
                destination_path.unlink(missing_ok=True)
                raise ConcurrencyError(
                    f"Copy verification failed: hash mismatch for {destination_path}"
                )

        return destination_path

    finally:
        temp_path.unlink(missing_ok=True)


def atomic_move(source: str | Path, destination: str | Path) -> Path:
    """
    Atomically move/rename a file or directory.

    Refuses to overwrite existing destination.
    Refuses to move filesystem root.

    Args:
        source: Source path
        destination: Destination path

    Returns:
        Destination path

    Raises:
        AlreadyExistsError: If destination exists
        SafetyError: If attempting to move filesystem root
    """
    source_path = resolve_nofollow_leaf(source)
    if not source_path.exists() and not source_path.is_symlink():
        raise FileNotFoundError(source_path)

    if is_filesystem_root(source_path):
        raise SafetyError("Refusing to move a filesystem root")

    destination_path = resolve_nofollow_leaf(destination)
    if destination_path.exists() or destination_path.is_symlink():
        raise AlreadyExistsError(
            f"Destination already exists: {destination_path}", destination_path
        )

    _rename_noreplace(source_path, destination_path)
    return destination_path


def _rename_noreplace(source: Path, destination: Path) -> None:
    try:
        renameat2 = ctypes.CDLL(None, use_errno=True).renameat2
    except AttributeError as error:
        raise OSError(errno.ENOSYS, "Atomic no-overwrite move is unavailable") from error

    renameat2.argtypes = [
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_uint,
    ]
    renameat2.restype = ctypes.c_int
    result = renameat2(
        -100,
        os.fsencode(source),
        -100,
        os.fsencode(destination),
        1,
    )
    if result == 0:
        return

    error_number = ctypes.get_errno()
    if error_number == errno.EEXIST:
        raise AlreadyExistsError(
            f"Destination already exists: {destination}", destination
        )
    raise OSError(error_number, os.strerror(error_number), str(destination))


def is_filesystem_root(path: Path) -> bool:
    """Check if path is a filesystem root."""
    return bool(path.anchor) and path == Path(path.anchor)


def create_directory_safe(
    path: str | Path, *, parents: bool = True, exist_ok: bool = False
) -> Path:
    """
    Create directory with safety checks.

    Args:
        path: Directory path
        parents: Create parent directories
        exist_ok: If False, raise if directory exists

    Returns:
        Created directory path

    Raises:
        AlreadyExistsError: If directory exists and exist_ok=False
    """
    target = Path(path).expanduser()
    if target.exists() and not exist_ok:
        raise AlreadyExistsError(f"Directory already exists: {target}", target)
    target.mkdir(parents=parents, exist_ok=exist_ok)
    return target.resolve(strict=True)