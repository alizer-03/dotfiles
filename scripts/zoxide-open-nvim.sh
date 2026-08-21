#!/usr/bin/env bash
set -euo pipefail

# Ouvre directement un fichier dans Neovim, sans avoir à "cd" dedans au
# préalable. Sans argument : cherche dans le dossier courant. Avec un
# argument : cherche ce motif dans tous les dossiers connus de zoxide
# (alias "nzo" dans zsh/.zshrc).

if [ -z "${1:-}" ]; then
	roots=(".")
else
	mapfile -t roots < <(zoxide query -l)
fi

file="$(fd --type f --hidden --exclude .git "${1:-}" "${roots[@]}" 2>/dev/null \
	| fzf --height=70% --preview 'bat --style=numbers --color=always --line-range :200 {}')"

[ -n "$file" ] && nvim "$file"
