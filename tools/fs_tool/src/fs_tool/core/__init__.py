"""Core filesystem operations for fs-tool."""

from __future__ import annotations

from fs_tool.core.compare import compare_files_by_content, signature
from fs_tool.core.filesystem import (
    Entry,
    collect_entries,
    entry_type_from_mode,
    get_file_info,
    read_text_file,
)
from fs_tool.core.hashing import canonical_json_hash, hash_bytes, hash_file, verify_hash
from fs_tool.core.inventory import create_inventory, inventory_to_entries
from fs_tool.core.safety import atomic_copy, atomic_move, create_directory_safe, is_filesystem_root

__all__ = [
    # filesystem
    "Entry",
    "entry_type_from_mode",
    "collect_entries",
    "read_text_file",
    "get_file_info",
    # hashing
    "hash_file",
    "hash_bytes",
    "verify_hash",
    "canonical_json_hash",
    # inventory
    "create_inventory",
    "inventory_to_entries",
    # compare
    "compare_files_by_content",
    "signature",
    # safety
    "atomic_copy",
    "atomic_move",
    "create_directory_safe",
    "is_filesystem_root",
]