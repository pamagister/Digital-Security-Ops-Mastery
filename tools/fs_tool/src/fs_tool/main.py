"""Command-line interface for safe, local filesystem operations."""

from __future__ import annotations

import argparse
import json
import os
import stat
from dataclasses import asdict
from pathlib import Path
from typing import Any, Sequence

from fs_tool.core import (
    atomic_copy,
    atomic_move,
    collect_entries,
    compare_files_by_content,
    create_directory_safe,
    create_inventory,
    get_file_info,
    is_filesystem_root,
    read_text_file,
)
from fs_tool.utils.errors import FSError
from fs_tool.utils.paths import expand_path


class JsonArgumentParser(argparse.ArgumentParser):
    def error(self, message: str) -> None:
        print(json.dumps({"error": message}, ensure_ascii=False))
        raise SystemExit(2)


def _parser() -> argparse.ArgumentParser:
    parser = JsonArgumentParser(
        prog="fs-tool",
        description="Inspect and safely organize files within allowed roots.",
    )
    parser.add_argument(
        "--allow-root",
        action="append",
        type=Path,
        metavar="PATH",
        help="Additional allowed root (repeatable; home is always allowed by default)",
    )
    commands = parser.add_subparsers(dest="command", required=True)

    listing = commands.add_parser("list", help="List directory entries")
    listing.add_argument("directory", type=Path)
    listing.add_argument("--recursive", "-r", action="store_true")
    listing.add_argument("--offset", type=int, default=0)
    listing.add_argument("--limit", type=int, default=1000)
    listing.add_argument("--max-entries", type=int, default=100_000)

    inventory = commands.add_parser("inventory", help="Hash files and inventory a tree")
    inventory.add_argument("directory", type=Path)
    inventory.add_argument("--max-entries", type=int, default=100_000)

    info = commands.add_parser("info", help="Show metadata for one path")
    info.add_argument("path", type=Path)

    read = commands.add_parser("read", help="Read a bounded UTF-8 text file")
    read.add_argument("path", type=Path)
    read.add_argument("--max-bytes", type=int, default=65_536)

    compare = commands.add_parser(
        "compare", help="Check whether source file contents exist in a destination"
    )
    compare.add_argument("sources", nargs="+", type=Path)
    compare.add_argument("destination", type=Path)
    compare.add_argument("--max-entries", type=int, default=100_000)

    mkdir = commands.add_parser("mkdir", help="Create a directory and missing parents")
    mkdir.add_argument("path", type=Path)

    copy = commands.add_parser("copy", help="Copy one regular file without overwriting")
    copy.add_argument("source", type=Path)
    copy.add_argument("destination", type=Path)

    move = commands.add_parser("move", help="Move or rename a path without overwriting")
    move.add_argument("source", type=Path)
    move.add_argument("destination", type=Path)

    for command in (mkdir, copy, move):
        command.add_argument(
            "--dry-run",
            action="store_true",
            help="Validate the operation and report what would change",
        )
        command.add_argument(
            "--yes",
            action="store_true",
            help="Confirm and perform the operation",
        )
    return parser


def _allowed_roots(extra_roots: list[Path] | None) -> list[Path]:
    roots = [Path.home().resolve(strict=True)]
    for root in extra_roots or []:
        resolved = expand_path(root).resolve(strict=True)
        if not resolved.is_dir():
            raise ValueError(f"Allowed root is not a directory: {resolved}")
        if resolved not in roots:
            roots.append(resolved)
    return roots


def _checked_path(path: Path, roots: list[Path], *, follow_leaf: bool = True) -> Path:
    expanded = expand_path(path)
    if follow_leaf or not expanded.name:
        resolved = expanded.resolve(strict=False)
    else:
        resolved = expanded.parent.resolve(strict=False) / expanded.name
    if not any(resolved == root or resolved.is_relative_to(root) for root in roots):
        raise PermissionError(f"Path is outside allowed roots: {path}")
    return resolved


def _require_directory(path: Path, roots: list[Path]) -> Path:
    resolved = _checked_path(path, roots)
    if not resolved.is_dir():
        raise NotADirectoryError(f"Not a directory: {resolved}")
    return resolved


def _require_confirmation(args: argparse.Namespace) -> None:
    if not args.dry_run and not args.yes:
        raise PermissionError("Mutation requires --yes; use --dry-run to preview")


