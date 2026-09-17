#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="${SELF_CONFIG_BACKUP_ROOT:-$HOME/.self_config-backup}"
STAMP="$(date +%Y%m%d-%H%M%S)"

backup_path() {
  local target="$1"
  local rel="${target#"$HOME"/}"
  local dest="$BACKUP_ROOT/$STAMP/$rel"
  mkdir -p -- "$(dirname -- "$dest")"
  mv -- "$target" "$dest"
  printf 'backed up  %s -> %s\n' "$target" "$dest"
}

link_path() {
  local src="$1" target="$2"
  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    printf 'skip       %s (missing source)\n' "$target"
    return
  fi
  mkdir -p -- "$(dirname -- "$target")"
  if [ -L "$target" ]; then
    if [ "$(readlink -f -- "$target")" = "$(readlink -f -- "$src")" ]; then
      printf 'ok         %s\n' "$target"
      return
    fi
    backup_path "$target"
  elif [ -e "$target" ]; then
    backup_path "$target"
  fi
  ln -s -- "$src" "$target"
  printf 'linked     %s -> %s\n' "$target" "$src"
}

link_path "$REPO_DIR/nvim/.config/nvim" "$HOME/.config/nvim"
link_path "$REPO_DIR/yazi/.config/yazi" "$HOME/.config/yazi"
link_path "$REPO_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
link_path "$REPO_DIR/bin/.local/bin/yazi-copy-text" "$HOME/.local/bin/yazi-copy-text"

chmod +x "$REPO_DIR/bin/.local/bin/yazi-copy-text"

if [ -f "$REPO_DIR/terminfo/kitty.terminfo" ] && command -v tic >/dev/null 2>&1; then
  tic -x "$REPO_DIR/terminfo/kitty.terminfo"
  printf 'installed  kitty terminfo\n'
fi

printf '\ndone. reload tmux with: tmux source-file ~/.tmux.conf\n'
