"""Integration tests for fs-tool mutation commands (copy, move, mkdir, info, read)."""

from __future__ import annotations

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


def test_copy_basic(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"

    result = run_fs_tool(tmp_path, ["copy", str(source), str(destination), "--yes"])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["destination"] == str(destination.resolve())
    assert destination.read_text(encoding="utf-8") == "data"


def test_copy_verifies_content(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"

    result = run_fs_tool(tmp_path, ["copy", str(source), str(destination), "--yes"])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["copied"] is True
    assert destination.read_text(encoding="utf-8") == "data"


def test_copy_refuses_overwrite(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"
    destination.write_text("existing", encoding="utf-8")

    result = run_fs_tool(tmp_path, ["copy", str(source), str(destination), "--yes"])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert "error" in data


def test_copy_rejects_symlink_source(tmp_path: Path) -> None:
    target = tmp_path / "target.txt"
    target.write_text("data", encoding="utf-8")
    link = tmp_path / "link.txt"
    try:
        link.symlink_to(target)
    except (NotImplementedError, OSError):
        pytest.skip("Symlinks unavailable")

    destination = tmp_path / "destination.txt"
    result = run_fs_tool(tmp_path, ["copy", str(link), str(destination), "--yes"])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert "error" in data


def test_copy_dry_run(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"

    result = run_fs_tool(tmp_path, ["copy", str(source), str(destination), "--dry-run"])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["dry_run"] is True
    assert not destination.exists()


def test_move_basic(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"

    result = run_fs_tool(tmp_path, ["move", str(source), str(destination), "--yes"])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["destination"] == str(destination.resolve())
    assert destination.read_text(encoding="utf-8") == "data"
    assert not source.exists()


def test_move_directory(tmp_path: Path) -> None:
    source = tmp_path / "source_dir"
    source.mkdir()
    (source / "file.txt").write_text("data", encoding="utf-8")
    destination = tmp_path / "destination_dir"

    result = run_fs_tool(tmp_path, ["move", str(source), str(destination), "--yes"])

    assert result.returncode == 0
    assert destination.is_dir()
    assert (destination / "file.txt").read_text(encoding="utf-8") == "data"
    assert not source.exists()


def test_move_refuses_overwrite(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"
    destination.write_text("existing", encoding="utf-8")

    result = run_fs_tool(tmp_path, ["move", str(source), str(destination), "--yes"])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert "error" in data


def test_move_dry_run(tmp_path: Path) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "destination.txt"

    result = run_fs_tool(tmp_path, ["move", str(source), str(destination), "--dry-run"])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["dry_run"] is True
    assert source.exists()
    assert not destination.exists()


def test_mkdir_basic(tmp_path: Path) -> None:
    new_dir = tmp_path / "new_dir"

    result = run_fs_tool(tmp_path, ["mkdir", str(new_dir), "--yes"])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["created"] is True
    assert new_dir.is_dir()


def test_mkdir_parents(tmp_path: Path) -> None:
    new_dir = tmp_path / "parent" / "child" / "grandchild"

    result = run_fs_tool(tmp_path, ["mkdir", str(new_dir), "--yes"])

    assert result.returncode == 0
    assert new_dir.is_dir()


def test_mkdir_refuses_existing(tmp_path: Path) -> None:
    existing = tmp_path / "existing"
    existing.mkdir()

    result = run_fs_tool(tmp_path, ["mkdir", str(existing), "--yes"])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert "error" in data


def test_info_file(tmp_path: Path) -> None:
    file_path = tmp_path / "test.txt"
    file_path.write_text("data", encoding="utf-8")

    result = run_fs_tool(tmp_path, ["info", str(file_path)])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["type"] == "file"
    assert data["size"] == 4


def test_info_symlink(tmp_path: Path) -> None:
    target = tmp_path / "target.txt"
    target.write_text("data", encoding="utf-8")
    link = tmp_path / "link.txt"
    try:
        link.symlink_to(target)
    except (NotImplementedError, OSError):
        pytest.skip("Symlinks unavailable")

    result = run_fs_tool(tmp_path, ["info", str(link)])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["type"] == "symlink"
    assert data["target"] == str(target)


def test_read_text(tmp_path: Path) -> None:
    file_path = tmp_path / "test.txt"
    file_path.write_text("hello world", encoding="utf-8")

    result = run_fs_tool(tmp_path, ["read", str(file_path), "--max-bytes", "100"])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["content"] == "hello world"


def test_read_size_limit(tmp_path: Path) -> None:
    file_path = tmp_path / "test.txt"
    file_path.write_text("hello world", encoding="utf-8")

    result = run_fs_tool(tmp_path, ["read", str(file_path), "--max-bytes", "5"])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert "error" in data
    assert "exceeds" in data["error"]


def test_read_rejects_symlink(tmp_path: Path) -> None:
    target = tmp_path / "target.txt"
    target.write_text("data", encoding="utf-8")
    link = tmp_path / "link.txt"
    try:
        link.symlink_to(target)
    except (NotImplementedError, OSError):
        pytest.skip("Symlinks unavailable")

    result = run_fs_tool(tmp_path, ["read", str(link)])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert "error" in data