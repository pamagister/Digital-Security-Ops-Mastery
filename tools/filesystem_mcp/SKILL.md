---
name: local-filesystem-mcp
description: Use the local filesystem MCP server for low-level listing, inventory, hashing, inspection, copying, and moving while keeping organization decisions with the agent.
---

# Local Filesystem MCP Server

This server provides low-level filesystem primitives for an agent that is organizing files. The agent decides the taxonomy, naming, and sequence of operations; the server does not infer categories or perform automatic sorting.

## Setup

The repository already declares `fastmcp` as a project dependency. From the repository root, run the server with:

```bash
python -m tools.filesystem_mcp.server
```

Configure the MCP client to launch that command in the repository's Python environment. The server uses the default FastMCP transport.

## Tools

- `list_entries(directory, recursive, offset, limit, max_entries)` lists entries with relative paths and types. Pages are limited to 5,000 entries. Recursive scans do not follow symlinks; any scan or entry-limit errors are included and make `complete` false.
- `create_inventory(directory, max_entries)` returns a deterministic sorted inventory. Each regular file has a SHA-256 of its content, symlinks include their target, and directories are represented (including empty directories). `tree_sha256` is only returned when the scan and all file hashes complete successfully.
- `compare_files_by_content(source_directories, destination_directory, max_entries)` reports source files not preserved in the destination. It compares regular files by SHA-256 and symlinks by their literal link target, independent of names and paths; duplicate content is counted per file occurrence. Overlapping source directories are deduplicated by absolute file path, with all source locations included in `origins`. Source and destination trees must not overlap. `complete` is false if a scan fails or an unsupported special file is found; inspect `errors` and `unsupported_entries` before relying on the diff.
- `get_file_info(path)` returns metadata without following the final path component when it is a symlink.
- `read_text_file(path, max_bytes)` reads bounded UTF-8 text and rejects symlinks, non-regular files, and oversized inputs.
- `create_directory(path)` creates a directory and missing parents; it fails if the target already exists.
- `copy_file(source, destination)` copies one regular file and refuses to follow a source symlink or overwrite an existing destination.
- `move_path(source, destination)` moves or renames a file, directory, or symlink and refuses an existing destination. Moving a filesystem root is rejected.

All paths may be absolute or use `~`. The tools accept any local path supplied by the MCP client; this is intentionally not an access-control boundary. Run the server only in a trusted local environment and only give the agent paths that should be accessed.

## Preservation verification workflow

1. After copying or reorganizing, call `compare_files_by_content` with all source roots and the destination root. Require `complete: true`; resolve every reported error and unsupported entry rather than treating a partial scan as proof.
2. Use `missing_entries` to locate source files without a matching destination copy. The comparison ignores changed names and paths, and counts identical-content files separately. If source roots overlap (for example, a parent and one of its subdirectories), each physical file is counted only once.
3. The comparison checks regular-file contents and symlink target text. It does not verify that relative symlinks still resolve correctly, and it does not preserve or compare empty directories. Use `create_inventory` when exact tree structure also needs verification.
4. This tool verifies preservation only; it does not copy files, enforce storage quotas, or prevent concurrent modifications. Plan the new layout to stay within any applicable storage limits, and avoid modifying files while the comparison is running.

For the user's current cleanup, the planned destination is `/home/paul/Dokumente_NEU/`. Use only the source directories the user specifies. `/home/paul/Dokumente/pauldata/` is inside `/home/paul/Dokumente/`, so selecting both does not double-count its files. Account for the stated free-space limits when planning: 1,000 MB in `/home/paul/Nextcloud/` and 200 MB in the `pauldata` SVN repository. The verifier does not enforce these limits.

The inventory is a point-in-time observation, not a filesystem lock. Avoid modifying files concurrently with inventory generation. Content is read to calculate hashes, so inventories can take time for large trees.

The server intentionally has no arbitrary delete operation. If an operation fails, inspect the returned error and re-inventory affected paths before retrying.
