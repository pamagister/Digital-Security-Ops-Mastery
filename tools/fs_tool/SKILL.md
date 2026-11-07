---
name: local-filesystem-cli
description: Use the local fs-tool CLI for filesystem listing, inventory, hashing, comparison, and guarded file operations.
---

# 🧭 Local Filesystem CLI

Use the `fs-tool` command from the `tools/fs_tool` package for low-level
filesystem operations. The agent decides file categories, naming, and operation
sequence; the tool does not automatically sort or delete files.

## ⚙️ Set-Up

### 📋 Requirements

- Python 3.13 or newer.

### 📦 Installation

Install the CLI from the repository root:

```bash
python -m pip install -e tools/fs_tool
```

The CLI is also directly runnable from the repository root:

```bash
PYTHONPATH=tools/fs_tool/src python -m fs_tool.main --help
```

All commands emit JSON by default. The current user's home directory is allowed
by default. To access another tree, pass `--allow-root PATH` before the command.

## 🚀 Usage

- `fs-tool list DIRECTORY [--recursive]` lists entries and reports whether the scan completed.
- `fs-tool inventory DIRECTORY` creates a deterministic inventory with SHA-256 per regular file.
- `fs-tool compare SOURCE... DESTINATION` reports source files not preserved by content.
- `fs-tool info PATH` returns metadata without following the final symlink.
- `fs-tool read PATH [--max-bytes N]` reads bounded UTF-8 text and rejects symlinks.
- `fs-tool mkdir PATH`, `fs-tool copy SOURCE DESTINATION`, and
  `fs-tool move SOURCE DESTINATION` change the filesystem only with `--yes`.
- Add `--dry-run` to a mutation to validate it and print the proposed change without applying it.

Mutations do not overwrite existing destinations. There is no delete command.
Copy accepts regular files only and verifies copied content. Moves may rename
files, directories, or symlinks. `--allow-root` is a tool-level guard, not an
operating-system sandbox; other tools or shell access are not restricted by it.

## 💾 Preservation verification

1. Copy or reorganize files only after reviewing the proposed layout.
2. Compare all specified source roots with the destination:

   ```bash
   fs-tool compare /path/to/source /path/to/destination
   ```

3. Require exit status `0` and `complete: true`; resolve every error and
   unsupported entry before relying on the result. Exit status `1` indicates
   missing content or an operation error; status `2` means the scan was incomplete.

Comparison matches regular files by SHA-256 and symlinks by literal target text,
independent of names and paths. Duplicate file occurrences are counted
separately. Overlapping source roots are deduplicated. Comparison does not verify
that relative symlinks still resolve correctly and does not preserve empty
directories; use `inventory` when exact tree structure also matters.

Inventory and comparison are point-in-time observations, not filesystem locks.
Avoid concurrent modifications while hashing. The tool does not enforce storage
quotas; account for available space before copying.


