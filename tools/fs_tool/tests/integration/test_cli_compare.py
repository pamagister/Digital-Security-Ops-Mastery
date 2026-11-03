"""Integration tests for fs-tool compare command."""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

import pytest


def run_fs_tool(root: Path, args: list[str]) -> subprocess.CompletedProcess:
    source = Path(__file__).parents[2] / "src"
    env = os.environ.copy()
    env["PYTHONPATH"] = os.pathsep.join(
        [str(source), env.get("PYTHONPATH", "")]
    ).rstrip(os.pathsep)
    cmd = [sys.executable, "-m", "fs_tool", "--allow-root", str(root), *args]
    return subprocess.run(cmd, capture_output=True, text=True, env=env)


def test_compare_basic(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    (source / "file.txt").write_text("content", encoding="utf-8")

    destination = tmp_path / "destination"
    destination.mkdir()
    (destination / "file.txt").write_text("content", encoding="utf-8")

    result = run_fs_tool(tmp_path, ["compare", str(source), str(destination)])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["complete"] is True
    assert data["source_entry_count"] == 1
    assert data["matched_entry_count"] == 1
    assert data["missing_entry_count"] == 0


def test_compare_missing_file(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    (source / "file.txt").write_text("content", encoding="utf-8")

    destination = tmp_path / "destination"
    destination.mkdir()

    result = run_fs_tool(tmp_path, ["compare", str(source), str(destination)])

    assert result.returncode == 1  # Missing entries -> exit code 1
    data = json.loads(result.stdout)
    assert data["complete"] is True
    assert data["source_entry_count"] == 1
    assert data["matched_entry_count"] == 0
    assert data["missing_entry_count"] == 1
    missing = data["missing_entries"][0]
    assert missing["sha256"] == hashlib.sha256(b"content").hexdigest()


def test_compare_different_content(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    (source / "file.txt").write_text("content a", encoding="utf-8")

    destination = tmp_path / "destination"
    destination.mkdir()
    (destination / "file.txt").write_text("content b", encoding="utf-8")

    result = run_fs_tool(tmp_path, ["compare", str(source), str(destination)])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert data["missing_entry_count"] == 1
    assert data["missing_entries"][0]["sha256"] == hashlib.sha256(b"content a").hexdigest()


def test_compare_ignores_paths_and_names(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    (source / "original.txt").write_text("same content", encoding="utf-8")

    destination = tmp_path / "destination"
    destination.mkdir()
    (destination / "renamed.dat").write_text("same content", encoding="utf-8")

    result = run_fs_tool(tmp_path, ["compare", str(source), str(destination)])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["missing_entry_count"] == 0


def test_compare_overlapping_sources_deduplicated(tmp_path: Path) -> None:
    source = tmp_path / "source"
    nested = source / "nested"
    nested.mkdir(parents=True)
    (source / "first.txt").write_text("same", encoding="utf-8")
    (nested / "second.txt").write_text("same", encoding="utf-8")

    destination = tmp_path / "destination"
    destination.mkdir()
    (destination / "kept.txt").write_text("same", encoding="utf-8")

    result = run_fs_tool(tmp_path, ["compare", str(source), str(nested), str(destination)])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert data["source_entry_count"] == 2
    assert data["matched_entry_count"] == 1
    assert data["missing_entry_count"] == 1
    missing = data["missing_entries"][0]
    origins = {o["path"] for o in missing["origins"]}
    assert origins == {"second.txt", "nested/second.txt"}


def test_compare_rejects_overlap(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    destination = source / "destination"
    destination.mkdir()

    result = run_fs_tool(tmp_path, ["compare", str(source), str(destination)])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert "error" in data
    assert "overlap" in data["error"].lower()


def test_compare_json_includes_missing_entries(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    (source / "file.txt").write_text("content", encoding="utf-8")
    destination = tmp_path / "destination"
    destination.mkdir()

    result = run_fs_tool(tmp_path, ["compare", str(source), str(destination)])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert "missing_entry_count" in data
    assert "missing_entries" in data
    assert "source_entry_count" in data


def test_compare_symlink_targets(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    destination = tmp_path / "destination"
    destination.mkdir()
    try:
        (source / "link").symlink_to("target")
        (destination / "link2").symlink_to("target")
    except (NotImplementedError, OSError):
        pytest.skip("Symlinks unavailable")

    result = run_fs_tool(tmp_path, ["compare", str(source), str(destination)])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["matched_entry_count"] == 1


def test_compare_incomplete_scan(tmp_path: Path) -> None:
    source = tmp_path / "source"
    source.mkdir()
    (source / "a.txt").write_text("a", encoding="utf-8")
    (source / "b.txt").write_text("b", encoding="utf-8")
    destination = tmp_path / "destination"
    destination.mkdir()

    result = run_fs_tool(
        tmp_path, ["compare", str(source), str(destination), "--max-entries", "1"]
    )

    assert result.returncode == 2  # Incomplete -> exit code 2
    data = json.loads(result.stdout)
    assert data["complete"] is False