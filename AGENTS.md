
# Repository Guidelines

This repository primarily contains Linux guides, documentation, shell scripts, and a smaller amount of Python code. 
Changes should prioritize clarity, safety, maintainability, and consistency with the existing structure.
These guidelines apply repository-wide. More specific instructions in a subdirectory or task may refine them. 
When instructions conflict, follow the most specific applicable instruction and preserve existing project conventions unless the requested change explicitly calls for updating them.

[] Finaly: Add with time and date a short report in english to temp/report.md that also can be used as commit message describing the changes made. Add this incrementally without modifying the previous report content.

## 🧭 General Guidelines

- Keep documentation practical, concise, and accessible to users with different levels of Linux experience.
- Prefer Bash for system automation and Python for tasks where it provides a clear advantage.
- Provide copy-paste installation instructions whenever they are useful and safe.
- Document manual installation as an alternative when appropriate.
- Use standard Linux user-level locations and avoid requiring root privileges for installation unless genuinely necessary.
- Keep scripts, documentation, and installation instructions consistent.
- Make the smallest change that fully solves the requested task.

## 📚 Documentation

- Write documentation in English unless the user or the specific document requests another language.
- Use Markdown headings in a logical hierarchy: one `#` title, followed by `##` sections and `###` subsections.
- Prefer concise explanations, lists, and tables over long paragraphs.
- Avoid redundant sections and repeated descriptions of the same feature.
- Do not copy large portions of a script into its README. Describe purpose, requirements, installation, usage, and important safety considerations.
- Keep documentation general enough to remain accurate when internal implementation details change.
- Use relative links for files within the repository.
- Verify links, filenames, commands, and destination paths after editing.
- Clearly distinguish optional features, requirements, warnings, and desktop-environment-specific behavior.
- Explain potentially destructive operations prominently and plainly.

## Emojis in Documentation

Emojis enrich documentation by making it more scannable and visually structured. Use them sparingly, consistently, and thematically appropriate.

### Emoji categories

| Category | Emoji | Usage |
|---|---|---|
| Overview / General | 🧭 | Overview, summary, introduction |
| Features / Functions | ✨ | Functionality, key features |
| Installation | 📦 | Installation, packaging |
| Setup / Configuration | ⚙️ | Setup, settings |
| Prerequisites | 📋 | Requirements, dependencies |
| Usage | 🚀 | Usage, application |
| Examples | 💡 | Examples, use cases |
| Security | 🔐 | Security, protection measures |
| Privacy | 🛡️ | Privacy, data control |
| Network / Internet | 🌐 | Network, internet, connections |
| Android / Smartphone | 📱 | Mobile devices, Android |
| Linux / Operating System | 🐧 | Linux, system administration |
| Backup / Restore | 💾 | Data backup, restore |
| Files / Directories | 📁 | File management, folder structure |
| Databases / Data | 🗄️ | Data storage, databases |
| Automation | 🔄 | Scripts, workflows, automation |
| Warnings / Risks | ⚠️ | Hazards, limitations, warnings |
| Troubleshooting | 🔧 | Troubleshooting, repairs |
| Documentation / Sources | 📚 | References, links, further information |
| Notes / Hints | 📝 | Additions, general notes |

### Additional optional emojis

| Category | Emoji |
|---|---|
| Success / Result | ✅ |
| Failed | ❌ |
| Important / Priority | ❗ |
| Tip / Recommendation | 🎯 |
| Time / Planning | ⏱️ |
| Terminal / CLI | 💻 |
| Git / Version Control | 🔀 |
| Development / Code | 🧑‍💻 |
| Cloud / Online Storage | ☁️ |
| Energy / Performance | ⚡ |

Every standard heading receives its dedicated emoji immediately before the title.

| Heading | Mandatory emoji |
|---|---|
| Overview / Übersicht | 🧭 |
| Features | ✨ |
| Set-Up | ⚙️ |
| Requirements | 📋 |
| Installation | 📦 |
| Manual installation | 🔩 |
| Usage | 🚀 |
| Examples (optional) | 💡 |
| Notes / Warnings (optional) | 📝 |

