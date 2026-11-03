"""Integration tests for fs-tool list command."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path


def run_fs_tool(root: Path, args: list[str]) -> subprocess.CompletedProcess:
    source = Path(__file__).parents[2] / "src"
    env = os.environ.copy()
    env["PYTHONPATH"] = os.pathsep.join(
        [str(source), env.get("PYTHONPATH", "")]
    ).rstrip(os.pathsep)
    cmd = [sys.executable, "-m", "fs_tool", "--allow-root", str(root), *args]
    return subprocess.run(cmd, capture_output=True, text=True, env=env)


def test_list_basic(tmp_path: Path) -> None:
    (tmp_path / "file.txt").write_text("content", encoding="utf-8")
    (tmp_path / "subdir").mkdir()

    result = run_fs_tool(tmp_path, ["list", str(tmp_path)])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["root"] == str(tmp_path.resolve())
    assert len(data["entries"]) == 2
    paths = {e["path"] for e in data["entries"]}
    assert "file.txt" in paths
    assert "subdir" in paths


def test_list_recursive(tmp_path: Path) -> None:
    (tmp_path / "root.txt").write_text("root", encoding="utf-8")
    subdir = tmp_path / "subdir"
    subdir.mkdir()
    (subdir / "nested.txt").write_text("nested", encoding="utf-8")

    result = run_fs_tool(tmp_path, ["list", str(tmp_path), "--recursive"])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert len(data["entries"]) == 3
    paths = {e["path"] for e in data["entries"]}
    assert "root.txt" in paths
    assert "subdir" in paths
    assert "subdir/nested.txt" in paths


def test_list_pagination(tmp_path: Path) -> None:
    (tmp_path / "a.txt").write_text("a", encoding="utf-8")
    (tmp_path / "b.txt").write_text("b", encoding="utf-8")
    (tmp_path / "c.txt").write_text("c", encoding="utf-8")

    result = run_fs_tool(tmp_path, ["list", str(tmp_path), "--limit", "2", "--offset", "0"])

    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert len(data["entries"]) == 2
    assert data["total_entries"] == 3
    assert data["next_offset"] == 2

    result2 = run_fs_tool(tmp_path, ["list", str(tmp_path), "--limit", "2", "--offset", "2"])
    data2 = json.loads(result2.stdout)
    assert len(data2["entries"]) == 1
    assert data2["next_offset"] is None


def test_list_json_is_the_default_output(tmp_path: Path) -> None:
    (tmp_path / "file.txt").write_text("content", encoding="utf-8")
    result = run_fs_tool(tmp_path, ["list", str(tmp_path)])
    assert result.returncode == 0
    assert json.loads(result.stdout)["entries"][0]["path"] == "file.txt"


def test_list_nonexistent(tmp_path: Path) -> None:
    result = run_fs_tool(tmp_path, ["list", str(tmp_path / "nonexistent")])

    assert result.returncode == 1
    data = json.loads(result.stdout)
    assert "error" in data