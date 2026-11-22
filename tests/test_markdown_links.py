"""Every local link in the documentation must resolve to an existing file."""

from __future__ import annotations

import pytest

from docs_utils import (
    REPO_ROOT,
    is_external,
    iter_link_targets,
    iter_markdown_files,
    resolve_target,
    split_anchor,
    strip_fenced_blocks,
)


def _relative(path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


MARKDOWN_FILES = iter_markdown_files()


@pytest.mark.parametrize("path", MARKDOWN_FILES, ids=_relative)
def test_markdown_files_are_not_empty(path):
    assert path.read_text(encoding="utf-8").strip(), f"{_relative(path)} is empty"


@pytest.mark.parametrize("path", MARKDOWN_FILES, ids=_relative)
def test_local_links_resolve(path):
    markdown = strip_fenced_blocks(path.read_text(encoding="utf-8"))

    broken = []
    for target in iter_link_targets(markdown):
        if is_external(target):
            continue
        link_path, _ = split_anchor(target)
        if not link_path:
            continue

        resolved = resolve_target(path, target)
        if resolved.is_dir():
            resolved = resolved / "index.md"

        if not resolved.is_file():
            try:
                shown = resolved.relative_to(REPO_ROOT)
            except ValueError:
                shown = resolved
            broken.append(f"{target} -> {shown}")

    assert not broken, f"broken links in {_relative(path)}:\n" + "\n".join(broken)