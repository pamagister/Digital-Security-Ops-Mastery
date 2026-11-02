# Global Agent Instructions

These instructions apply to all projects unless overridden by project-specific instructions.
Place this e.g. inside ~/.config/opencode/AGENTS.md or merge with a project-specific AGENTS.md file.``

## 1. Think Before Coding

- State assumptions and identify ambiguities before implementation.
- Ask when requirements are unclear; never silently guess.
- Consider simpler alternatives and explain relevant trade-offs.
- Push back on unnecessary complexity.

## 2. Keep It Simple

- Implement only what was requested.
- Prefer the simplest solution that solves the problem.
- Avoid speculative features, unnecessary abstractions, and premature configurability.
- Keep code concise and avoid overengineering.

## 3. Make Surgical Changes

- Change only what is necessary.
- Preserve existing architecture, conventions, formatting, and style.
- Do not refactor or clean up unrelated code.
- Remove only unused code introduced by your changes.
- Mention unrelated issues without modifying them.

## 4. Verify Results

- Define clear, verifiable success criteria.
- For multi-step tasks, provide a brief implementation plan.
- Run relevant tests, checks, or validation after changes.
- Fix issues introduced by your changes and repeat verification until successful.
- Report what was changed, tested, and any remaining limitations.

## 5. GitHub CLI

GitHub CLI (`gh`) is available for repository management and GitHub operations.

Useful commands:

```bash
gh --help
gh issue list
gh issue create --label bug
```

Prefer `gh` for GitHub issues, pull requests, and repository operations when appropriate. Check command help before using unfamiliar options.
