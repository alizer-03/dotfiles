-- Bootstrap : installe lazy.nvim (le gestionnaire de plugins) s'il n'est pas
-- déjà présent, puis l'ajoute au runtimepath de Neovim pour pouvoir l'utiliser
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none", -- clone partiel : plus rapide, sans l'historique complet
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Touche leader : Espace.
-- Doit être définie AVANT le chargement des plugins : certains d'entre eux
-- déclarent leurs raccourcis (ex. "<leader>ff") au moment où ils se chargent,
-- donc si le leader n'est pas encore défini, ces raccourcis ne fonctionnent pas.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Configuration de base, chargée avant les plugins (options, raccourcis fixes,
-- comportements automatiques). Voir le contenu de chaque fichier pour le détail.
require("core.options")
require("core.autocmds")
require("core.norminette").setup()
require("core.rainbow_var").setup()
require("core.keymaps")

-- Charge tous les plugins déclarés dans lua/plugins/init.lua
require("lazy").setup("plugins", {
	defaults = { lazy = true }, -- par défaut, un plugin ne se charge que si besoin
	checker = { enabled = true }, -- vérifie périodiquement les mises à jour disponibles
	performance = {
		rtp = {
			-- plugins intégrés à Neovim qu'on n'utilise pas, désactivés pour un
			-- démarrage légèrement plus rapide
			disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
		},
	},
})