"""Tests for fs-tool core inventory."""

from __future__ import annotations

import hashlib
from pathlib import Path

import pytest

from fs_tool.core import create_inventory, inventory_to_entries


def test_inventory_hashes_content_and_is_deterministic(tmp_path: Path) -> None:
    (tmp_path / "nested").mkdir()
    (tmp_path / "nested" / "note.txt").write_text("first", encoding="utf-8")

    first = create_inventory(str(tmp_path))
    again = create_inventory(str(tmp_path))

    assert first["complete"] is True
    assert first["tree_sha256"] == again["tree_sha256"]
    file_entry = next(entry for entry in first["entries"] if entry["type"] == "file")
    assert file_entry["sha256"] == hashlib.sha256(b"first").hexdigest()
    assert any(entry["type"] == "directory" for entry in first["entries"])

    (tmp_path / "nested" / "note.txt").write_text("second", encoding="utf-8")
    changed = create_inventory(str(tmp_path))
    assert changed["tree_sha256"] != first["tree_sha256"]


def test_inventory_reports_unfollowed_symlinks(tmp_path: Path) -> None:
    target = tmp_path / "target.txt"
    target.write_text("contents", encoding="utf-8")
    link = tmp_path / "link.txt"
    try:
        link.symlink_to(target)
    except (NotImplementedError, OSError):
        pytest.skip("Symlinks are unavailable")

    inventory = create_inventory(str(tmp_path))

    assert inventory["complete"] is True
    link_entry = next(entry for entry in inventory["entries"] if entry["path"] == "link.txt")
    assert link_entry["type"] == "symlink"
    assert link_entry["target"] == str(target)
    assert "sha256" not in link_entry


def test_inventory_is_incomplete_after_entry_limit(tmp_path: Path) -> None:
    (tmp_path / "a").write_text("a", encoding="utf-8")
    (tmp_path / "b").write_text("b", encoding="utf-8")

    inventory = create_inventory(str(tmp_path), max_entries=1)

    assert inventory["complete"] is False
    assert inventory["tree_sha256"] is None
    assert inventory["errors"]


def test_inventory_includes_empty_directories(tmp_path: Path) -> None:
    (tmp_path / "empty_dir").mkdir()
    (tmp_path / "file.txt").write_text("content", encoding="utf-8")

    inventory = create_inventory(str(tmp_path))

    assert inventory["complete"] is True
    dir_entry = next(e for e in inventory["entries"] if e["path"] == "empty_dir")
    assert dir_entry["type"] == "directory"
    assert dir_entry["size"] is None


def test_inventory_to_entries(tmp_path: Path) -> None:
    (tmp_path / "file.txt").write_text("content", encoding="utf-8")

    inventory = create_inventory(str(tmp_path))
    entries = inventory_to_entries(inventory)

    assert len(entries) == 1
    file_entry = next(e for e in entries if e.type == "file")
    assert file_entry.path == "file.txt"
    assert file_entry.sha256 == hashlib.sha256(b"content").hexdigest()