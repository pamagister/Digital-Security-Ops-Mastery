"""Integration tests for fs-tool inventory command."""

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


def test_inventory_basic(tmp_path: Path) -> None:
    (tmp_path / "file.txt").write_text("content", encoding="utf-8")
    (tmp_path / "subdir").mkdir()

    result = run_fs_tool(tmp_path, ["inventory", str(tmp_path)])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["complete"] is True
    assert data["entry_count"] == 2
    assert data["tree_sha256"] is not None
    file_entry = next(e for e in data["entries"] if e["type"] == "file")
    assert file_entry["sha256"] == hashlib.sha256(b"content").hexdigest()


def test_inventory_deterministic(tmp_path: Path) -> None:
    (tmp_path / "file.txt").write_text("content", encoding="utf-8")

    result1 = run_fs_tool(tmp_path, ["inventory", str(tmp_path)])
    result2 = run_fs_tool(tmp_path, ["inventory", str(tmp_path)])

    data1 = json.loads(result1.stdout)
    data2 = json.loads(result2.stdout)
    assert data1["tree_sha256"] == data2["tree_sha256"]


def test_inventory_symlink(tmp_path: Path) -> None:
    target = tmp_path / "target.txt"
    target.write_text("target content", encoding="utf-8")
    link = tmp_path / "link.txt"
    try:
        link.symlink_to(target)
    except (NotImplementedError, OSError):
        pytest.skip("Symlinks unavailable")

    result = run_fs_tool(tmp_path, ["inventory", str(tmp_path)])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    link_entry = next(e for e in data["entries"] if e["path"] == "link.txt")
    assert link_entry["type"] == "symlink"
    assert link_entry["target"] == str(target)
    assert "sha256" not in link_entry


def test_inventory_json_is_the_default_output(tmp_path: Path) -> None:
    (tmp_path / "file.txt").write_text("content", encoding="utf-8")
    result = run_fs_tool(tmp_path, ["inventory", str(tmp_path)])
    assert result.returncode == 0
    assert json.loads(result.stdout)["complete"] is True


def test_inventory_nonexistent(tmp_path: Path) -> None:
    result = run_fs_tool(tmp_path, ["inventory", str(tmp_path / "nonexistent")])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert "error" in data