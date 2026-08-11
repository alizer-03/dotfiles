# dotfiles

Configuration personnelle : Neovim, zsh, Ghostty, git, Starship, AeroSpace, bat, gh, lazygit, yazi.

## Contenu

- `nvim/` — configuration Neovim complète (LSP C/Python/Web, Git, snippets, thème)
- `zsh/.zshrc` — configuration shell (alias, fonctions, plugins)
- `ghostty/config` — configuration du terminal
- `git/.gitconfig` — configuration git (alias, pager delta, etc.)
- `git/.gitignore_global` — règles d'exclusion git globales (toutes machines)
- `starship/starship.toml` — configuration du prompt
- `aerospace/aerospace.toml` — gestionnaire de fenêtres en tuiles (workspaces, raccourcis clavier)
- `bat/config` — thème et pager pour `bat` (remplaçant de `cat`)
- `gh/config.yml` — configuration du CLI GitHub (alias, préférences)
- `lazygit/config.yml` — thème et pager pour l'interface Git en terminal
- `yazi/` — configuration du gestionnaire de fichiers en terminal (thème, raccourcis, flavors)
- `prettier/.prettierrc` — règles de formatage JS/CSS/HTML
- `.editorconfig` — règles d'indentation partagées entre éditeurs (tabs pour C/Makefile)
- `Brewfile` — liste des outils et applications installés via Homebrew

## Installation sur une nouvelle machine

Prérequis : [Homebrew](https://brew.sh).

```bash
git clone https://github.com/<ton-user>/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Installe tous les outils et applications listés dans Brewfile
brew bundle install

# Installe norminette (hors Homebrew, via pipx)
pipx install norminette

mkdir -p ~/.config/aerospace ~/.config/bat ~/.config/gh ~/.config/lazygit ~/Documents/Code

ln -sf ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/ghostty ~/.config/ghostty
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/git/.gitignore_global ~/.gitignore
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/aerospace/aerospace.toml ~/.config/aerospace/aerospace.toml
ln -sf ~/dotfiles/bat/config ~/.config/bat/config
ln -sf ~/dotfiles/gh/config.yml ~/.config/gh/config.yml
ln -sf ~/dotfiles/lazygit/config.yml ~/.config/lazygit/config.yml
ln -sf ~/dotfiles/yazi ~/.config/yazi
ln -sf ~/dotfiles/prettier/.prettierrc ~/.prettierrc
ln -sf ~/dotfiles/.editorconfig ~/Documents/Code/.editorconfig
```

> Si `~/.config/nvim` (ou un autre fichier/dossier cible) existe déjà sur la machine, renomme-le ou supprime-le avant de créer le lien symbolique — sinon la commande `ln` échoue silencieusement.

Ouvre ensuite Neovim : `lazy.nvim` installe automatiquement tous les plugins listés dans `nvim/lua/plugins/init.lua`, puis `mason-lspconfig` installe les serveurs LSP (clangd, pyright, ruff, html, cssls, ts_ls, eslint) au premier fichier ouvert du langage correspondant.

Deux étapes manuelles, volontairement laissées hors de ce dépôt :
- **AeroSpace** demande l'autorisation d'accessibilité macOS au premier lancement (*Réglages Système → Confidentialité et sécurité → Accessibilité*).
- **gh** (CLI GitHub) n'est pas authentifié par ce dépôt — lance `gh auth login` sur la nouvelle machine ; ses identifiants ne sont jamais versionnés.
