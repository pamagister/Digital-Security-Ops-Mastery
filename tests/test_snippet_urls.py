"""The download URLs inside the copy-paste snippets must resolve.

Every snippet is expanded textually (variables and ``for`` loops) and each
resulting URL is fetched. When the URL points at this repository, the served
bytes are compared with the committed file, which catches "resolves but serves
the wrong content".

The comparison against the ``main`` branch is intentional: the snippets tell
readers to download from ``main``. On a feature branch that changes a snippet
or its script the check therefore fails until the change is merged. Use
``DSOM_SKIP_NETWORK=1`` or ``-m "not network"`` for offline runs.
"""

from __future__ import annotations

import os

import pytest

from docs_utils import (
    REPO_ROOT,
    fetch,
    iter_snippet_blocks,
    iter_snippet_urls,
    local_path_for_raw_url,
)

BLOCKS = list(iter_snippet_blocks())

DOWNLOADS = [
    (f"{guide} block {number}: {url.rsplit('/', 1)[-1]}", url)
    for guide, number, code in BLOCKS
    for url in iter_snippet_urls(code)[0]
]


def _skip_if_offline():
    if os.environ.get("DSOM_SKIP_NETWORK") == "1":
        pytest.skip("network checks disabled via DSOM_SKIP_NETWORK=1")


def test_snippets_are_discovered():
    assert BLOCKS, "no install snippets with a download were found in docs/linux/*/index.md"


@pytest.mark.parametrize(
    "guide,number,code",
    BLOCKS,
    ids=[f"{guide} block {number}" for guide, number, _ in BLOCKS],
)
def test_snippet_urls_can_be_expanded(guide, number, code):
    urls, problems = iter_snippet_urls(code)
    assert not problems, f"cannot expand {guide} block {number}:\n" + "\n".join(problems)
    assert urls, f"no download URL found in {guide} block {number}"


@pytest.mark.network
@pytest.mark.parametrize("label,url", DOWNLOADS, ids=[label for label, _ in DOWNLOADS])
def test_download_url_resolves(label, url):
    _skip_if_offline()

    try:
        status, body = fetch(url)
    except RuntimeError as error:
        pytest.fail(f"{label}: {error}")

    assert status == 200, f"{label}: HTTP {status}"
    assert body, f"{label}: empty response body"

    local = local_path_for_raw_url(url)
    if local is not None and local.is_file():
        assert body == local.read_bytes(), (
            f"{label}: served content differs from {local.relative_to(REPO_ROOT)}"
        )