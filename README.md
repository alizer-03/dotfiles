# dotfiles

Configuration personnelle : Neovim, zsh, tmux, Ghostty, git, Starship, bat, gh, lazygit, yazi, ripgrep.

## Contenu

- `nvim/` — configuration Neovim complète (LSP C/Python/Web, Git, snippets, thème)
- `zsh/.zshrc` — configuration shell (alias, fonctions, plugins)
- `tmux/` — configuration tmux (préfixe, plugins, popups, statusline) et scripts `tmux-sessionizer.sh`/`tmux-file-picker.sh` (navigation rapide via fzf)
- `ghostty/config` — configuration du terminal
- `git/.gitconfig` — configuration git (alias, pager delta, etc.)
- `git/.gitignore_global` — règles d'exclusion git globales (toutes machines)
- `starship/starship.toml` — configuration du prompt
- `bat/config` — thème et pager pour `bat` (remplaçant de `cat`)
- `gh/config.yml` — configuration du CLI GitHub (alias, préférences)
- `lazygit/config.yml` — thème et pager pour l'interface Git en terminal
- `yazi/` — configuration du gestionnaire de fichiers en terminal (thème, raccourcis, flavors)
- `ripgrep/rgrc` — configuration de `rg` (smart-case)
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

# Installe norminette et c_formatter_42 (hors Homebrew, via pipx)
pipx install norminette
pipx install c-formatter-42

mkdir -p ~/.config/bat ~/.config/gh ~/.config/lazygit ~/.config/tmux ~/.config/ripgrep ~/Documents/Code

ln -sf ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/tmux/tmux.conf ~/.config/tmux/tmux.conf
ln -sf ~/dotfiles/ghostty ~/.config/ghostty
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/git/.gitignore_global ~/.gitignore
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/bat/config ~/.config/bat/config
ln -sf ~/dotfiles/gh/config.yml ~/.config/gh/config.yml
ln -sf ~/dotfiles/lazygit/config.yml ~/.config/lazygit/config.yml
ln -sf ~/dotfiles/yazi ~/.config/yazi
ln -sf ~/dotfiles/ripgrep/rgrc ~/.config/ripgrep/rgrc
ln -sf ~/dotfiles/prettier/.prettierrc ~/.prettierrc
ln -sf ~/dotfiles/.editorconfig ~/Documents/Code/.editorconfig

# 42-header.nvim : copie le modèle d'identité et renseigne-y ton login et ton
# email 42 (fichier non suivi par Git, jamais versionné)
cp ~/dotfiles/nvim/lua/core/identity.lua.example ~/dotfiles/nvim/lua/core/identity.lua
# puis édite ~/dotfiles/nvim/lua/core/identity.lua pour renseigner tes identifiants

# bat : le thème n'est pas embarqué nativement, il faut l'installer une fois
mkdir -p ~/.config/bat/themes
curl -o ~/.config/bat/themes/tokyonight_moon.tmTheme https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_moon.tmTheme
bat cache --build
```

> Si `~/.config/nvim` (ou un autre fichier/dossier cible) existe déjà sur la machine, renomme-le ou supprime-le avant de créer le lien symbolique — sinon la commande `ln` échoue silencieusement.

Ouvre ensuite Neovim : `lazy.nvim` installe automatiquement tous les plugins listés dans `nvim/lua/plugins/init.lua`, puis `mason-lspconfig` installe les serveurs LSP (clangd, pyright, ruff, html, cssls, ts_ls, eslint, lua_ls) au premier fichier ouvert du langage correspondant.

Deux étapes manuelles, volontairement laissées hors de ce dépôt :
- **TPM** (gestionnaire de plugins tmux) n'est pas embarqué dans ce dépôt :
```bash
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
  Lance `tmux`, puis `prefix + I` (`Ctrl+a` puis `Shift+i`) pour installer tous les plugins déclarés dans `tmux/tmux.conf`.
- **gh** (CLI GitHub) n'est pas authentifié par ce dépôt — lance `gh auth login` sur la nouvelle machine ; ses identifiants ne sont jamais versionnés.