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
- `get_file_info(path)` returns metadata without following the final path component when it is a symlink.
- `read_text_file(path, max_bytes)` reads bounded UTF-8 text and rejects symlinks, non-regular files, and oversized inputs.
- `create_directory(path)` creates a directory and missing parents; it fails if the target already exists.
- `copy_file(source, destination)` copies one regular file and refuses to follow a source symlink or overwrite an existing destination.
- `move_path(source, destination)` moves or renames a file, directory, or symlink and refuses an existing destination. Moving a filesystem root is rejected.

All paths may be absolute or use `~`. The tools accept any local path supplied by the MCP client; this is intentionally not an access-control boundary. Run the server only in a trusted local environment and only give the agent paths that should be accessed.

## Preservation verification workflow

1. Call `create_inventory` for each source tree before moving files. Require `complete: true`; resolve every reported error rather than treating a partial inventory as proof.
2. Let the agent plan and execute low-level operations. Review proposed destinations and ensure no files are unintentionally overwritten.
3. Call `create_inventory` for the resulting tree or trees.
4. Compare the returned relative paths, entry types, symlink targets, per-file SHA-256 values, and `tree_sha256`. A matching tree digest means the same relative structure and file contents were observed; expected path changes from a reorganization must be compared as explicit source-to-destination mappings instead of comparing the aggregate hashes directly.

The inventory is a point-in-time observation, not a filesystem lock. Avoid modifying files concurrently with inventory generation. Content is read to calculate hashes, so inventories can take time for large trees.

The server intentionally has no arbitrary delete operation. If an operation fails, inspect the returned error and re-inventory affected paths before retrying.
