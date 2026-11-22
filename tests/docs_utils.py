"""Shared helpers for the documentation checks.

The Markdown in this repository is hand written and uses a narrow subset of
the syntax. The helpers therefore stay small and regex based on purpose: if a
new construct shows up, extend the extractor here instead of scattering
special cases across the tests.
"""

from __future__ import annotations

import re
import shlex
import time
import urllib.error
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_DIR = REPO_ROOT / "docs"
MKDOCS_CONFIG = REPO_ROOT / "mkdocs.yml"

# ```lang ... ``` and ~~~lang ... ~~~
FENCE_RE = re.compile(
    r"^(?P<fence>`{3,}|~{3,})(?P<lang>[^\n]*)\n(?P<body>.*?)^(?P=fence)[ \t]*$",
    re.M | re.S,
)

# [text](target) and ![alt](target), with an optional link title
LINK_RE = re.compile(r"!?\[[^\]]*\]\(\s*<?(?P<target>[^)>\s]+)>?(?:\s+\"[^\"]*\")?\s*\)")

# src="..." / href="..." inside inline HTML
HTML_REF_RE = re.compile(r"(?:src|href)\s*=\s*[\"'](?P<target>[^\"']+)[\"']")

# Snippet expansion
ASSIGN_RE = re.compile(r"^(?P<name>[A-Za-z_][A-Za-z0-9_]*)=(?P<value>.+)$")
FOR_RE = re.compile(r"^for\s+(?P<var>[A-Za-z_]\w*)\s+in\s+(?P<items>.+?)\s*;\s*do$")
VAR_RE = re.compile(r"\$\{(?P<braced>[A-Za-z_]\w*)\}|\$(?P<plain>[A-Za-z_]\w*)")

# raw.githubusercontent.com/<owner>/<repo>/<ref>/<path>
RAW_URL_RE = re.compile(r"^https?://raw\.githubusercontent\.com/[^/]+/[^/]+/[^/]+/(?P<path>.+)$")


def iter_markdown_files() -> list[Path]:
    """Return the documentation files plus the top level README."""
    files = sorted(DOCS_DIR.rglob("*.md"))
    readme = REPO_ROOT / "README.md"
    if readme.is_file():
        files.append(readme)
    return files


def iter_fenced_blocks(markdown: str):
    """Yield (language, body) for every fenced code block."""
    for match in FENCE_RE.finditer(markdown):
        yield match.group("lang").strip(), match.group("body")


def strip_fenced_blocks(markdown: str) -> str:
    """Remove fenced code blocks so their content is not scanned for links."""
    return FENCE_RE.sub("", markdown)


def iter_link_targets(markdown: str):
    """Yield every Markdown and inline HTML link target."""
    for match in LINK_RE.finditer(markdown):
        yield match.group("target")
    for match in HTML_REF_RE.finditer(markdown):
        yield match.group("target")


def is_external(target: str) -> bool:
    """True for links that are not resolved against the local file tree."""
    return target.startswith(("#", "//", "mailto:", "tel:", "data:", "http://", "https://"))


def split_anchor(target: str) -> tuple[str, str]:
    path, _, anchor = target.partition("#")
    return path, anchor


def resolve_target(source: Path, target: str) -> Path:
    """Resolve a link target relative to the file that contains it."""
    path, _ = split_anchor(target)
    return (source.parent / path).resolve()


def local_path_for_raw_url(url: str) -> Path | None:
    """Map a raw.githubusercontent.com URL to the matching file in the checkout."""
    match = RAW_URL_RE.match(url)
    if not match:
        return None
    return REPO_ROOT / match.group("path")


def iter_snippet_blocks():
    """Yield (guide, block_number, code) for install snippets that download files."""
    for md in sorted(DOCS_DIR.glob("*/*/index.md")):
        for number, (lang, code) in enumerate(
            iter_fenced_blocks(md.read_text(encoding="utf-8")), start=1
        ):
            if lang in {"bash", "sh"} and "curl" in code and "http" in code:
                yield md.parent.name, number, code


