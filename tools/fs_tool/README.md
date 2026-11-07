# fs-tool

A small Python CLI for inspecting filesystem contents and carrying out controlled
file operations. Results are JSON by default; filesystem logic is reusable from
Python without a server process.

## ✨ Features

- List directory entries and create deterministic SHA-256 inventories.
- Compare source and destination trees by file content to verify preservation.
- Inspect metadata and create directories, copy files, or move paths.
- Read bounded UTF-8 text files without following symlinks.
- Limit access to the home directory and explicitly allowed roots.
- Require `--yes` for changes, refuse existing destinations, and support `--dry-run`.

## ⚙️ Set-Up

### 📋 Requirements

- Python 3.13 or newer.

### 📦 Installation

From the repository root, install the standalone tool into the active Python
environment:

```bash
python -m pip install -e tools/fs_tool
```

For development and tests:

```bash
python -m pip install -e "tools/fs_tool[dev]"
```

### 🔩 Manual installation

The CLI can also be run directly from the repository root:

```bash
PYTHONPATH=tools/fs_tool/src python -m fs_tool.main --help
```

## 🚀 Usage

```bash
fs-tool list ~/Downloads
fs-tool inventory ~/Documents
fs-tool info ~/Documents/report.pdf
fs-tool read ~/Documents/notes.txt --max-bytes 65536
fs-tool compare ~/Documents ~/Documents_NEU
```

The default output is JSON. For mutations, preview first and then explicitly
confirm:

```bash
fs-tool copy ~/Downloads/report.pdf ~/Documents_NEU/report.pdf --dry-run
fs-tool copy ~/Downloads/report.pdf ~/Documents_NEU/report.pdf --yes
fs-tool move ~/Downloads/old.pdf ~/Documents_NEU/old.pdf --yes
fs-tool mkdir ~/Documents_NEU/Projects --yes
```

All paths must be within the current user's home directory or a root supplied
before the command with `--allow-root PATH`. Additional roots can be supplied
repeatedly. For example:

```bash
fs-tool --allow-root /mnt/archive inventory /mnt/archive
```

`compare` exits with status `0` when the scan is complete and no files are
missing, `1` when files are missing or an operation fails, and `2` when the
scan is incomplete. Inspect `complete`, `errors`, and `unsupported_entries`
before treating a comparison as proof of preservation.

## 🔐 Safety and limitations

- Copy accepts regular files only, does not follow a source symlink, verifies the
  copied content, and refuses to overwrite an existing destination.
- Move supports files, directories, and symlinks, refuses existing destinations
  and filesystem roots, and does not delete data.
- Inventory is a point-in-time scan, not a filesystem lock. Do not modify the
  tree concurrently if the result is being used as a preservation proof.
- Root restrictions apply only to `fs-tool`; they cannot restrict a separate
  shell process or another tool used by an agent.


