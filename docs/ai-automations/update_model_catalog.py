#!/usr/bin/env python3
"""Update the free-model section in TEMPLATE_opencode.jsonc.

Data sources:
- Kilo AI Gateway: free model discovery and provider metadata
- OpenRouter: model metadata and Artificial Analysis benchmark indices
- OpenCode CLI: locally available models with an explicit free suffix

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
DEFAULT_TEMPLATE = SCRIPT_DIR / "TEMPLATE_opencode.jsonc"

KILO_MODELS_URL = "https://ai-gateway.kilo.ai/api/v1/models"
OPENROUTER_MODELS_URL = "https://openrouter.ai/api/v1/models"
OPENROUTER_BENCHMARKS_URL = "https://openrouter.ai/api/v1/benchmarks"

BEGIN_MARKER = "// BEGIN AUTO-GENERATED FREE MODELS"
END_MARKER = "// END AUTO-GENERATED FREE MODELS"

KEYRING_SERVICE = "opencode-model-catalog"
KEYRING_USERNAME = "openrouter-api-key"

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
    description: str = ""
    metadata_source: str | None = None
    benchmark_match: str | None = None
    match_method: str | None = None
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
) -> None:
    payload = get_json(session, KILO_MODELS_URL)
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
) -> dict[str, dict[str, Any]]:
    payload = get_json(session, OPENROUTER_MODELS_URL)
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


def discover_opencode_cli(models: dict[str, Model]) -> None:
    """Include locally configured OpenCode models with an explicit free suffix."""
    try:
        result = subprocess.run(
            ["opencode", "models"],
            check=True,
            capture_output=True,
            text=True,
            timeout=30,
        )
    except (FileNotFoundError, subprocess.SubprocessError) as exc:
        logging.warning("Could not query 'opencode models': %s", exc)
        return

    count = 0
    for line in result.stdout.splitlines():
        model_id = line.strip()
        if not model_id.startswith("opencode/"):
            continue
        bare_id = model_id.removeprefix("opencode/")
        if not (bare_id.endswith("-free") or bare_id.endswith(":free")):
            continue
        add_candidate(
            models,
            "opencode",
            bare_id,
            bare_id,
            metadata_source="OpenCode CLI",
        )
        count += 1

    logging.info("Discovered %d free OpenCode models.", count)


def get_benchmarks(
    session: requests.Session,
    api_key: str,
) -> tuple[list[dict[str, Any]], str | None]:
    payload = get_json(
        session,
        OPENROUTER_BENCHMARKS_URL,
        params={
            "source": "artificial-analysis",
            "max_results": 500,
        },
        headers={"Authorization": f"Bearer {api_key}"},
    )
    items = data_list(payload, "OpenRouter benchmarks")
    as_of = (payload.get("meta") or {}).get("as_of")
    logging.info("Retrieved %d benchmark records (as of %s).", len(items), as_of)
    return items, str(as_of) if as_of else None


def find_best_match(
    model: Model,
    candidates: list[tuple[str, dict[str, Any]]],
    *,
    exact_alias: str | None = None,
) -> tuple[dict[str, Any] | None, str | None, str | None]:
    if not candidates:
        return None, None, None

    if exact_alias:
        alias_key = normalize_model_id(exact_alias)
        for key, item in candidates:
            if normalize_model_id(key) == alias_key:
                return item, key, "alias"

    target_ids = {
        normalize_model_id(model.model_id),
        normalize_model_id(model.name),
    }
    target_ids.discard("")

    for key, item in candidates:
        candidate_ids = {
            normalize_model_id(key),
            normalize_name(str(item.get("display_name") or item.get("name") or "")),
        }
        if target_ids.intersection(candidate_ids):
            return item, key, "exact"

    # Fuzzy matching is deliberately conservative. A false match is worse
    # than missing benchmark data in a generated configuration.
    scored: list[tuple[float, str, dict[str, Any]]] = []
    for key, item in candidates:
        choices = [
            normalize_model_id(key),
            normalize_name(str(item.get("display_name") or item.get("name") or "")),
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

    scored.sort(key=lambda row: row[0], reverse=True)
    best = scored[0]
    second_score = scored[1][0] if len(scored) > 1 else 0.0

    if (
        best[0] >= FUZZY_MATCH_THRESHOLD
        and best[0] - second_score >= FUZZY_MATCH_MARGIN
    ):
        return best[2], best[1], f"fuzzy:{best[0]:.0f}"

    return None, None, None


def enrich_from_openrouter_catalog(
    models: dict[str, Model],
    catalog: dict[str, dict[str, Any]],
) -> None:
    catalog_candidates = list(catalog.items())
    matched = 0

    for model in models.values():
        alias = MODEL_ALIASES.get(model.opencode_id)
        item, matched_id, method = find_best_match(
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


def enrich_from_benchmarks(
    models: dict[str, Model],
    benchmarks: list[dict[str, Any]],
) -> None:
    candidates = [
        (str(item.get("model_permaslug") or ""), item)
        for item in benchmarks
        if item.get("model_permaslug")
    ]
    matched = 0

    for model in models.values():
        alias = MODEL_ALIASES.get(model.opencode_id)
        item, matched_id, method = find_best_match(
            model,
            candidates,
            exact_alias=alias,
        )
        if not item:
            continue

        model.intelligence = _to_float(item.get("intelligence_index"))
        model.coding = _to_float(item.get("coding_index"))
        model.agentic = _to_float(item.get("agentic_index"))
        model.benchmark_match = matched_id
        model.match_method = method
        matched += 1

    logging.info(
        "Matched benchmark data for %d/%d free model entries.",
        matched,
        len(models),
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


def generate_section(models: dict[str, Model], benchmark_as_of: str | None) -> str:
    grouped: dict[str, list[Model]] = {}
    for model in models.values():
        grouped.setdefault(model.provider, []).append(model)

    lines = [
        BEGIN_MARKER,
        "// Automatically generated by update_model_catalog.py.",
        "// Scores: Artificial Analysis indices (0-100); higher is better.",
        f"// Benchmark snapshot: {benchmark_as_of or 'unavailable'}",
        "// Uncomment a model line to select it; keep manual defaults outside this section.",
        "",
    ]

    provider_order = {"kilo": 0, "openrouter": 1, "opencode": 2}
    for provider in sorted(
        grouped,
        key=lambda item: (provider_order.get(item, 99), item.casefold()),
    ):
        entries = sorted(grouped[provider], key=lambda item: item.rank_key)
        lines.append(f"// === {provider.upper()} ({len(entries)} free models) ===")

        rendered = [
            (model, f'// "model": "{model.opencode_id}",')
            for model in entries
        ]
        width = max((len(prefix) for _, prefix in rendered), default=0)

        for model, prefix in rendered:
            params = model.parameters or "n/a"
            comment = (
                f"I: {format_score(model.intelligence):>5} | "
                f"C: {format_score(model.coding):>5} | "
                f"A: {format_score(model.agentic):>5} | "
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
    session = make_session()

    try:
        discover_kilo(session, models)
        catalog = discover_openrouter(session, models)

        if not args.no_opencode_cli:
            discover_opencode_cli(models)

        benchmark_as_of = None
        if not args.skip_benchmarks:
            api_key = get_openrouter_key()
            if not api_key:
                logging.error(
                    "No OpenRouter API key found. Set OPENROUTER_API_KEY, "
                    "store it with --store-api-key, or use --skip-benchmarks."
                )
                return 2

            benchmarks, benchmark_as_of = get_benchmarks(session, api_key)
            enrich_from_benchmarks(models, benchmarks)

        enrich_from_openrouter_catalog(models, catalog)

        if not models:
            logging.error("No free models discovered; template was not changed.")
            return 3

        generated = generate_section(models, benchmark_as_of)
        original = template_path.read_text(encoding="utf-8")
        updated = replace_managed_section(original, generated)

        if updated == original:
            print("No changes; catalog is already up to date.")
            return 0

        if args.dry_run:
            print(generated)
            print("\nDry run: template was not modified.")
            return 0

        write_atomically(template_path, updated)
        print(
            f"Catalog contains {len(models)} free model entries "
            f"across {len({model.provider for model in models.values()})} providers."
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
