#!/usr/bin/env python3
"""Update the generated model catalog in opencode-template.jsonc.

Data sources:
- Kilo AI Gateway: free model discovery and provider metadata
- OpenRouter: model metadata, Artificial Analysis indices and OpenRouter evals
- OpenCode CLI: locally available models with an explicit free suffix

Successful API responses are cached under ~/.cache/opencode-model-catalog and
reused when a source is temporarily unreachable, so a network problem never
truncates the catalog.

The OpenRouter API key is read from OPENROUTER_API_KEY or the OS keyring.
No secrets are stored in this source file or in a .env file.
"""

from __future__ import annotations

import argparse
import getpass
import json
import logging
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

try:
    from rapidfuzz import fuzz
except ImportError as exc:
    raise SystemExit(
        "Missing dependency: rapidfuzz. Add 'rapidfuzz' to pyproject.toml."
    ) from exc


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_TEMPLATE = SCRIPT_DIR / "opencode-template.jsonc"

KILO_MODELS_URL = "https://ai-gateway.kilo.ai/api/v1/models"
OPENROUTER_MODELS_URL = "https://openrouter.ai/api/v1/models"
OPENROUTER_BENCHMARKS_URL = "https://openrouter.ai/api/v1/benchmarks"

# Each source exposes a different benchmark family via the same endpoint.
BENCHMARK_SOURCES = {
    "artificial-analysis": "Artificial Analysis",
    "openrouter": "OpenRouter evals",
}

BEGIN_MARKER = "// BEGIN AUTO-GENERATED FREE MODELS"
END_MARKER = "// END AUTO-GENERATED FREE MODELS"

KEYRING_SERVICE = "opencode-model-catalog"
KEYRING_USERNAME = "openrouter-api-key"

CACHE_DIR = Path(
    os.getenv("XDG_CACHE_HOME", str(Path.home() / ".cache"))
) / "opencode-model-catalog"
MAX_BACKUPS = 5

# Explicit aliases can be added here when two providers use substantially
# different identifiers for the same underlying model.
MODEL_ALIASES: dict[str, str] = {
    # "opencode/example-free": "provider/canonical-model-id",
}

FUZZY_MATCH_THRESHOLD = 91
FUZZY_MATCH_MARGIN = 4


@dataclass
class Model:
    provider: str
    model_id: str
    name: str
    context_length: int | None = None
    parameters: str | None = None
    intelligence: float | None = None
    coding: float | None = None
    agentic: float | None = None
    gpqa: float | None = None
    tau_bench: float | None = None
    description: str = ""
    metadata_source: str | None = None
    benchmark_match: str | None = None
    match_method: str | None = None
    is_free: bool = True
    extra: dict[str, Any] = field(default_factory=dict)

    @property
    def opencode_id(self) -> str:
        return f"{self.provider}/{self.model_id}"

    @property
    def rank_key(self) -> tuple[float, float, float, str]:
        # Missing scores sort after scored models.
        return (
            -(self.intelligence if self.intelligence is not None else -1.0),
            -(self.coding if self.coding is not None else -1.0),
            -(self.agentic if self.agentic is not None else -1.0),
            self.model_id.casefold(),
        )


