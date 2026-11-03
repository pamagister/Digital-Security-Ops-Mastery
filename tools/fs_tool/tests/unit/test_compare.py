"""Tests for fs-tool core compare."""

from __future__ import annotations

import hashlib
from pathlib import Path

import pytest

from fs_tool.core import compare_files_by_content
from fs_tool.utils.errors import OverlapError


def test_content_diff_ignores_paths_and_deduplicates_overlapping_sources(tmp_path: Path) -> None:
    source = tmp_path / "source"
    nested = source / "nested"
    nested.mkdir(parents=True)
    (source / "first.txt").write_text("same contents", encoding="utf-8")
    (nested / "second.txt").write_text("same contents", encoding="utf-8")
    destination = tmp_path / "destination"
    destination.mkdir()
    (destination / "renamed.txt").write_text("same contents", encoding="utf-8")

    diff = compare_files_by_content([str(source), str(nested)], str(destination))

    assert diff["complete"] is True
    assert diff["source_entry_count"] == 2
    assert diff["matched_entry_count"] == 1
    assert diff["missing_entry_count"] == 1
    missing = diff["missing_entries"][0]
    assert missing["type"] == "file"
    assert missing["sha256"] == hashlib.sha256(b"same contents").hexdigest()
    assert {origin["path"] for origin in missing["origins"]} == {
        "second.txt",
        "nested/second.txt",
    }


def test_content_diff_rejects_overlapping_destination(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    destination = source / "destination"
    destination.mkdir()

    with pytest.raises(OverlapError, match="must not overlap"):
        compare_files_by_content([str(source)], str(destination))


def test_content_diff_reports_incomplete_inventory(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    (source / "a.txt").write_text("a", encoding="utf-8")
    (source / "b.txt").write_text("b", encoding="utf-8")
    destination = tmp_path / "destination"
    destination.mkdir()

    diff = compare_files_by_content([str(source)], str(destination), max_entries=1)

    assert diff["complete"] is False
    assert diff["errors"]


def test_content_diff_matches_symlink_targets(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    destination = tmp_path / "destination"
    destination.mkdir()
    try:
        (source / "old-name").symlink_to("payload")
        (destination / "new-name").symlink_to("payload")
    except (NotImplementedError, OSError):
        pytest.skip("Symlinks are unavailable")

    diff = compare_files_by_content([str(source)], str(destination))

    assert diff["complete"] is True
    assert diff["matched_entry_count"] == 1
    assert diff["missing_entries"] == []


def test_content_diff_counts_duplicates_per_occurrence(tmp_path: Path) -> None:
    """Same content in source twice, once in dest -> one missing."""
    source = tmp_path / "source"
    source.mkdir()
    (source / "a.txt").write_text("same", encoding="utf-8")
    (source / "b.txt").write_text("same", encoding="utf-8")
    destination = tmp_path / "destination"
    destination.mkdir()
    (destination / "c.txt").write_text("same", encoding="utf-8")

    diff = compare_files_by_content([str(source)], str(destination))

    assert diff["complete"] is True
    assert diff["source_entry_count"] == 2
    assert diff["matched_entry_count"] == 1
    assert diff["missing_entry_count"] == 1


def test_content_diff_different_content_not_matched(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    (source / "a.txt").write_text("content a", encoding="utf-8")
    destination = tmp_path / "destination"
    destination.mkdir()
    (destination / "b.txt").write_text("content b", encoding="utf-8")

    diff = compare_files_by_content([str(source)], str(destination))

    assert diff["complete"] is True
    assert diff["source_entry_count"] == 1
    assert diff["matched_entry_count"] == 0
    assert diff["missing_entry_count"] == 1
    assert diff["missing_entries"][0]["sha256"] == hashlib.sha256(b"content a").hexdigest()


def test_content_diff_multiple_sources(tmp_path: Path) -> None:
    source1 = tmp_path / "source1"
    source1.mkdir()
    (source1 / "a.txt").write_text("from source1", encoding="utf-8")

    source2 = tmp_path / "source2"
    source2.mkdir()
    (source2 / "b.txt").write_text("from source2", encoding="utf-8")

    destination = tmp_path / "destination"
    destination.mkdir()
    (destination / "a.txt").write_text("from source1", encoding="utf-8")

    diff = compare_files_by_content([str(source1), str(source2)], str(destination))

    assert diff["complete"] is True
    assert diff["source_entry_count"] == 2
    assert diff["matched_entry_count"] == 1
    assert diff["missing_entry_count"] == 1
    missing = diff["missing_entries"][0]
    assert missing["sha256"] == hashlib.sha256(b"from source2").hexdigest()
    assert len(missing["origins"]) == 1
    assert missing["origins"][0]["root"] == str(source2)


def test_content_diff_empty_destination(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    (source / "a.txt").write_text("content", encoding="utf-8")
    destination = tmp_path / "destination"
    destination.mkdir()

    diff = compare_files_by_content([str(source)], str(destination))

    assert diff["complete"] is True
    assert diff["source_entry_count"] == 1
    assert diff["matched_entry_count"] == 0
    assert diff["missing_entry_count"] == 1