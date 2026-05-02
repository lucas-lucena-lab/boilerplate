#!/usr/bin/env bash
# Symlinks tracked dotfiles into their expected locations.
# Idempotent: safe to re-run. Backs up existing real files (not symlinks)
# to <path>.backup-<timestamp> before replacing.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

link() {
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

link "$DOTFILES/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo "done."
