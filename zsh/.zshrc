# Comportement du shell
setopt autocd
setopt globdots
stty stop undef
# Complétion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# Starship
eval "$(starship init zsh)"
# Outils
eval "$(zoxide init zsh --cmd cd)"
source <(fzf --zsh)
eval "$(atuin init zsh --disable-up-arrow)"
export FZF_DEFAULT_COMMAND='fd --type f --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS=" \
--color=bg+:#2f334d,bg:#222436,spinner:#ffc777,hl:#ff966c \
--color=fg:#c8d3f5,header:#4fd6be,info:#0db9d7,pointer:#c099ff \
--color=marker:#c3e88d,fg+:#c8d3f5,prompt:#82aaff,hl+:#ff966c"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rgrc"
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
alias mv='mv -i'
alias sz='source ~/.zshrc'
alias c='clear'
alias cat='bat'
alias lg='lazygit'
alias y='yazi'
alias v='nvim'
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