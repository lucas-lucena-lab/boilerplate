# boilerplate

Shared defaults for Codex, Claude Code, Gemini CLI, Kimi Code, Grok Build,
GitHub Copilot CLI, Cursor Agent, and OpenCode on macOS and Windows.

The setup keeps task-completion responses short, direct, and easy to read for
people who use English as a second language. It does not copy authentication,
tokens, project trust, or other machine-specific state.

## Install

There is no install script. [`INSTALL.md`](INSTALL.md) is a prompt: give it to
an AI agent with filesystem access on the machine being set up, and it performs
the install.

Clone the repository, then point your agent at the prompt:

```bash
gh repo clone lucas-lucena-lab/boilerplate ~/Projects/boilerplate
```

```
Read ~/Projects/boilerplate/INSTALL.md and follow it.
```

Windows is the same, with the path spelled `$HOME\Projects\boilerplate`.

Start new harness sessions after installation. A running session has already
loaded its instructions and will not see the change.

### Why a prompt instead of a script

A script appends, overwrites, or creates. It cannot tell a default it is allowed
to change from a local decision it must keep, so it either clobbers your machine
or refuses to touch anything.

The scripts this replaced did both. The TOML merge matched key names by line
prefix, so on a Codex config with profiles it wrote a global default into
`[profiles.fast]`, deleted that profile's own `personality`, and never set the
top-level key it was asked to set. The macOS settings merge round-tripped
`~/.claude/settings.json` through `plutil`, which preserved every value and
minified the file to a single line, escaping every `/` as `\/`. Neither failure
reported anything. Both are named as traps in the prompt.

An agent can read what is already there, judge which parts are yours, and say
what it changed. That is the whole difference.

## What is installed

- `codex/AGENTS.md` becomes `~/.codex/AGENTS.md`.
- The Codex verbosity and personality defaults are merged into
  `~/.codex/config.toml`, at the top level only.
- `claude/CLAUDE.md` becomes `~/.claude/CLAUDE.md`.
- The custom Claude output style is installed under `~/.claude/output-styles/`
  and selected through the `outputStyle` key in `~/.claude/settings.json`.
- `grok/AGENTS.md` becomes `~/.grok/AGENTS.md`.
- `copilot/copilot-instructions.md` becomes `~/.copilot/copilot-instructions.md`
  and applies to every model selected in Copilot CLI.
- `gemini/GEMINI.md` becomes `~/.gemini/GEMINI.md`.
- `kimi/SYSTEM.md` becomes `~/.kimi-code/SYSTEM.md`. It keeps Kimi's built-in
  system prompt and adds the shared defaults.
- `cursor/rules/shared-defaults.mdc` becomes an always-applied global rule at
  `~/.cursor/rules/shared-defaults.mdc`.
- `opencode/AGENTS.md` becomes `~/.config/opencode/AGENTS.md`.

Instruction files are symlinked on macOS and Linux, and copied on Windows so the
install needs neither Administrator nor Developer Mode. Only the keys listed
above are touched in the two settings files. Everything else in them is
machine-local and is preserved: permissions, model, effort level, plugins,
hooks, and Codex project trust.

Existing files are backed up before they are replaced, and the agent reports
where. A local customisation the repository does not have is treated as yours:
the prompt requires the agent to keep it and say which shared rules are missing,
rather than replacing it.

The repository is a static source of configuration, so it does not need a
background process. Dev Utils can verify the checkout and installed files
without changing them.

## Update an existing machine

```bash
git -C ~/Projects/boilerplate pull --ff-only
```

Instruction files are symlinks, so on macOS and Linux the pull is the update.
Run the prompt again when the settings keys change, or on Windows where the
files are copies. It is idempotent: a second run reports that everything is
already in place and changes nothing.

## Credentials

Log in to GitHub and each harness separately on every machine. Credentials must
never be added to this repository. Codex project trust is machine state and is
never copied between machines.
