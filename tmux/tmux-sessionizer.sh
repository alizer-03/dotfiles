#!/usr/bin/env bash
set -euo pipefail

# Répertoires scannés par défaut : tes projets (2 niveaux de profondeur) + dotfiles.
# Surchargeable : export TMUX_SESSIONIZER_PATHS="~/autre/chemin:1 ~/encore"
paths="${TMUX_SESSIONIZER_PATHS:-$HOME/Documents/Code:2 $HOME/dotfiles:0}"
default_depth="${TMUX_SESSIONIZER_DEPTH:-1}"

expand_tilde() { echo "${1/#~/$HOME}"; }

selected=$(
  {
    tmux list-sessions -F '[TMUX] #{session_name}' 2>/dev/null || true

    for entry in $paths; do
      [[ "$entry" =~ ^([^:]+):([0-9]+)$ ]] && path="${BASH_REMATCH[1]}" depth="${BASH_REMATCH[2]}" || { path="$entry"; depth="$default_depth"; }
      path=$(expand_tilde "$path")
      for expanded in $path; do
        [ -d "$expanded" ] || continue
        find "$expanded" -mindepth 1 -maxdepth "$depth" -type d | sed "s|^$HOME|~|"
      done
    done
  } | fzf --height 100%
)

[ -z "$selected" ] && exit 0
selected=$(expand_tilde "$selected")

if [[ "$selected" =~ ^\[TMUX\]\ (.+)$ ]]; then
  sess="${BASH_REMATCH[1]}"
  [ -z "${TMUX:-}" ] && tmux attach -t "$sess" || tmux switch-client -t "$sess"
  exit 0
fi

sess=$(basename "$selected")
if [ -z "${TMUX:-}" ]; then
  tmux has-session -t "$sess" 2>/dev/null || tmux new-session -ds "$sess" -c "$selected"
  tmux attach -t "$sess"
else
  tmux has-session -t "$sess" 2>/dev/null || tmux new-session -ds "$sess" -c "$selected"
  tmux switch-client -t "$sess"
fi