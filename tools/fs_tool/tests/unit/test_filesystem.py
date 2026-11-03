"""Tests for fs-tool core filesystem operations."""

from __future__ import annotations

import pytest
from pathlib import Path

from fs_tool.core import (
    Entry,
    collect_entries,
    entry_type_from_mode,
    get_file_info,
    read_text_file,
)
from fs_tool.utils.errors import NotAFileError


def test_entry_type_from_mode() -> None:
    import stat
    assert entry_type_from_mode(stat.S_IFREG | 0o644) == "file"
    assert entry_type_from_mode(stat.S_IFDIR | 0o755) == "directory"
    assert entry_type_from_mode(stat.S_IFLNK | 0o777) == "symlink"
    assert entry_type_from_mode(stat.S_IFCHR | 0o644) == "other"


def test_collect_entries_basic(tmp_path: Path) -> None:
    (tmp_path / "file.txt").write_text("content", encoding="utf-8")
    (tmp_path / "subdir").mkdir()

    entries, errors = collect_entries(tmp_path)

    assert not errors
    assert len(entries) == 2
    paths = {e.path for e in entries}
    assert "file.txt" in paths
    assert "subdir" in paths


def test_collect_entries_recursive(tmp_path: Path) -> None:
    (tmp_path / "root.txt").write_text("root", encoding="utf-8")
    subdir = tmp_path / "subdir"
    subdir.mkdir()
    (subdir / "nested.txt").write_text("nested", encoding="utf-8")

    entries, errors = collect_entries(tmp_path, recursive=True)

    assert not errors
    assert len(entries) == 3
    paths = {e.path for e in entries}
    assert "root.txt" in paths
    assert "subdir" in paths
    assert "subdir/nested.txt" in paths


def test_collect_entries_symlink(tmp_path: Path) -> None:
    target = tmp_path / "target.txt"
    target.write_text("target content", encoding="utf-8")
    link = tmp_path / "link.txt"
    link.symlink_to(target)

    entries, errors = collect_entries(tmp_path)

    assert not errors
    link_entry = next(e for e in entries if e.path == "link.txt")
    assert link_entry.type == "symlink"
    assert link_entry.target == str(target)


def test_collect_entries_sorted(tmp_path: Path) -> None:
    (tmp_path / "z.txt").write_text("z", encoding="utf-8")
    (tmp_path / "a.txt").write_text("a", encoding="utf-8")
    (tmp_path / "m.txt").write_text("m", encoding="utf-8")

    entries, _ = collect_entries(tmp_path)

    paths = [e.path for e in entries]
    assert paths == ["a.txt", "m.txt", "z.txt"]


def test_collect_entries_limit(tmp_path: Path) -> None:
    (tmp_path / "a.txt").write_text("a", encoding="utf-8")
    (tmp_path / "b.txt").write_text("b", encoding="utf-8")

    entries, errors = collect_entries(tmp_path, max_entries=1)

    assert len(entries) == 1
    assert errors
    assert any("Entry limit reached" in e["error"] for e in errors)


def test_read_text_file(tmp_path: Path) -> None:
    file_path = tmp_path / "test.txt"
    file_path.write_text("hello world", encoding="utf-8")

    content = read_text_file(file_path, max_bytes=100)
    assert content == "hello world"


def test_read_text_file_size_limit(tmp_path: Path) -> None:
    file_path = tmp_path / "test.txt"
    file_path.write_text("hello world", encoding="utf-8")

    with pytest.raises(ValueError, match="exceeds max_bytes"):
        read_text_file(file_path, max_bytes=5)


def test_read_text_file_rejects_symlink(tmp_path: Path) -> None:
    target = tmp_path / "target.txt"
    target.write_text("data", encoding="utf-8")
    link = tmp_path / "link.txt"
    link.symlink_to(target)

    with pytest.raises(NotAFileError):
        read_text_file(link)


def test_get_file_info(tmp_path: Path) -> None:
    file_path = tmp_path / "test.txt"
    file_path.write_text("data", encoding="utf-8")

    info = get_file_info(file_path)

    assert info["type"] == "file"
    assert info["size"] == 4
    assert info["path"] == str(file_path)
    assert "modified_ns" in info
    assert "mode" in info


def test_get_file_info_symlink(tmp_path: Path) -> None:
    target = tmp_path / "target.txt"
    target.write_text("data", encoding="utf-8")
    link = tmp_path / "link.txt"
    link.symlink_to(target)

    info = get_file_info(link)

    assert info["type"] == "symlink"
    assert info["target"] == str(target)