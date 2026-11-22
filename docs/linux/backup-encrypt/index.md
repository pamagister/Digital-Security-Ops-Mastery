# Encrypt a directory backup

`backup_encrypt.sh` creates a password-protected `tar.gz` archive of a directory and encrypts it with OpenSSL AES-256-CBC and PBKDF2.

## ✨ Features

- Creates a `tar.gz` archive of a source directory.
- Encrypts the archive with a passphrase.
- Uses a temporary, permission-restricted passphrase file instead of exposing the passphrase on the command line.
- Refuses to overwrite an existing output file.
- Can be used from the terminal or from a KDE application launcher.

## ⚙️ Set-Up

### 📋 Requirements

- `tar`
- `openssl`
- Bash
- `konsole` only for the optional KDE launcher

### 📦 Installation

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/linux/backup-encrypt"

mkdir -p "$HOME/.local/bin"

curl -fL "$BASE_URL/backup_encrypt.sh" -o "$HOME/.local/bin/backup_encrypt.sh"
chmod +x "$HOME/.local/bin/backup_encrypt.sh"
```

Optional KDE launcher:

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/linux/backup-encrypt"

mkdir -p "$HOME/.local/share/applications"

curl -fL "$BASE_URL/backup_encrypt.desktop" \
    -o "$HOME/.local/share/applications/backup_encrypt.desktop"

sed -i "s|@HOME@|$HOME|g" "$HOME/.local/share/applications/backup_encrypt.desktop"
```

### 🔩 Manual installation

1. Download [`backup_encrypt.sh`](backup_encrypt.sh) to `~/.local/bin/`.
2. Make it executable:

   ```bash
   chmod +x ~/.local/bin/backup_encrypt.sh
   ```

3. Optional: download [`backup_encrypt.desktop`](backup_encrypt.desktop) to `~/.local/share/applications/` and replace `@HOME@` with your home directory.

## 🚀 Usage

Create a backup of a directory in the current directory:

```bash
~/.local/bin/backup_encrypt.sh ~/Documents
```

The output name defaults to `<source-name>_backup_<timestamp>.tar.gz.enc`.

Specify an output path:

```bash
~/.local/bin/backup_encrypt.sh ~/Documents /tmp/documents.tar.gz.enc
```

Enter the passphrase twice. Use a long, unique passphrase and store it in a password manager.

## 🔓 Restore

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -salt \
    -pass stdin -in documents.tar.gz.enc | tar -xzf -
```

Extract into a dedicated directory if the archive contains absolute or unexpected paths. Review the archive contents before extracting:

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -salt \
    -pass stdin -in documents.tar.gz.enc | tar -tzf - | less
```

## 📝 Notes / Warnings

- The backup is only as safe as the passphrase. Use a long, unique passphrase and keep a recovery copy in a password manager.
- The script does not securely erase the source or the output file. Deleting a file is not the same as sanitizing the storage medium.
- The archive contains the source directory name. Extract it into a dedicated directory.
- Test the restore before relying on the backup.
- The KDE launcher uses `@HOME@` as a placeholder. Replace it during installation.