local opt = vim.opt
local g = vim.g

-- Apparence
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"

-- Comportement
opt.mouse = "a"
opt.completeopt = { "menu", "menuone", "noselect" }
opt.updatetime = 300
opt.timeoutlen = 700
opt.autoread = true -- recharge un fichier modifié en dehors de Neovim (git pull/checkout, etc.) au lieu d'avertir

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- Recherche
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Fichiers de sauvegarde/undo, rangés à part plutôt qu'à côté du fichier édité
opt.swapfile = true
opt.backup = true
opt.writebackup = true
opt.undofile = true
opt.backupdir = vim.fn.expand("~/.logs/nvim/backup")
opt.directory = vim.fn.expand("~/.logs/nvim/swap")
opt.undodir = vim.fn.expand("~/.logs/nvim/undo")

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Défilement
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Identité utilisée par le header généré automatiquement (voir 42-header.nvim
-- dans plugins/init.lua). Les vraies valeurs vivent dans core/identity.lua,
-- un fichier local non suivi par git (voir core/identity.lua.example pour le
-- modèle) — si ce fichier n'existe pas encore, on retombe sur des valeurs
-- vides plutôt que de faire planter Neovim.
--
-- Important : on assigne à vim.g.user / vim.g.mail (sans "42") — ce sont les
-- noms exacts que 42-header.nvim lit en priorité maximale, avant même les
-- variables d'environnement système (qui sinon écraseraient silencieusement
-- notre configuration avec le nom de session macOS).
local ok, identity = pcall(require, "core.identity")
g.user = ok and identity.user42 or ""
g.mail = ok and identity.mail42 or ""