# dotfiles

Shared Codex and Claude Code defaults for macOS.

The setup keeps task-completion responses short, direct, and easy to read for
people who use English as a second language. It does not copy authentication,
tokens, project trust, or other machine-specific state.

## Install on a new machine

Install and authenticate GitHub CLI, then run:

```bash
mkdir -p ~/projects
gh repo clone lucas-lucena-lab/dotfiles ~/projects/dotfiles
~/projects/dotfiles/install.sh
```

Start new Codex and Claude sessions after installation.

## What is installed

- `codex/AGENTS.md` is linked to `~/.codex/AGENTS.md`.
- The Codex verbosity and personality defaults are merged into
  `~/.codex/config.toml`.
- `claude/CLAUDE.md` is linked to `~/.claude/CLAUDE.md`.
- The custom Claude output style is linked under
  `~/.claude/output-styles/` and selected in `~/.claude/settings.json`.

Existing instruction files are backed up before they are replaced. Existing
Codex and Claude settings are preserved; the installer changes only the keys
tracked in this repository.

## Update an existing machine

```bash
git -C ~/projects/dotfiles pull --ff-only
~/projects/dotfiles/install.sh
```

The installer is idempotent, so it is safe to run again.

## Credentials

Log in to GitHub, Codex, and Claude separately on every machine. Credentials
must never be added to this repository.
