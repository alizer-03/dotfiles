# Comportement du shell
setopt autocd
setopt no_beep                 # désactive le bip du terminal (complétion invalide, etc.)
setopt auto_pushd              # empile les dossiers visités (cd - <Tab> pour y revenir)
setopt pushd_ignore_dups       # n'empile pas un dossier déjà présent dans la pile
setopt extended_glob          # active #, ~, ^ comme opérateurs de motif (ex. exclusion avec ~)
setopt interactive_comments   # autorise les commentaires (#) en ligne de commande interactive
stty stop undef                # désactive le gel du terminal sur Ctrl+S (flow control natif)
# Historique — macOS en définit un minimal par défaut (/etc/zshrc) ; explicité
# et élargi ici pour que le repo reste portable sur une machine neuve
HISTFILE="$HOME/.zsh_history"
HISTSIZE=5000
SAVEHIST=5000
setopt share_history          # historique partagé en temps réel entre panneaux/sessions
setopt hist_ignore_all_dups   # pas de doublons dans l'historique
setopt hist_save_no_dups      # pas de doublons sauvegardés sur disque
setopt hist_reduce_blanks     # nettoie les espaces superflus avant sauvegarde
setopt hist_ignore_space      # une commande tapée avec un espace au début n'est pas enregistrée
# Complétion
autoload -Uz compinit
compinit
_comp_options+=(globdots)                                    # propose aussi les dotfiles en complétion — sans (contrairement à `setopt globdots`) élargir le comportement des globs dans les commandes réelles (ex. `rm *`)
zstyle ':completion:*' menu select                          # navigation au clavier dans le menu de complétion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'    # tolérance à la casse en tapant
zstyle ':completion:*' special-dirs true   # propose aussi ".." dans le menu de complétion
setopt auto_param_slash                    # complète un dossier avec "/" plutôt qu'un espace
# Starship
eval "$(starship init zsh)"
# Outils
eval "$(zoxide init zsh --cmd cd)"           # remplace directement `cd` (pas une commande séparée `z`)
source <(fzf --zsh)                          # Alt+C / Ctrl+T (fzf)
eval "$(atuin init zsh --disable-up-arrow)"  # Ctrl+R : repris par atuin (fzf le définit avant, volontairement écrasé)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
export FZF_DEFAULT_OPTS=" \
--color=bg+:#2f334d,bg:#222436,spinner:#ffc777,hl:#ff966c \
--color=fg:#c8d3f5,header:#4fd6be,info:#0db9d7,pointer:#c099ff \
--color=marker:#c3e88d,fg+:#c8d3f5,prompt:#82aaff,hl+:#ff966c"      # palette tokyonight-moon, reprise du thème nvim
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/rgrc"
# Éditeur par défaut (outils CLI : git commit sans -m, crontab -e, etc.)
export EDITOR='nvim'
export VISUAL='nvim'
autoload -Uz edit-command-line   # édite la commande en cours dans $EDITOR avant exécution
zle -N edit-command-line
bindkey '^Xe' edit-command-line
# Navigation
cx() { cd "$1" && ll; }
f() { fd -t f | fzf | tr -d '\n' | pbcopy }   # copie le chemin choisi dans le presse-papiers
mkcd() { mkdir -p "$1" && cd "$1"; }
source ~/dotfiles/scripts/fzf-git.sh   # Ctrl+G puis f/b/t/h/s/r... : insère un objet Git (branche, commit, fichier...) choisi via fzf dans la ligne en cours
alias nzo="~/dotfiles/scripts/zoxide-open-nvim.sh"   # trouve un fichier (dossier courant, ou motif dans tes dossiers zoxide) et l'ouvre direct dans nvim
# Aliases — fichiers
alias ls='eza --git --group-directories-first --icons=auto'
alias ll='eza -la --git --group-directories-first --icons=auto'
alias lt='eza --tree --level=2 --icons=auto --git-ignore -I ".git"'
alias mv='mv -i'
alias sz='source ~/.zshrc'
alias c='clear'
alias cat='bat'
alias man='batman'
alias lg='lazygit'
alias y='yazi'
alias v='nvim'
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
# Aliases — C
alias wcc="cc -Wall -Wextra -Werror"
# Aide rapide (tldr puis man en secours)
help() {
	tldr "$1" 2>/dev/null || batman "$1"
}
# Plugins
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