'''
Brief introduction and description of the project.

## ✨ Features

- Feature 1
- Feature 2

## ⚙️ Set-Up

### 📋 Requirements

List the prerequisites and specific dependencies.

### 📦 Installation

Describe the recommended installation procedure.

### 🔩 Manual installation

Describe alternative or manual installation procedures, if applicable.

## 🚀 Usage

Explain how to use the project.

## 💡 Examples (OPTIONAL)

Provide practical examples, if useful.

## 📝 Notes / Warnings (OPTIONAL)

Document important notes, limitations, warnings or additional information.
'''

### Additional rules

- The defined emojis are mandatory for the named standard headings.
- Additional topic-specific headings are expressly encouraged and should use matching emojis from the defined emoji system.
- The order of the standard chapters should generally be followed.
- Not relevant or not needed chapters (especially optional sections) may be omitted.
- Sensible additions, subsections, or minor deviations are allowed as long as they improve overview and understandability.
- Emojis serve orientation and should be used sparingly, consistently, and thematically appropriate.
- Within body text, lists, and warnings, emojis may additionally be used if they meaningfully support the information content.

## Shell Scripts (`.sh`)

- Use Bash when Bash features are required; start Bash scripts with `#!/usr/bin/env bash`.
- Prefer `set -Eeuo pipefail` for robust scripts, unless the script's control flow requires a documented exception.
- Quote variable expansions unless intentional word splitting or globbing is required.
- Use `printf` rather than relying on implementation-specific `echo` behavior.
- Check required commands and prerequisites before performing consequential operations.
- Handle errors explicitly and provide actionable messages.
- Use `sudo` only for operations that require elevated privileges.
- Avoid destructive actions without clear intent, safeguards, and appropriate user confirmation.
- Use functions for meaningful reusable operations; avoid unnecessary abstraction.
- Support `--help` when a script has command-line options or non-obvious behavior.
- Keep output readable and informative. Do not hide errors or imply success when a step failed.
- Test shell scripts with `bash -n` and, when available, ShellCheck.
- Consider interactive and non-interactive execution when prompts are involved.

## 🧑‍💻 Python (`.py`)

- Follow PEP 8 and the conventions already used in the project.
- Use four spaces for indentation and keep lines reasonably short (prefer a maximum of 100 characters).
- Add type hints where they improve readability or help maintain correctness.
- Prefer the standard library unless an external dependency provides a clear benefit.
- Keep functions focused and avoid speculative abstractions.
- Handle expected errors with useful messages; do not broadly suppress exceptions.
- Keep dependencies and setup instructions documented.
- Run relevant tests and available linting or formatting checks after changes.

## General Engineering Practices

### Think before implementing

- Identify assumptions and constraints before making changes.
- If a request has materially different interpretations, clarify them instead of silently choosing.
- Consider the simplest viable solution and explain meaningful trade-offs.
- Do not introduce features, configuration, or abstractions that were not requested.

### Simplicity first

- Implement only what is needed.
- Avoid overengineering, unnecessary dependencies, and single-use abstractions.
- Prefer straightforward code and documentation that a future contributor can easily maintain.

### Surgical changes

- Change only what is necessary for the task.
- Match the surrounding style and established conventions.
- Do not refactor unrelated code or documentation.
- Remove only unused code or imports introduced by the changes.
- Mention unrelated issues rather than fixing them without permission.

### Verify the result

- Define what success means for the task.
- Check modified scripts, commands, links, paths, and documentation for consistency.
- Run appropriate checks when possible (for example, `bash -n`, ShellCheck, Python tests, or Markdown/link checks).
- Do not claim a test or verification was performed if it was not.
- Summarize what changed and mention relevant checks or limitations.


## 📚 Document Structure

Use the following structure as the default for individual tool guides and README files:

# Title

Brief introduction describing the purpose of the tool or guide. Do not hardcode distribution versions (e.g. "24.04"); assume a current Ubuntu/Kubuntu LTS.

