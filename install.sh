#!/usr/bin/env bash
# Installs shared Codex and Claude defaults without copying credentials or
# replacing machine-specific settings.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_HOME="${DOTFILES_TARGET_HOME:-$HOME}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

link_file() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" ]]; then
    if [[ "$(readlink "$dst")" == "$src" ]]; then
      echo "ok    $dst -> $src (already linked)"
      return
    fi
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    local backup="$dst.backup-$TIMESTAMP"
    echo "backup $dst -> $backup"
    mv "$dst" "$backup"
  fi

  ln -s "$src" "$dst"
  echo "link   $dst -> $src"
}

set_toml_value() {
  local file="$1"
  local key="$2"
  local value="$3"
  local next
  next="$(mktemp)"

  if grep -Eq "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
    awk -v key="$key" -v value="$value" '
      $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
        if (!updated) {
          print key " = " value
          updated = 1
        }
        next
      }
      { print }
    ' "$file" > "$next"
  else
    {
      printf '%s = %s\n' "$key" "$value"
      cat "$file"
    } > "$next"
  fi

  mv "$next" "$file"
}

merge_toml_defaults() {
  local src="$1"
  local dst="$2"
  local working raw_key raw_value key value backup

  mkdir -p "$(dirname "$dst")"
  if [[ ! -e "$dst" ]]; then
    cp "$src" "$dst"
    echo "copy   $src -> $dst"
    return
  fi

  working="$(mktemp)"
  cp "$dst" "$working"

  while IFS='=' read -r raw_key raw_value; do
    key="$(trim "$raw_key")"
    value="$(trim "$raw_value")"
    [[ -z "$key" || "$key" == \#* ]] && continue

    if [[ ! "$key" =~ ^[A-Za-z0-9_]+$ || -z "$value" ]]; then
      echo "error  unsupported line in $src: $raw_key${raw_value:+=$raw_value}" >&2
      rm "$working"
      return 1
    fi

    set_toml_value "$working" "$key" "$value"
  done < "$src"

  if cmp -s "$working" "$dst"; then
    rm "$working"
    echo "ok     $dst (defaults already set)"
    return
  fi

  backup="$dst.backup-$TIMESTAMP"
  cp -p "$dst" "$backup"
  cp "$working" "$dst"
  rm "$working"
  echo "backup $dst -> $backup"
  echo "merge  $src -> $dst"
}

merge_claude_settings() {
  local src="$1"
  local dst="$2"
  local desired current working backup

  mkdir -p "$(dirname "$dst")"
  if [[ ! -e "$dst" ]]; then
    cp "$src" "$dst"
    echo "copy   $src -> $dst"
    return
  fi

  if ! command -v plutil >/dev/null 2>&1; then
    echo "error  plutil is required to merge $dst safely" >&2
    return 1
  fi

  if ! plutil -convert json -o - "$src" >/dev/null || \
     ! plutil -convert json -o - "$dst" >/dev/null; then
    echo "error  cannot merge invalid JSON settings: $dst" >&2
    return 1
  fi

  desired="$(plutil -extract outputStyle raw -o - "$src")"
  current="$(plutil -extract outputStyle raw -o - "$dst" 2>/dev/null || true)"
  if [[ "$current" == "$desired" ]]; then
    echo "ok     $dst (output style already set)"
    return
  fi

  working="$(mktemp)"
  cp "$dst" "$working"
  if ! plutil -replace outputStyle -string "$desired" "$working" 2>/dev/null; then
    plutil -insert outputStyle -string "$desired" "$working"
  fi

  backup="$dst.backup-$TIMESTAMP"
  cp -p "$dst" "$backup"
  cp "$working" "$dst"
  rm "$working"
  echo "backup $dst -> $backup"
  echo "merge  $src -> $dst"
}

merge_toml_defaults "$DOTFILES/codex/config.toml" "$TARGET_HOME/.codex/config.toml"
merge_claude_settings "$DOTFILES/claude/settings.json" "$TARGET_HOME/.claude/settings.json"

link_file "$DOTFILES/codex/AGENTS.md" "$TARGET_HOME/.codex/AGENTS.md"
link_file "$DOTFILES/claude/CLAUDE.md" "$TARGET_HOME/.claude/CLAUDE.md"
link_file \
  "$DOTFILES/claude/output-styles/clear-concise-english.md" \
  "$TARGET_HOME/.claude/output-styles/clear-concise-english.md"

echo "done. Start new Codex and Claude sessions to load the defaults."
