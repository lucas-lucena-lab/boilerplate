# Install prompt

You are an AI agent with filesystem access, running on the machine that is
being set up. This file replaces `install.sh` and `install.ps1`. Read it fully,
then perform the install yourself.

You are here because a script cannot do this job. A script appends, overwrites,
or creates. It cannot tell a default it is allowed to change from a local
decision it must keep. **You can, so the standard is higher: nothing the user
wrote may be lost, and nothing you cannot explain may be changed.**

## The contract

After you are done, all of the following must be true.

1. Every default in this repository is in effect on this machine.
2. Every local customisation that does not conflict with a default still
   exists, byte for byte where possible.
3. Anything you replaced is recoverable, and you told the user where it is.
4. Re-running this prompt changes nothing and says so.
5. No credential, token, or trust setting was copied, moved, or invented.

If you cannot satisfy all five for a file, **stop and ask**. Do not proceed on a
guess. A half-installed config the user does not know about is worse than no
install.

## What ships here

| Source | Destination | Method |
| --- | --- | --- |
| `codex/AGENTS.md` | `~/.codex/AGENTS.md` | link or copy |
| `codex/config.toml` | `~/.codex/config.toml` | **merge keys** |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | link or copy |
| `claude/settings.json` | `~/.claude/settings.json` | **merge keys** |
| `claude/output-styles/*.md` | `~/.claude/output-styles/` | link or copy |
| `grok/AGENTS.md` | `~/.grok/AGENTS.md` | link or copy |
| `copilot/copilot-instructions.md` | `~/.copilot/copilot-instructions.md` | link or copy |

Symlink on macOS and Linux. Copy on Windows, so the install needs neither
Administrator nor Developer Mode.

## Before you change anything

Read the current state of every destination and say what you found. For each
one, establish which of these it is, because the correct action differs:

- **Absent.** Create it. Nothing to preserve.
- **A symlink into this repo.** Already installed. Leave it.
- **A symlink somewhere else.** Report the target. Read that file: if it holds
  content this repo does not have, you are about to unlink the user's own
  setup. Say so and follow the merge rule for its type.
- **A regular file.** Merge or back up, per the rules below.

## Merge rules

### Instruction files (`AGENTS.md`, `CLAUDE.md`, `copilot-instructions.md`)

These are prose. Diff the existing file against this repo's version.

- Identical, or the repo version is a strict superset: install the repo version.
- The local file has sections, rules, or paragraphs the repo version lacks:
  **that is local content and it wins.** Do not silently replace it. Either
  keep the local file and report exactly which repo rules are missing from it,
  or ask whether to append them. Never drop a rule the user wrote.
- Conflicting versions of the same rule: ask. Do not pick.

Local content is a rule about *this machine* or *this person*, not a stale copy
of a shared default. A section this repo never had is local content.

### `~/.codex/config.toml`

Set only the keys this repo's `codex/config.toml` declares, **at the top level
of the file**, and nothing else.

TOML has tables. A key inside `[profiles.fast]` is a different key from the same
name at the top level. The retired shell script matched key names by line
prefix, so on a config with profiles it did two destructive things at once:

```toml
# before                          # after the old script
model = "gpt-5.6-sol"             model = "gpt-5.6-sol"
personality = "pragmatic"         personality = "pragmatic"

[profiles.fast]                   [profiles.fast]
model_verbosity = "high"          model_verbosity = "low"   # profile overwritten
personality = "concise"                                     # profile DELETED
```

It wrote a global default into a profile and deleted the profile's own key,
while never setting the top-level key it was asked to set. **Parse the TOML.
Do not pattern-match lines.** Leave every table, every profile, every
`[projects."…"]` trust entry and every comment exactly as it was.

If a key this repo declares already has a different value at the top level, that
is a real conflict: report the current value and the repo value, and ask.

### `~/.claude/settings.json`

Set only `outputStyle`. Everything else in that file is machine-local:
permissions, model, effort level, plugins, marketplaces, hooks, env.

**Preserve the file's formatting.** Read it, change the one key, write it back
with the same indentation and key order. Do not round-trip it through a tool
that reformats. `plutil` on macOS minifies the whole file to a single line and
escapes every `/` as `\/`; the data survives and the file stops being editable
by a human, which is the thing a settings file is for.

If the JSON is invalid, stop. Do not rewrite a file you cannot parse.

## Backups

Back up any regular file you replace or rewrite, as `<name>.backup-<timestamp>`
next to it. Preserve the original modification time.

Removing a symlink needs no backup, **as long as you have confirmed its target
file still exists and is not managed by this repo**. Check before you unlink,
and name the target in your report.

## Report

End with a table: one row per destination, what you found, what you did, and the
backup path if there is one. Then state explicitly:

- every default that is now in effect,
- every local customisation you preserved and why you judged it local,
- anything you did not change, and what it would take to change it,
- any file where you stopped and need an answer.

Say what you actually did. Do not report an intention as an outcome. If you
could not write to a path, say which one and why, rather than reporting success
for the rest and leaving the failure implicit.

## Credentials

This repository holds none, installs none, and must never receive any. Log in to
GitHub, Codex, Claude, and Grok separately on every machine. Codex project trust
(`[projects."…"]`) is machine state: never copy it between machines, and never
add an entry the user did not ask for.

## After

Tell the user to start new Codex, Claude, Grok, and Copilot sessions. A running
session has already loaded its instructions and will not see the change.
