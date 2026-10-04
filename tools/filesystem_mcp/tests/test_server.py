import hashlib
from pathlib import Path

import pytest

from tools.filesystem_mcp.server import (
    compare_files_by_content,
    copy_file,
    create_directory,
    create_inventory,
    get_file_info,
    list_entries,
    move_path,
    read_text_file,
)


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


def test_content_diff_ignores_paths_and_deduplicates_overlapping_sources(
    tmp_path: Path,
) -> None:
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

    with pytest.raises(ValueError, match="must not overlap"):
        compare_files_by_content([str(source)], str(destination))


def test_content_diff_reports_incomplete_inventory(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    (source / "a.txt").write_text("a", encoding="utf-8")
    (source / "b.txt").write_text("b", encoding="utf-8")
    destination = tmp_path / "destination"
    destination.mkdir()

    diff = compare_files_by_content(
        [str(source)], str(destination), max_entries=1
    )

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


def test_listing_paginates_and_text_read_is_bounded(tmp_path: Path) -> None:
    (tmp_path / "a.txt").write_text("alpha", encoding="utf-8")
    (tmp_path / "b.txt").write_text("beta", encoding="utf-8")

    page = list_entries(str(tmp_path), offset=0, limit=1)
    assert page["entries"][0]["path"] == "a.txt"
    assert page["next_offset"] == 1
    assert read_text_file(str(tmp_path / "a.txt"), max_bytes=5) == "alpha"
    with pytest.raises(ValueError, match="exceeds"):
        read_text_file(str(tmp_path / "a.txt"), max_bytes=4)


def test_mutations_do_not_overwrite_existing_files(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"

    assert copy_file(str(source), str(destination)) == str(destination)
    assert destination.read_text(encoding="utf-8") == "data"
    with pytest.raises(FileExistsError):
        copy_file(str(source), str(destination))

    moved = tmp_path / "renamed.txt"
    assert move_path(str(source), str(moved)) == str(moved)
    assert not source.exists()
    assert moved.read_text(encoding="utf-8") == "data"


def test_create_directory_and_file_info(tmp_path: Path) -> None:
    new_directory = tmp_path / "one" / "two"
    assert create_directory(str(new_directory)) == str(new_directory)
    with pytest.raises(FileExistsError):
        create_directory(str(new_directory))

    file_path = new_directory / "data.txt"
    file_path.write_text("data", encoding="utf-8")
    info = get_file_info(str(file_path))
    assert info["type"] == "file"
    assert info["size"] == 4


def test_read_and_copy_reject_symlink_sources(tmp_path: Path) -> None:
    target = tmp_path / "target.txt"
    target.write_text("data", encoding="utf-8")
    link = tmp_path / "link.txt"
    try:
        link.symlink_to(target)
    except (NotImplementedError, OSError):
        pytest.skip("Symlinks are unavailable")

    with pytest.raises(ValueError, match="regular file"):
        read_text_file(str(link))
    with pytest.raises(ValueError, match="regular file"):
        copy_file(str(link), str(tmp_path / "copy.txt"))
