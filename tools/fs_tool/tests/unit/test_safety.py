"""Tests for fs-tool core safety operations."""

from __future__ import annotations

from pathlib import Path

import pytest

from fs_tool.core import atomic_copy, atomic_move, create_directory_safe, is_filesystem_root
from fs_tool.utils.errors import AlreadyExistsError, NotAFileError, SafetyError


def test_atomic_copy(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"

    result = atomic_copy(source, destination)

    assert result == destination
    assert destination.read_text(encoding="utf-8") == "data"
    assert source.read_text(encoding="utf-8") == "data"  # source unchanged


def test_atomic_copy_verifies_hash(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"

    result = atomic_copy(source, destination, verify=True)

    assert result == destination
    assert destination.read_text(encoding="utf-8") == "data"


def test_atomic_copy_rejects_symlink_source(tmp_path: Path) -> None:
    target = tmp_path / "target.txt"
    target.write_text("data", encoding="utf-8")
    link = tmp_path / "link.txt"
    link.symlink_to(target)
    destination = tmp_path / "destination.txt"

    with pytest.raises(NotAFileError):
        atomic_copy(link, destination)


def test_atomic_copy_refuses_overwrite(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"
    destination.write_text("existing", encoding="utf-8")

    with pytest.raises(AlreadyExistsError):
        atomic_copy(source, destination)


def test_atomic_move(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"

    result = atomic_move(source, destination)

    assert result == destination
    assert destination.read_text(encoding="utf-8") == "data"
    assert not source.exists()


def test_atomic_move_directory(tmp_path: Path) -> None:
    source = tmp_path / "source_dir"
    source.mkdir()
    (source / "file.txt").write_text("data", encoding="utf-8")
    destination = tmp_path / "destination_dir"

    result = atomic_move(source, destination)

    assert result == destination
    assert destination.is_dir()
    assert (destination / "file.txt").read_text(encoding="utf-8") == "data"
    assert not source.exists()


def test_atomic_move_refuses_overwrite(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"
    destination.write_text("existing", encoding="utf-8")

    with pytest.raises(AlreadyExistsError):
        atomic_move(source, destination)


def test_atomic_move_refuses_filesystem_root(tmp_path: Path) -> None:
    root = Path("/")
    destination = tmp_path / "destination"

    with pytest.raises(SafetyError, match="filesystem root"):
        atomic_move(root, destination)


def test_is_filesystem_root() -> None:
    assert is_filesystem_root(Path("/")) is True
    assert is_filesystem_root(Path("/home")) is False
    assert is_filesystem_root(Path(".")) is False


def test_create_directory_safe(tmp_path: Path) -> None:
    new_dir = tmp_path / "new_dir"

    result = create_directory_safe(new_dir)

    assert result == new_dir.resolve()
    assert new_dir.is_dir()


def test_create_directory_safe_parents(tmp_path: Path) -> None:
    new_dir = tmp_path / "parent" / "child" / "grandchild"

    result = create_directory_safe(new_dir, parents=True)

    assert result == new_dir.resolve()
    assert new_dir.is_dir()


def test_create_directory_safe_refuses_existing(tmp_path: Path) -> None:
    existing = tmp_path / "existing"
    existing.mkdir()

    with pytest.raises(AlreadyExistsError):
        create_directory_safe(existing, exist_ok=False)


def test_create_directory_safe_exist_ok(tmp_path: Path) -> None:
    existing = tmp_path / "existing"
    existing.mkdir()

    result = create_directory_safe(existing, exist_ok=True)

    assert result == existing.resolve()