## Features (OPTIONAL)

List the main features and capabilities.

##  Set-Up

### Requirements

List the prerequisites and specific dependencies.

### Installation

Provide copy-paste installation instructions for the tool or script.
Use the following standard locations for user-level installations:

| File type / purpose | Recommended location |
| --- | --- |
| Executable user scripts | `~/.local/bin/` |
| Standard application launchers (`Type=Application`) | `~/.local/share/applications/` |
| KDE service-menu extensions (`Type=Service`) | Follow the existing project convention and verify the target KDE version's supported location |
| User-facing copies of application launchers | `~/Applications/` (when requested or useful) |
| User configuration | `~/.config/<application>/` |
| User data | `~/.local/share/<application>/` |
| Cache files | `~/.cache/<application>/` |

Installation instructions should:

1. Define a single `BASE_URL` pointing to the relevant directory in the repository's `main` branch when downloading raw files from GitHub.
2. Create only the directories required by the installation.
3. Download files with `curl -fL` so HTTP failures are reported.
4. Install executable scripts into `~/.local/bin/` and set the executable bit.
5. Install standard application launchers into `~/.local/share/applications/`.
6. Install KDE service-menu files into the repository's established service-menu location. Do not treat them as ordinary application launchers.
7. Replace repository placeholders such as `@HOME@` during installation when required. Do not leave unresolved placeholders in installed files.
8. Avoid `sudo` for installing files into the user's home directory.
9. Use `set -e` in copy-paste installation snippets so a failed command does not silently allow subsequent steps to continue.
10. Ensure that repeated installation or upgrade does not create unnecessary duplicate files or directories.

Example pattern for downloading a script and its KDE service-menu file:

```bash
set -e

BASE_URL="https://raw.githubusercontent.com/pamagister/Digital-Security-Ops-Mastery/main/docs/<section>"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/kservices5/ServiceMenus"

curl -fL "$BASE_URL/scripts/<script>.sh" \
    -o "$HOME/.local/bin/<script>.sh"

curl -fL "$BASE_URL/scripts/<service-menu>.desktop" \
    -o "$HOME/.local/share/kservices5/ServiceMenus/<service-menu>.desktop"

chmod +x "$HOME/.local/bin/<script>.sh"
```

This is a reference pattern, not a template to copy blindly. Adapt filenames, paths, placeholder handling, and desktop integration to the specific project and target environment. Preserve established repository conventions unless there is a verified reason to change them.

For standard application launchers, use `~/.local/share/applications/` instead of the KDE `ServiceMenus/` directory. If a visible personal copy is useful, place a configured copy in `~/Applications/`; keep the registered launcher in the standard applications directory.

### Manual installation

Optionally provide manual installation instructions as an alternative to the copy-paste installation. Manual instructions should:

- Provide manual installation instructions as an alternative to the copy-paste installation.
- When manual installation is documented:

- Link directly to the relevant files in the repository.
- List the destination paths explicitly.
- Explain any required placeholder replacement or configuration.
- Include required permissions, such as `chmod +x`, where applicable.
- Keep the manual steps concise and consistent with the copy-paste installation.
- Do not document a second procedure that differs from the automated installation without explaining why.

## Usage

- Explain the primary way to launch or use the tool first.
- Explain how to use the tool or script, including command-line usage and any interactive prompts.
- Include terminal usage when the tool provides a command-line interface.
- Document supported arguments and options, especially those that affect safety or behavior.
- Explain interactive prompts and any actions that may remove files, packages, or data.
- Do not repeat implementation details that can change frequently. Document user-visible behavior instead.
- Use examples that are valid, minimal, and copy-pasteable.

## Examples (OPTIONAL)

Provide minimal, copy-pasteable examples of usage.

## Notes / Warnings (OPTIONAL)

Clearly distinguish optional features, requirements, warnings, and desktop-environment-specific behavior. Explain potentially destructive operations prominently and plainly.

