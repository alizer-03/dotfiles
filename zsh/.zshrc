# Starship
eval "$(starship init zsh)"
# Outils
eval "$(zoxide init zsh --cmd cd)"
source <(fzf --zsh)
eval "$(atuin init zsh --disable-up-arrow)"
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
# Éditeur par défaut (outils CLI : git commit sans -m, crontab -e, etc.)
export EDITOR='nvim'
export VISUAL='nvim'
# Navigation
cx() { cd "$1" && ll; }
fcd() { cd "$(fd -t d | fzf)" && ll }
f() { fd -t f | fzf | tr -d '\n' | pbcopy }
# Aliases — fichiers
alias ls='eza --git --group-directories-first --icons=auto'
alias ll='eza -la --git --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --icons=auto --git-ignore -I ".git"'
alias sz='source ~/.zshrc'
alias c='clear'
alias cat='bat'
alias lg='lazygit'
alias y='yazi'
alias ..="cd .."
alias ...="cd ../.."
# Aliases — C
alias wcc="cc -Wall -Wextra -Werror"
# Aide rapide (tldr puis man en secours)
help() {
    tldr "$1" 2>/dev/null || man "$1"
}
# Plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
