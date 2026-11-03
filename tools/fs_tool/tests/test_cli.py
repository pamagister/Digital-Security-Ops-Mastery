from __future__ import annotations

import json
from pathlib import Path

import pytest

from fs_tool.main import main


def invoke(capsys: pytest.CaptureFixture[str], *args: str) -> tuple[int, dict]:
    exit_code = main(list(args))
    return exit_code, json.loads(capsys.readouterr().out)


def test_inventory_outputs_hashes_as_json(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    (tmp_path / "note.txt").write_text("contents", encoding="utf-8")

    exit_code, result = invoke(
        capsys, "--allow-root", str(tmp_path), "inventory", str(tmp_path)
    )

    assert exit_code == 0
    assert result["complete"] is True
    assert result["entries"][0]["sha256"]


def test_mutations_require_confirmation_and_dry_run_changes_nothing(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    source = tmp_path / "source.txt"
    source.write_text("data", encoding="utf-8")
    destination = tmp_path / "copy.txt"

    exit_code, result = invoke(
        capsys, "--allow-root", str(tmp_path), "copy", str(source), str(destination)
    )
    assert exit_code == 1
    assert "--yes" in result["error"]
    assert not destination.exists()

    exit_code, result = invoke(
        capsys,
        "--allow-root",
        str(tmp_path),
        "copy",
        str(source),
        str(destination),
        "--dry-run",
    )
    assert exit_code == 0
    assert result["dry_run"] is True
    assert not destination.exists()

    exit_code, result = invoke(
        capsys,
        "--allow-root",
        str(tmp_path),
        "copy",
        str(source),
        str(destination),
        "--yes",
    )
    assert exit_code == 0
    assert destination.read_text(encoding="utf-8") == "data"


def test_paths_outside_allowed_roots_are_rejected(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    allowed = tmp_path / "allowed"
    outside = tmp_path / "outside"
    allowed.mkdir()
    outside.mkdir()

    exit_code, result = invoke(capsys, "--allow-root", str(allowed), "list", str(outside))

    assert exit_code == 1
    assert "outside allowed roots" in result["error"]


def test_compare_returns_nonzero_when_content_is_missing(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    source = tmp_path / "source"
    destination = tmp_path / "destination"
    source.mkdir()
    destination.mkdir()
    (source / "file.txt").write_text("data", encoding="utf-8")

    exit_code, result = invoke(
        capsys,
        "--allow-root",
        str(tmp_path),
        "compare",
        str(source),
        str(destination),
    )

    assert exit_code == 1
    assert result["complete"] is True
    assert result["missing_entry_count"] == 1


def test_move_refuses_to_overwrite_and_moves_after_confirmation(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    source = tmp_path / "source.txt"
    destination = tmp_path / "destination.txt"
    source.write_text("source", encoding="utf-8")
    destination.write_text("existing", encoding="utf-8")

    exit_code, result = invoke(
        capsys,
        "--allow-root",
        str(tmp_path),
        "move",
        str(source),
        str(destination),
        "--yes",
    )

    assert exit_code == 1
    assert "already exists" in result["error"]
    assert source.exists()
    assert destination.read_text(encoding="utf-8") == "existing"


def test_argument_errors_are_json(capsys: pytest.CaptureFixture[str]) -> None:
    with pytest.raises(SystemExit) as error:
        main(["list"])

    assert error.value.code == 2
    assert json.loads(capsys.readouterr().out)["error"]