def iter_snippet_urls(code: str) -> tuple[list[str], list[str]]:
    """Expand a snippet and return (urls, problems).

    Only simple constructs are understood: ``VAR=value`` assignments and
    single ``for VAR in ...; do ... done`` loops. Anything that cannot be
    expanded is reported as a problem instead of being silently ignored.
    """
    env: dict[str, str] = {}
    urls: list[str] = []
    problems: list[str] = []

    lines = _join_continuations(code)
    index = 0
    while index < len(lines):
        line = lines[index].strip()
        index += 1
        if not line:
            continue

        assignment = ASSIGN_RE.match(line)
        if assignment:
            env[assignment.group("name")] = _strip_quotes(assignment.group("value"))
            continue

        loop = FOR_RE.match(line)
        if loop:
            body, index = _collect_loop_body(lines, index)
            for item in _strip_quotes(loop.group("items")).split():
                env[loop.group("var")] = item
                urls.extend(_urls_in(body, env, problems))
            env.pop(loop.group("var"), None)
            continue

        urls.extend(_urls_in([line], env, problems))

    return urls, problems


def fetch(url: str, attempts: int = 3, timeout: float = 20.0) -> tuple[int, bytes]:
    """GET a URL with a short retry budget for transient network errors."""
    last_error: Exception | None = None
    for attempt in range(attempts):
        try:
            request = urllib.request.Request(
                url, headers={"User-Agent": "dsom-docs-check/1.0"}
            )
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return response.status, response.read()
        except urllib.error.HTTPError as error:
            # A missing file will not appear on retry.
            raise RuntimeError(f"GET {url} returned HTTP {error.code}") from error
        except (urllib.error.URLError, TimeoutError, OSError) as error:
            last_error = error
            time.sleep(0.5 * (attempt + 1))
    raise RuntimeError(f"GET {url} failed after {attempts} attempts: {last_error}")


def _join_continuations(code: str) -> list[str]:
    lines: list[str] = []
    buffer = ""
    for raw in code.splitlines():
        if raw.rstrip().endswith("\\"):
            buffer += raw.rstrip()[:-1] + " "
            continue
        lines.append(buffer + raw)
        buffer = ""
    if buffer:
        lines.append(buffer)
    return lines


def _strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def _collect_loop_body(lines: list[str], start: int) -> tuple[list[str], int]:
    body: list[str] = []
    depth = 1
    while start < len(lines):
        line = lines[start].strip()
        start += 1
        if FOR_RE.match(line):
            depth += 1
        elif line == "done":
            depth -= 1
            if depth == 0:
                break
        body.append(line)
    return body, start


def _urls_in(lines: list[str], env: dict[str, str], problems: list[str]) -> list[str]:
    urls: list[str] = []
    for line in lines:
        if "curl" not in line:
            continue
        try:
            tokens = shlex.split(line)
        except ValueError as error:
            problems.append(f"cannot parse line {line!r}: {error}")
            continue
        for token in tokens:
            if token.startswith(("http://", "https://")):
                urls.append(token)
                continue
            expanded = _expand(token, env)
            if expanded is None:
                continue
            if expanded.startswith(("http://", "https://")):
                urls.append(expanded)
            elif "$" in expanded and _references_remote_base(token, env):
                problems.append(f"unresolved variable in URL token {token!r}")
    return urls


def _references_remote_base(token: str, env: dict[str, str]) -> bool:
    """True when the token uses a variable that holds a remote base URL."""
    for match in VAR_RE.finditer(token):
        value = env.get(match.group("braced") or match.group("plain"))
        if value and value.startswith(("http://", "https://")):
            return True
    return False


def _expand(token: str, env: dict[str, str]) -> str | None:
    """Expand the variables of a token that are known, leave the rest untouched.

    Returns None when the token does not reference any tracked variable, which
    is how unrelated arguments such as ``$HOME/.local/bin`` are ignored.
    """
    names = {
        match.group("braced") or match.group("plain") for match in VAR_RE.finditer(token)
    }
    if not names & env.keys():
        return None
    return VAR_RE.sub(lambda m: env.get(m.group("braced") or m.group("plain"), m.group(0)), token)