def make_session() -> requests.Session:
    session = requests.Session()
    retry = Retry(
        total=3,
        connect=3,
        read=3,
        backoff_factor=0.6,
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=frozenset({"GET"}),
        respect_retry_after_header=True,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("https://", adapter)
    session.headers.update({"User-Agent": "opencode-model-catalog/1.0"})
    return session


def get_secure_keyring():
    """Return keyring only when backed by an OS credential store.

    In particular, reject plaintext fallback backends such as keyrings.alt.
    """
    try:
        import keyring
    except ImportError:
        return None

    backend = keyring.get_keyring()
    module = backend.__class__.__module__.casefold()
    secure_backend = any(
        marker in module
        for marker in ("kwallet", "secretservice", "libsecret", "winvault", "keychain")
    )
    if getattr(backend, "priority", 0) <= 0 or not secure_backend:
        logging.warning(
            "Refusing non-OS-backed or unavailable keyring backend: %s",
            backend.__class__.__name__,
        )
        return None
    return keyring


def get_openrouter_key() -> str | None:
    key = os.getenv("OPENROUTER_API_KEY")
    if key:
        return key.strip()

    keyring = get_secure_keyring()
    if keyring is None:
        return None

    try:
        return keyring.get_password(KEYRING_SERVICE, KEYRING_USERNAME)
    except Exception as exc:  # Keyring backends can fail when locked/headless.
        logging.warning("Could not read the OS keyring: %s", exc)
        return None


def store_openrouter_key() -> None:
    keyring = get_secure_keyring()
    if keyring is None:
        raise SystemExit(
            "No secure OS keyring backend is available. "
            "On Kubuntu, unlock/configure KDE Wallet or use OPENROUTER_API_KEY. "
            "Plaintext keyring backends are deliberately rejected."
        )

    key = getpass.getpass("OpenRouter API key (input hidden): ").strip()
    if not key:
        raise SystemExit("No key entered.")
    keyring.set_password(KEYRING_SERVICE, KEYRING_USERNAME, key)
    print("OpenRouter API key stored in the OS keyring.")


def get_json(
    session: requests.Session,
    url: str,
    *,
    params: dict[str, Any] | None = None,
    headers: dict[str, str] | None = None,
) -> dict[str, Any]:
    response = session.get(
        url,
        params=params,
        headers=headers,
        timeout=(8, 35),
    )
    response.raise_for_status()
    payload = response.json()
    if not isinstance(payload, dict):
        raise ValueError(f"Expected a JSON object from {url}")
    return payload


def data_list(payload: dict[str, Any], source: str) -> list[dict[str, Any]]:
    data = payload.get("data")
    if not isinstance(data, list):
        raise ValueError(f"Unexpected response from {source}: missing data[]")
    return [item for item in data if isinstance(item, dict)]


def _cache_path(key: str) -> Path:
    safe_key = re.sub(r"[^a-z0-9._-]+", "-", key.casefold())
    return CACHE_DIR / f"{safe_key}.json"


def write_cache(key: str, payload: dict[str, Any]) -> None:
    """Persist a successful response for later fallback. Never fatal."""
    path = _cache_path(key)
    try:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(
                {
                    "fetched_at": datetime.now().isoformat(timespec="seconds"),
                    "payload": payload,
                },
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
    except OSError as exc:  # A read-only or full cache must not break a run.
        logging.debug("Could not write cache %s: %s", path, exc)


def read_cache(key: str) -> tuple[dict[str, Any], str] | None:
    path = _cache_path(key)
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        logging.debug("No usable cache at %s: %s", path, exc)
        return None
    payload = raw.get("payload")
    if not isinstance(payload, dict):
        return None
    return payload, str(raw.get("fetched_at") or "unknown")


def load_json(
    session: requests.Session,
    url: str,
    cache_key: str,
    *,
    params: dict[str, Any] | None = None,
    headers: dict[str, str] | None = None,
    stale_sources: list[str] | None = None,
) -> dict[str, Any]:
    """Fetch JSON, falling back to the last successful cached response."""
    try:
        payload = get_json(session, url, params=params, headers=headers)
    except (requests.RequestException, ValueError) as exc:
        cached = read_cache(cache_key)
        if cached is None:
            raise
        payload, fetched_at = cached
        logging.warning(
            "Request for %s failed (%s); using cache from %s.",
            cache_key,
            exc,
            fetched_at,
        )
        if stale_sources is not None:
            stale_sources.append(f"{cache_key} (cached {fetched_at})")
        return payload

    write_cache(cache_key, payload)
    return payload


def is_free_kilo(item: dict[str, Any]) -> bool:
    if item.get("isFree") is True:
        return True
    model_id = str(item.get("id", ""))
    return model_id.endswith(":free")


def is_free_openrouter(item: dict[str, Any]) -> bool:
    return str(item.get("id", "")).endswith(":free")


def context_length(item: dict[str, Any]) -> int | None:
    value = item.get("context_length")
    if value is None:
        value = (item.get("top_provider") or {}).get("context_length")
    try:
        return int(value) if value is not None else None
    except (TypeError, ValueError):
        return None


def parse_parameters(description: str, model_id: str = "") -> str | None:
    """Extract total/active parameter counts from common model-card wording."""
    text = f"{description} {model_id}"

    patterns = (
        # "30B total parameters and 3B active"
        (
            r"(?P<total>\d+(?:\.\d+)?)\s*B\s+total\s+parameters?"
            r".{0,100}?(?P<active>\d+(?:\.\d+)?)\s*B\s+active"
        ),
        # "12B active parameters out of 120B total"
        (
            r"(?P<active>\d+(?:\.\d+)?)\s*B\s+active\s+parameters?"
            r".{0,100}?(?:out\s+of|from)\s+"
            r"(?P<total>\d+(?:\.\d+)?)\s*B\s+total"
        ),
        # "16B active parameters out of 280B total"
        (
            r"(?P<active>\d+(?:\.\d+)?)\s*B\s+active"
            r".{0,100}?(?P<total>\d+(?:\.\d+)?)\s*B\s+total"
        ),
    )

    for pattern in patterns:
        match = re.search(pattern, text, flags=re.IGNORECASE | re.DOTALL)
        if match:
            total = _format_parameter_number(match.group("total"))
            active = _format_parameter_number(match.group("active"))
            return f"{total}B/{active}B active"

    # Dense models often disclose only one parameter count.
    dense_match = re.search(
        r"(?P<count>\d+(?:\.\d+)?)\s*B\s+dense\b",
        text,
        flags=re.IGNORECASE,
    )
    if dense_match:
        return f"{_format_parameter_number(dense_match.group('count'))}B"

    # Model IDs such as "gemma-4-26b-a4b" expose total and active counts.
    id_match = re.search(
        r"(?P<total>\d+(?:\.\d+)?)b[-_]a(?P<active>\d+(?:\.\d+)?)b",
        model_id,
        flags=re.IGNORECASE,
    )
    if id_match:
        total = _format_parameter_number(id_match.group("total"))
        active = _format_parameter_number(id_match.group("active"))
        return f"{total}B/{active}B active"

    return None


def _format_parameter_number(value: str) -> str:
    number = float(value)
    return str(int(number)) if number.is_integer() else f"{number:g}"


def normalize_model_id(value: str) -> str:
    """Normalize provider prefixes, free suffixes and punctuation for matching."""
    value = value.casefold().strip()
    value = value.replace("\\", "/")
    value = value.lstrip("/")
    value = re.sub(r"^(kilo|openrouter|opencode)/", "", value)
    value = value.lstrip("~")
    value = re.sub(r":free$", "", value)
    value = re.sub(r"[-_]free$", "", value)
    value = re.sub(r"[^a-z0-9]+", "", value)
    return value


def normalize_name(value: str) -> str:
    value = value.casefold()
    value = re.sub(r"\([^)]*\)", " ", value)
    value = re.sub(r"\b(free|preview|instruct|chat|it)\b", " ", value)
    value = re.sub(r"[^a-z0-9]+", "", value)
    return value


def normalize_match_id(value: str, *, strip_date_suffix: bool = False) -> str:
    """Normalize a model ID, optionally ignoring a trailing YYYYMMDD version stamp."""
    if strip_date_suffix:
        value = re.sub(r"[-_]\d{8}$", "", value.strip())
    return normalize_model_id(value)


def add_candidate(
    models: dict[str, Model],
    provider: str,
    raw_id: str,
    name: str,
    *,
    context: int | None = None,
    description: str = "",
    metadata_source: str | None = None,
) -> None:
    raw_id = raw_id.strip()
    if not raw_id:
        return
    model_id = raw_id
    if model_id.startswith(f"{provider}/"):
        model_id = model_id[len(provider) + 1 :]

    key = f"{provider}/{model_id}".casefold()
    candidate = Model(
        provider=provider,
        model_id=model_id,
        name=name or model_id,
        context_length=context,
        parameters=parse_parameters(description, model_id),
        description=description,
        metadata_source=metadata_source,
    )

    existing = models.get(key)
    if existing is None:
        models[key] = candidate
        return

    # Prefer the richer metadata record when the same provider/model is
    # discovered through more than one route.
    if existing.context_length is None:
        existing.context_length = candidate.context_length
    if existing.parameters is None:
        existing.parameters = candidate.parameters
    if not existing.description and candidate.description:
        existing.description = candidate.description
    if existing.name == existing.model_id and candidate.name:
        existing.name = candidate.name


def discover_kilo(
    session: requests.Session,
    models: dict[str, Model],
    stale_sources: list[str],
) -> None:
    payload = load_json(
        session,
        KILO_MODELS_URL,
        "kilo-models",
        stale_sources=stale_sources,
    )
    items = data_list(payload, "Kilo")
    count = 0

    for item in items:
        if not is_free_kilo(item):
            continue
        model_id = str(item.get("id", ""))
        add_candidate(
            models,
            "kilo",
            model_id,
            str(item.get("name") or model_id),
            context=context_length(item),
            description=str(item.get("description") or ""),
            metadata_source="Kilo",
        )
        count += 1

    logging.info("Discovered %d free Kilo models.", count)


def discover_openrouter(
    session: requests.Session,
    models: dict[str, Model],
    stale_sources: list[str],
) -> dict[str, dict[str, Any]]:
    payload = load_json(
        session,
        OPENROUTER_MODELS_URL,
        "openrouter-models",
        stale_sources=stale_sources,
    )
    items = data_list(payload, "OpenRouter")
    catalog: dict[str, dict[str, Any]] = {}
    count = 0

    for item in items:
        raw_id = str(item.get("id", ""))
        if not raw_id:
            continue
        canonical = normalize_model_id(raw_id)
        catalog[canonical] = item

        if not is_free_openrouter(item):
            continue

        description = str(item.get("description") or "")
        add_candidate(
            models,
            "openrouter",
            raw_id,
            str(item.get("name") or raw_id),
            context=context_length(item),
            description=description,
            metadata_source="OpenRouter",
        )
        count += 1

    logging.info(
        "Loaded %d OpenRouter catalog entries; %d are explicitly free.",
        len(catalog),
        count,
    )
    return catalog


def parse_existing_models(template_text: str) -> dict[str, Model]:
    """Read model entries from the managed section before regenerating it."""
    begin = template_text.find(BEGIN_MARKER)
    end = template_text.find(END_MARKER)
    if begin < 0 or end < begin:
        raise ValueError("Cannot parse existing models: managed markers are missing.")

    section = template_text[begin:end]
    existing: dict[str, Model] = {}
    # Accept both commented and already-uncommented entries so that a user who
    # selected a model does not lose it during regeneration.
    pattern = re.compile(
        r'^\s*(?://\s*)?"model"\s*:\s*"([^"]+)"',
        re.MULTILINE,
    )
    for match in pattern.finditer(section):
        opencode_id = match.group(1).strip()
        if "/" not in opencode_id:
            continue
        provider, model_id = opencode_id.split("/", 1)
        is_free = model_id.endswith((":free", "-free"))
        existing[opencode_id.casefold()] = Model(
            provider=provider,
            model_id=model_id,
            name=model_id,
            metadata_source="Existing template",
            is_free=is_free,
        )
    return existing


def resolve_opencode_binary(explicit: str | None = None) -> Path | None:
    """Locate the OpenCode CLI even when PATH lacks the usual install dirs.

    IDEs and service managers often run Python with a reduced PATH, so relying
    on a bare "opencode" lookup makes the catalog silently lose its opencode/*
    entries.
    """
    candidates: list[str] = []
    for value in (explicit, os.getenv("OPENCODE_BIN")):
        if value:
            candidates.append(value)
    found = shutil.which("opencode")
    if found:
        candidates.append(found)
    candidates += [
        str(Path.home() / ".opencode" / "bin" / "opencode"),
        str(Path.home() / ".local" / "bin" / "opencode"),
        str(Path.home() / ".bun" / "bin" / "opencode"),
        "/usr/local/bin/opencode",
        "/usr/bin/opencode",
    ]

    for candidate in candidates:
        path = Path(candidate).expanduser()
        if path.is_file() and os.access(path, os.X_OK):
            return path
    return None


def query_opencode_models(binary: Path | None) -> list[str] | None:
    """Return the model IDs reported by the CLI, or None when unavailable."""
    try:
        result = subprocess.run(
            [str(binary), "models"],
            check=True,
            capture_output=True,
            text=True,
            timeout=30,
        )
    except (FileNotFoundError, subprocess.SubprocessError) as exc:
        name = str(binary) if binary else "no executable found"
        logging.warning(
            "Could not run '%s models': %s", name, exc or type(exc).__name__
        )
        return None

    return [
        line.strip()
        for line in result.stdout.splitlines()
        if "/" in line.strip()
    ]


def discover_opencode_cli(
    models: dict[str, Model],
    existing_models: dict[str, Model],
    binary: Path | None,
) -> bool:
    """Add free CLI models and retain existing entries that are still listed.

    Returns True when the CLI was queried successfully. When it is not
    available, every existing entry is retained unchanged instead of being
    dropped, so a broken PATH cannot truncate the catalog.
    """
    available = query_opencode_models(binary)
    if available is None:
        retained = 0
        for key, model in existing_models.items():
            if key in models:
                continue
            model.metadata_source = "Existing template (CLI unavailable)"
            models[key] = model
            retained += 1
        logging.warning(
            "OpenCode CLI unavailable (%s); kept %d existing entries unverified. "
            "Set OPENCODE_BIN or --opencode-bin to refresh them.",
            binary or "no executable found",
            retained,
        )
        return False

    available_ids = {line.casefold() for line in available}
    retained = 0
    for key, model in existing_models.items():
        if key not in available_ids or key in models:
            continue
        model.metadata_source = "Existing template + OpenCode CLI"
        models[key] = model
        retained += 1

    added = 0
    for line in available:
        if line.casefold() in models:
            continue
        provider, _, model_id = line.partition("/")
        if not provider or not model_id.strip():
            continue
        if not model_id.strip().endswith((":free", "-free")):
            continue
        add_candidate(
            models,
            provider,
            model_id.strip(),
            model_id.strip(),
            metadata_source="OpenCode CLI",
        )
        added += 1

    logging.info(
        "OpenCode CLI: %d entries retained, %d new free models added.",
        retained,
        added,
    )
    return True


def get_benchmarks(
    session: requests.Session,
    api_key: str,
    source: str,
    stale_sources: list[str],
) -> tuple[list[dict[str, Any]], str | None]:
    """Fetch one benchmark family from the OpenRouter rankings API."""
    payload = load_json(
        session,
        OPENROUTER_BENCHMARKS_URL,
        f"benchmarks-{source}",
        params={"source": source, "max_results": 5000},
        headers={"Authorization": f"Bearer {api_key}"},
        stale_sources=stale_sources,
    )
    items = data_list(payload, f"OpenRouter benchmarks ({source})")
    as_of = (payload.get("meta") or {}).get("as_of")
    logging.info(
        "Retrieved %d %s records (as of %s).",
        len(items),
        BENCHMARK_SOURCES[source],
        as_of,
    )
    return items, str(as_of) if as_of else None


def _candidate_name(item: dict[str, Any]) -> str:
    return str(item.get("display_name") or item.get("name") or "")


def find_best_match(
    model: Model,
    candidates: list[tuple[str, dict[str, Any]]],
    *,
    exact_alias: str | None = None,
    strip_date_suffix: bool = False,
) -> tuple[
    dict[str, Any] | None,
    str | None,
    str | None,
    list[tuple[float, str, str]],
]:
    """Find a conservative match and return the three best diagnostic candidates."""
    if not candidates:
        return None, None, None, []

    if exact_alias:
        alias_key = normalize_match_id(
            exact_alias,
            strip_date_suffix=strip_date_suffix,
        )
        for key, item in candidates:
            candidate_ids = [key, key.rsplit("/", 1)[-1]]
            if any(
                normalize_match_id(
                    candidate_id,
                    strip_date_suffix=strip_date_suffix,
                ) == alias_key
                for candidate_id in candidate_ids
            ):
                return item, key, "alias", [(100.0, key, _candidate_name(item))]

    # Model IDs and display names need different normalization rules.
    target_ids = {
        normalize_match_id(
            model.model_id,
            strip_date_suffix=strip_date_suffix,
        ),
        normalize_name(model.name),
    }
    target_ids.discard("")

    scored: list[tuple[float, str, dict[str, Any]]] = []
    for key, item in candidates:
        choices = [
            normalize_match_id(
                key,
                strip_date_suffix=strip_date_suffix,
            ),
            normalize_match_id(
                key.rsplit("/", 1)[-1],
                strip_date_suffix=strip_date_suffix,
            ),
            normalize_name(_candidate_name(item)),
        ]
        score = max(
            (
                fuzz.WRatio(target, choice)
                for target in target_ids
                for choice in choices
                if target and choice
            ),
            default=0,
        )
        scored.append((float(score), key, item))

    scored.sort(key=lambda row: (-row[0], row[1].casefold()))
    diagnostics = [
        (score, key, _candidate_name(item))
        for score, key, item in scored[:3]
    ]
    if not scored:
        return None, None, None, diagnostics

    best = scored[0]
    second_score = scored[1][0] if len(scored) > 1 else 0.0

    if best[0] >= 100:
        return best[2], best[1], "exact", diagnostics

    # Fuzzy matching remains deliberately conservative. Diagnostics expose
    # near misses without silently assigning a potentially incorrect score.
    if (
        best[0] >= FUZZY_MATCH_THRESHOLD
        and best[0] - second_score >= FUZZY_MATCH_MARGIN
    ):
        return best[2], best[1], f"fuzzy:{best[0]:.0f}", diagnostics

    return None, None, None, diagnostics


def enrich_from_openrouter_catalog(
    models: dict[str, Model],
    catalog: dict[str, dict[str, Any]],
) -> None:
    catalog_candidates = list(catalog.items())
    matched = 0

    for model in models.values():
        alias = MODEL_ALIASES.get(model.opencode_id)
        item, matched_id, method, _ = find_best_match(
            model,
            catalog_candidates,
            exact_alias=alias,
        )
        if not item:
            continue

        model.context_length = model.context_length or context_length(item)
        description = str(item.get("description") or "")
        model.description = model.description or description
        model.parameters = model.parameters or parse_parameters(
            description,
            str(item.get("id") or matched_id or ""),
        )
        model.metadata_source = (
            f"{model.metadata_source}+OpenRouter"
            if model.metadata_source and "OpenRouter" not in model.metadata_source
            else model.metadata_source or "OpenRouter"
        )
        matched += 1

    logging.info(
        "Enriched %d/%d candidates with OpenRouter catalog metadata.",
        matched,
        len(models),
    )


def aa_candidates(
    catalog: dict[str, dict[str, Any]],
    aa_items: list[dict[str, Any]],
) -> list[tuple[str, dict[str, Any]]]:
    """Merge Artificial Analysis records from the benchmark endpoint with the
    records embedded in the OpenRouter models catalog.

    The endpoint carries 176 records; the catalog embeds 204, including
    :free variants keyed by canonical_slug. Endpoint records take precedence
    when both sources describe the same model permaslug.
    """
    candidates: dict[str, dict[str, Any]] = {}
    for item in catalog.values():
        slug = item.get("canonical_slug")
        aa = (item.get("benchmarks") or {}).get("artificial_analysis")
        if slug and isinstance(aa, dict):
            candidates.setdefault(str(slug), aa)
    for item in aa_items:
        slug = str(item.get("model_permaslug") or "")
        if slug:
            candidates[str(slug)] = item
    return sorted(candidates.items())


def openrouter_eval_candidates(
    eval_items: list[dict[str, Any]],
) -> list[tuple[str, dict[str, Any]]]:
    """Collapse OpenRouter eval records into one entry per model, keeping the
    gpqa_diamond and tau_bench_verified_airline results when present."""
    by_slug: dict[str, dict[str, Any]] = {}
    for item in eval_items:
        slug = str(item.get("model_permaslug") or "")
        if not slug:
            continue
        entry = by_slug.setdefault(
            slug, {"gpqa_diamond": None, "tau_bench_verified_airline": None}
        )
        benchmark_type = str(item.get("benchmark_type") or "")
        if benchmark_type in entry and entry[benchmark_type] is None:
            entry[benchmark_type] = item

    candidates: list[tuple[str, dict[str, Any]]] = []
    for slug, entry in by_slug.items():
        merged: dict[str, Any] = {"model_permaslug": slug}
        for benchmark_type, record in entry.items():
            if record is not None:
                merged[f"eval_{benchmark_type}"] = record
        candidates.append((slug, merged))
    return sorted(candidates)


def _enrich_from_source(
    models: dict[str, Model],
    candidates: list[tuple[str, dict[str, Any]]],
    *,
    apply: Any,
    source_label: str,
    strip_date_suffix: bool = False,
) -> int:
    """Match models against benchmark candidates and apply one source's fields.

    Matching is conservative: near misses are logged as diagnostics, never
    silently assigned.
    """
    matched = 0
    for model in models.values():
        alias = MODEL_ALIASES.get(model.opencode_id)
        item, matched_id, method, top_candidates = find_best_match(
            model,
            candidates,
            exact_alias=alias,
            strip_date_suffix=strip_date_suffix,
        )
        if not item:
            suggestions = "; ".join(
                f"{key} ({score:.0f}: {name})"
                for score, key, name in top_candidates
            ) or "no candidates"
            logging.info(
                "%s: NO MATCH  %s | closest: %s",
                source_label,
                model.opencode_id,
                suggestions,
            )
            continue

        apply(model, item)
        model.benchmark_match = matched_id
        model.match_method = f"{source_label}:{method}"
        matched += 1
        logging.info(
            "%s: MATCH     %s -> %s [%s]",
            source_label,
            model.opencode_id,
            matched_id,
            method,
        )

    logging.info("%s: matched %d/%d models.", source_label, matched, len(models))
    return matched


def enrich_from_aa(
    models: dict[str, Model],
    candidates: list[tuple[str, dict[str, Any]]],
) -> int:
    def apply(model: Model, item: dict[str, Any]) -> None:
        model.intelligence = _to_float(item.get("intelligence_index"))
        model.coding = _to_float(item.get("coding_index"))
        model.agentic = _to_float(item.get("agentic_index"))

    return _enrich_from_source(
        models,
        candidates,
        apply=apply,
        source_label="Artificial Analysis",
        strip_date_suffix=True,
    )


def enrich_from_openrouter_evals(
    models: dict[str, Model],
    candidates: list[tuple[str, dict[str, Any]]],
    strip_date_suffix: bool = False,
) -> int:
    def apply(model: Model, item: dict[str, Any]) -> None:
        gpqa = item.get("eval_gpqa_diamond")
        if gpqa is not None:
            model.gpqa = _to_float(gpqa.get("accuracy"))
        tau = item.get("eval_tau_bench_verified_airline")
        if tau is not None:
            model.tau_bench = _to_float(tau.get("accuracy"))

    return _enrich_from_source(
        models,
        candidates,
        apply=apply,
        source_label="OpenRouter evals",
        strip_date_suffix=strip_date_suffix,
    )


def _to_float(value: Any) -> float | None:
    try:
        return float(value) if value is not None else None
    except (TypeError, ValueError):
        return None


def format_context(value: int | None) -> str:
    if value is None:
        return "n/a"
    if value >= 1_000_000:
        return f"{value / 1_000_000:g}M"
    if value >= 1_000:
        return f"{value / 1_000:g}K"
    return str(value)


def format_score(value: float | None) -> str:
    return f"{value:.1f}" if value is not None else "—"


def format_percent(value: float | None) -> str:
    return f"{value * 100:.1f}%" if value is not None else "—"


def generate_section(
    models: dict[str, Model],
    benchmark_as_of: str | None,
    used_sources: list[str],
    stale_sources: list[str],
) -> str:
    grouped: dict[str, list[Model]] = {}
    for model in models.values():
        grouped.setdefault(model.provider, []).append(model)

    lines = [
        BEGIN_MARKER,
        "// Automatically generated by update_model_catalog.py.",
        "// Scores: Artificial Analysis indices (0-100); higher is better.",
        f"// Benchmark snapshot: {benchmark_as_of or 'unavailable'}",
    ]
    if used_sources:
        names = ", ".join(BENCHMARK_SOURCES[source] for source in used_sources)
        lines.append(f"// Benchmark sources: {names}")
    for note in stale_sources:
        if note.startswith("benchmarks-"):
            lines.append(f"// NOTE: {note} — served from cache (stale).")
    lines.append("// Uncomment a model line to select it; existing entries are retained while available.")
    lines.append("")

    provider_order = {"kilo": 0, "openrouter": 1, "opencode": 2}
    for provider in sorted(
        grouped,
        key=lambda item: (provider_order.get(item, 99), item.casefold()),
    ):
        entries = sorted(grouped[provider], key=lambda item: item.rank_key)
        free_count = sum(model.is_free for model in entries)
        paid_count = len(entries) - free_count
        count_label = f"{free_count} free"
        if paid_count:
            count_label += f", {paid_count} retained paid"
        lines.append(f"// === {provider.upper()} ({count_label} models) ===")

        rendered = [
            (model, f'//  "model": "{model.opencode_id}",')
            for model in entries
        ]
        width = max((len(prefix) for _, prefix in rendered), default=0)

        for model, prefix in rendered:
            params = model.parameters or "n/a"
            comment = (
                f"I: {format_score(model.intelligence):>5} | "
                f"C: {format_score(model.coding):>5} | "
                f"A: {format_score(model.agentic):>5} | "
                f"GPQA: {format_percent(model.gpqa):>6} | "
                f"Params: {params:<18} | "
                f"Ctx: {format_context(model.context_length)}"
            )
            lines.append(f"{prefix:<{width}}  // {comment}")
        lines.append("")

    lines.append(END_MARKER)
    return "\n".join(lines)


def replace_managed_section(template_text: str, generated: str) -> str:
    begin_count = template_text.count(BEGIN_MARKER)
    end_count = template_text.count(END_MARKER)
    if begin_count != 1 or end_count != 1:
        raise ValueError(
            "Template must contain exactly one BEGIN and one END marker. "
            "Add the marker pair before running the script."
        )

    begin = template_text.index(BEGIN_MARKER)
    end = template_text.index(END_MARKER)
    if end < begin:
        raise ValueError("END marker appears before BEGIN marker.")

    end += len(END_MARKER)
    return template_text[:begin] + generated + template_text[end:]


def prune_backups(path: Path) -> None:
    """Keep only the most recent MAX_BACKUPS backups."""
    backups = sorted(
        path.parent.glob(f"{path.name}.bak.*"),
        key=lambda item: item.stat().st_mtime,
        reverse=True,
    )
    for old in backups[MAX_BACKUPS:]:
        try:
            old.unlink()
        except OSError as exc:
            logging.debug("Could not remove old backup %s: %s", old, exc)


def write_atomically(path: Path, content: str) -> None:
    original_mode = path.stat().st_mode
    backup = path.with_name(
        f"{path.name}.bak.{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    )
    shutil.copy2(path, backup)

    file_descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.",
        suffix=".tmp",
        dir=path.parent,
        text=True,
    )
    try:
        with os.fdopen(file_descriptor, "w", encoding="utf-8", newline="") as handle:
            handle.write(content)
        os.chmod(temporary_name, original_mode)
        os.replace(temporary_name, path)
        prune_backups(path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except FileNotFoundError:
            pass
        raise

    print(f"Updated: {path}")
    print(f"Backup:  {backup}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Discover and rank free OpenCode models."
    )
    parser.add_argument(
        "--template",
        type=Path,
        default=DEFAULT_TEMPLATE,
        help="JSONC template path (default: next to this script).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the generated section without modifying the template.",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Check whether the template matches the current sources without writing it. Run without --skip-benchmarks for a full comparison.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable debug logging.",
    )
    parser.add_argument(
        "--skip-benchmarks",
        action="store_true",
        help="Skip benchmark retrieval (scores remain unavailable).",
    )
    parser.add_argument(
        "--no-opencode-cli",
        action="store_true",
        help="Do not discover free models from the local 'opencode models' list.",
    )
    parser.add_argument(
        "--opencode-bin",
        type=Path,
        metavar="PATH",
        help="Path to the OpenCode CLI binary (default: auto-detect via PATH and common locations).",
    )
    parser.add_argument(
        "--store-api-key",
        action="store_true",
        help="Store the OpenRouter API key in the OS keyring and exit.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s: %(message)s",
    )

    if args.store_api_key:
        store_openrouter_key()
        return 0

    template_path = args.template.expanduser().resolve()
    if not template_path.is_file():
        logging.error("Template file not found: %s", template_path)
        return 1

    models: dict[str, Model] = {}
    stale_sources: list[str] = []
    benchmark_sources: dict[str, list[dict[str, Any]]] = {}
    session = make_session()

    try:
        discover_kilo(session, models, stale_sources)
        catalog = discover_openrouter(session, models, stale_sources)

        original = template_path.read_text(encoding="utf-8")
        existing_models = parse_existing_models(original)
        existing_keys = set(existing_models)

        binary = resolve_opencode_binary(args.opencode_bin)
        cli_available = False
        if not args.no_opencode_cli:
            cli_available = discover_opencode_cli(models, existing_models, binary)

        benchmark_as_of = None
        used_sources: list[str] = []
        if not args.skip_benchmarks:
            api_key = get_openrouter_key()
            if not api_key:
                logging.error(
                    "No OpenRouter API key found. Set OPENROUTER_API_KEY, "
                    "store it with --store-api-key, or use --skip-benchmarks."
                )
                return 2

            # Each source is fetched independently: one failing source is
            # logged and skipped instead of truncating the whole catalog.
            for source in ("artificial-analysis", "openrouter"):
                try:
                    items, as_of = get_benchmarks(
                        session, api_key, source, stale_sources
                    )
                    benchmark_sources[source] = items
                    used_sources.append(source)
                    if as_of and benchmark_as_of is None:
                        benchmark_as_of = as_of
                except Exception as exc:  # Cache may soften the failure.
                    logging.warning("Benchmark source %s unavailable: %s", source, exc)

        enrich_from_openrouter_catalog(models, catalog)

        if benchmark_sources.get("artificial-analysis"):
            enrich_from_aa(
                models,
                aa_candidates(catalog, benchmark_sources["artificial-analysis"]),
            )
        if benchmark_sources.get("openrouter"):
            enrich_from_openrouter_evals(
                models,
                openrouter_eval_candidates(benchmark_sources["openrouter"]),
                strip_date_suffix=True,
            )

        if not models:
            logging.error("No models discovered; template was not changed.")
            return 3

        kept = sum(1 for key in existing_keys if key in models)
        removed = sorted(key for key in existing_keys if key not in models)
        generated = generate_section(
            models, benchmark_as_of, used_sources, stale_sources
        )
        updated = replace_managed_section(original, generated)

        if args.verify:
            if updated == original:
                print("Verified: catalog is up to date.")
                return 0
            print("Verification failed: catalog differs from the current sources.")
            print("Run without --verify to update the template.")
            return 1

        if updated == original:
            print("No changes; catalog is already up to date.")
            return 0

        if args.dry_run:
            print(generated)
            print("\nDry run: template was not modified.")
            return 0

        write_atomically(template_path, updated)
        free = sum(model.is_free for model in models.values())
        paid = sum(not model.is_free for model in models.values())
        providers = {model.provider for model in models.values()}
        print(
            f"Catalog contains {free} free and {paid} retained paid model entries "
            f"across {len(providers)} providers."
        )
        print(f"Existing entries: {kept} retained, {len(removed)} dropped.")
        if removed:
            print(f"Dropped entries: {', '.join(removed)}")
        if stale_sources:
            print("Stale sources (cache used): " + "; ".join(stale_sources))
        if not cli_available and not args.no_opencode_cli:
            print(
                "Hint: the OpenCode CLI was not found; opencode/* entries were "
                "kept unverified. Use --opencode-bin PATH or set OPENCODE_BIN."
            )
        return 0

    except requests.RequestException as exc:
        logging.error("API request failed: %s", exc)
        return 4
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        logging.error("Catalog update failed: %s", exc)
        return 5
    finally:
        session.close()


if __name__ == "__main__":
    sys.exit(main())
