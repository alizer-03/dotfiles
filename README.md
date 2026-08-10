# dotfiles

Configuration personnelle : Neovim, zsh, Ghostty, git, Starship.

## Contenu

- `nvim/` — configuration Neovim complète (LSP C/Python/Web, Git, snippets, thème)
- `zsh/.zshrc` — configuration shell (alias, fonctions, plugins)
- `ghostty/config` — configuration du terminal
- `git/.gitconfig` — configuration git (alias, pager delta, etc.)
- `git/.gitignore_global` — règles d'exclusion git globales (toutes machines)
- `starship/starship.toml` — configuration du prompt
- `.editorconfig` — règles d'indentation partagées entre éditeurs (tabs pour C/Makefile)
- `Brewfile` — liste des outils et applications installés via Homebrew

## Installation sur une nouvelle machine

Prérequis : [Homebrew](https://brew.sh).

\`\`\`bash
git clone https://github.com/<ton-user>/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Installe tous les outils et applications listés dans Brewfile
brew bundle install

# Installe norminette (hors Homebrew, via pipx)
pipx install norminette

ln -sf ~/dotfiles/nvim ~/.config/nvim
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/ghostty ~/.config/ghostty
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/git/.gitignore_global ~/.gitignore
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/.editorconfig ~/Documents/Code/.editorconfig
\`\`\`

> Si \`~/.config/nvim\` (ou un autre fichier cible) existe déjà sur la machine, renomme-le ou supprime-le avant de créer le lien symbolique — sinon la commande \`ln\` échoue silencieusement.

Ouvre ensuite Neovim : \`lazy.nvim\` installe automatiquement tous les plugins listés dans \`nvim/lua/plugins/init.lua\`, puis \`mason-lspconfig\` installe les serveurs LSP (clangd, pyright, ruff, html, cssls, ts_ls, eslint) au premier fichier ouvert du langage correspondant.
