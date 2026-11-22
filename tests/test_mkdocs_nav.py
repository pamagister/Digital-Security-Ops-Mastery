"""Every navigation entry in mkdocs.yml must point at an existing page.

mkdocs.yml uses the custom ``!ENV`` tag, so a loader that tolerates unknown
tags is used instead of ``yaml.safe_load``.
"""

from __future__ import annotations

import pytest
import yaml

from docs_utils import DOCS_DIR, MKDOCS_CONFIG


class _ConfigLoader(yaml.SafeLoader):
    """SafeLoader that ignores unknown tags such as !ENV."""


_ConfigLoader.add_constructor("!ENV", lambda loader, node: None)


def _walk_nav(node):
    if isinstance(node, str):
        yield node
    elif isinstance(node, list):
        for item in node:
            yield from _walk_nav(item)
    elif isinstance(node, dict):
        for value in node.values():
            yield from _walk_nav(value)


@pytest.fixture(scope="module")
def nav_entries():
    if not MKDOCS_CONFIG.is_file():
        pytest.skip("mkdocs.yml not found")
    config = yaml.load(MKDOCS_CONFIG.read_text(encoding="utf-8"), Loader=_ConfigLoader)
    return list(_walk_nav(config.get("nav") or []))


def test_nav_is_not_empty(nav_entries):
    assert nav_entries, "mkdocs.yml defines no navigation entries"


def test_nav_targets_exist(nav_entries):
    missing = sorted(
        entry for entry in set(nav_entries) if not (DOCS_DIR / entry).is_file()
    )
    assert not missing, "mkdocs.yml navigation entries without a file:\n" + "\n".join(missing)