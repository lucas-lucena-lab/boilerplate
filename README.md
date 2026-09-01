# boilerplate

Shared defaults for Codex, Claude Code, Grok Build, and GitHub Copilot CLI on
macOS and Windows.

The setup keeps task-completion responses short, direct, and easy to read for
people who use English as a second language. It does not copy authentication,
tokens, project trust, or other machine-specific state.

## Install on macOS

Install and authenticate GitHub CLI, then run:

```bash
mkdir -p ~/projects
gh repo clone lucas-lucena-lab/boilerplate ~/projects/boilerplate
~/projects/boilerplate/install.sh
```

Start new Codex, Claude, Grok, and Copilot sessions after installation.

## Install on Windows

Open PowerShell, install and authenticate GitHub CLI, then run:

```powershell
New-Item -ItemType Directory -Force -Path "$HOME\projects" | Out-Null
gh repo clone lucas-lucena-lab/boilerplate "$HOME\projects\boilerplate"
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\projects\boilerplate\install.ps1"
```

`ExecutionPolicy Bypass` applies only to that PowerShell process. It does not
change the system execution policy.

## What is installed

- `codex/AGENTS.md` is installed as `~/.codex/AGENTS.md`.
- The Codex verbosity and personality defaults are merged into
  `~/.codex/config.toml`.
- `claude/CLAUDE.md` is installed as `~/.claude/CLAUDE.md`.
- The custom Claude output style is installed under
  `~/.claude/output-styles/` and selected in `~/.claude/settings.json`.
- `grok/AGENTS.md` is installed as `~/.grok/AGENTS.md`.
- `copilot/copilot-instructions.md` is installed as
  `~/.copilot/copilot-instructions.md` and applies to every model selected in
  Copilot CLI.

Existing instruction files are backed up before they are replaced. Existing
settings are preserved; the installer changes only the keys tracked in this
repository. The macOS installer uses symbolic links for the instruction files.
The Windows installer copies them, so it works without Administrator access or
Developer Mode.

## Update an existing machine

```bash
git -C ~/projects/boilerplate pull --ff-only
~/projects/boilerplate/install.sh
```

On Windows:

```powershell
git -C "$HOME\projects\boilerplate" pull --ff-only
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\projects\boilerplate\install.ps1"
```

The installer is idempotent, so it is safe to run again.

## Credentials

Log in to GitHub, Codex, Claude, and Grok separately on every machine.
Credentials must never be added to this repository.
