local autocmd = vim.api.nvim_create_autocmd

-- Fait clignoter brièvement le texte copié, pour visualiser ce qui vient d'être yanké
autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ timeout = 200 })
	end,
})

-- Retire automatiquement les espaces en fin de ligne à chaque sauvegarde
autocmd("BufWritePre", {
	pattern = "*",
	command = [[%s/\s\+$//e]], -- le "e" final évite une erreur si aucune espace n'est trouvée
})

-- Fichiers C/H : force de vraies tabulations (pas d'espaces), largeur 4.
-- Contrairement au réglage global (voir core/options.lua, expandtab=true),
-- ces filetypes ont besoin de vraies tabulations pour respecter certaines
-- normes de style C strictes sur l'indentation.
autocmd("FileType", {
	pattern = { "c", "h" },
	callback = function()
		vim.opt_local.expandtab = false
		vim.opt_local.tabstop = 4
		vim.opt_local.shiftwidth = 4
	end,
})

-- Makefile : tabulations obligatoires (syntaxe Make elle-même, indépendamment
-- de toute norme de style — un Makefile indenté avec des espaces ne fonctionne pas)
autocmd("FileType", {
	pattern = "make",
	callback = function()
		vim.opt_local.expandtab = false
		vim.opt_local.tabstop = 4
		vim.opt_local.shiftwidth = 4
	end,
})