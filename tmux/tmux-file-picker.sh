#!/usr/bin/env bash
set -euo pipefail

pane_dir=$(tmux display-message -p '#{pane_current_path}')
pane_id=$(tmux display-message -p '#{pane_id}')
pane_pid=$(tmux display-message -p '#{pane_pid}')

# Détecte un agent IA en cours dans ce panneau (Claude Code, Codex)
ai_mode=false
pgrep -P "$pane_pid" -f "claude|codex" >/dev/null && ai_mode=true

git_root=$(cd "$pane_dir" && git rev-parse --show-toplevel 2>/dev/null || echo "$pane_dir")

selected=$(
  cd "$git_root" && fd --type f --hidden --follow --exclude .git | \
    fzf --multi --height 100% --preview "bat --style=numbers --color=always {}"
)

[ -z "$selected" ] && exit 0

output=""
if $ai_mode; then
  while IFS= read -r file; do
    output+="@$file "
  done <<< "$selected"
else
  while IFS= read -r file; do
    output+=$(printf '%q ' "$file")
  done <<< "$selected"
fi

tmux send-keys -t "$pane_id" "$output"