def _run(args: argparse.Namespace, roots: list[Path]) -> tuple[dict[str, Any], int]:
    if args.command == "list":
        if args.offset < 0:
            raise ValueError("--offset must not be negative")
        if not 1 <= args.limit <= 5000:
            raise ValueError("--limit must be between 1 and 5000")
        directory = _require_directory(args.directory, roots)
        entries, errors = collect_entries(
            directory, recursive=args.recursive, max_entries=args.max_entries
        )
        result = {
            "root": str(directory),
            "entries": [asdict(entry) for entry in entries[args.offset : args.offset + args.limit]],
            "total_entries": len(entries),
            "offset": args.offset,
            "next_offset": (
                args.offset + args.limit
                if args.offset + args.limit < len(entries)
                else None
            ),
            "complete": not errors,
            "errors": errors,
        }
        return result, 0 if result["complete"] else 2

    if args.command == "inventory":
        directory = _require_directory(args.directory, roots)
        result = create_inventory(directory, max_entries=args.max_entries)
        return result, 0 if result["complete"] else 2

    if args.command == "info":
        path = _checked_path(args.path, roots, follow_leaf=False)
        return get_file_info(path), 0

    if args.command == "read":
        path = _checked_path(args.path, roots, follow_leaf=False)
        content = read_text_file(path, max_bytes=args.max_bytes)
        return {"path": str(path), "content": content, "encoding": "utf-8"}, 0

    if args.command == "compare":
        sources = [_require_directory(path, roots) for path in args.sources]
        destination = _require_directory(args.destination, roots)
        result = compare_files_by_content(
            sources, destination, max_entries=args.max_entries
        )
        if not result["complete"]:
            return result, 2
        return result, 1 if result["missing_entry_count"] else 0

    if args.command == "mkdir":
        _require_confirmation(args)
        path = _checked_path(args.path, roots)
        if args.dry_run:
            if os.path.lexists(path):
                raise FileExistsError(f"Path already exists: {path}")
            return {"dry_run": True, "operation": "mkdir", "path": str(path)}, 0
        created = create_directory_safe(path)
        return {"created": True, "path": str(created)}, 0

    if args.command == "copy":
        _require_confirmation(args)
        source = _checked_path(args.source, roots, follow_leaf=False)
        destination = _checked_path(args.destination, roots, follow_leaf=False)
        source_info = source.lstat()
        if not stat.S_ISREG(source_info.st_mode):
            raise ValueError(f"Source is not a regular file: {source}")
        if os.path.lexists(destination):
            raise FileExistsError(f"Destination already exists: {destination}")
        if not destination.parent.is_dir():
            raise NotADirectoryError(f"Destination parent is not a directory: {destination.parent}")
        if args.dry_run:
            return {
                "dry_run": True,
                "operation": "copy",
                "source": str(source),
                "destination": str(destination),
            }, 0
        copied = atomic_copy(source, destination)
        return {"copied": True, "source": str(source), "destination": str(copied)}, 0

    if args.command == "move":
        _require_confirmation(args)
        source = _checked_path(args.source, roots, follow_leaf=False)
        destination = _checked_path(args.destination, roots, follow_leaf=False)
        if not os.path.lexists(source):
            raise FileNotFoundError(source)
        if is_filesystem_root(source):
            raise ValueError("Refusing to move a filesystem root")
        if os.path.lexists(destination):
            raise FileExistsError(f"Destination already exists: {destination}")
        if not destination.parent.is_dir():
            raise NotADirectoryError(f"Destination parent is not a directory: {destination.parent}")
        if args.dry_run:
            return {
                "dry_run": True,
                "operation": "move",
                "source": str(source),
                "destination": str(destination),
            }, 0
        moved = atomic_move(source, destination)
        return {"moved": True, "source": str(source), "destination": str(moved)}, 0

    raise ValueError(f"Unsupported command: {args.command}")


def main(argv: Sequence[str] | None = None) -> int:
    parser = _parser()
    args = parser.parse_args(argv)
    try:
        roots = _allowed_roots(args.allow_root)
        result, exit_code = _run(args, roots)
    except (FSError, OSError, ValueError, PermissionError) as error:
        result = {"error": str(error)}
        exit_code = 1
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return exit_code


def cli() -> None:
    raise SystemExit(main())


if __name__ == "__main__":
    cli()
