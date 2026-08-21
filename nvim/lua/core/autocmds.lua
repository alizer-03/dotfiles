local autocmd = vim.api.nvim_create_autocmd

-- Fait clignoter brièvement le texte copié, pour visualiser ce qui vient d'être yanké
autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank({ timeout = 200 })
	end,
})

-- Rouvre un fichier à la dernière ligne éditée plutôt qu'à la ligne 1
autocmd("BufReadPost", {
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			vim.api.nvim_win_set_cursor(0, mark)
			vim.schedule(function()
				vim.cmd("normal! zz")
			end)
		end
	end,
})

-- Retire automatiquement les espaces en fin de ligne à chaque sauvegarde
-- (sauf en Markdown, où deux espaces en fin de ligne sont un retour à la ligne volontaire)
autocmd("BufWritePre", {
	pattern = "*",
	callback = function()
		if vim.bo.filetype == "markdown" then
			return
		end
		vim.cmd([[%s/\s\+$//e]]) -- le "e" final évite une erreur si aucune espace n'est trouvée
	end,
})

-- Fichiers C/H et Makefile : forcent de vraies tabulations (pas d'espaces), largeur 4.
-- Contrairement au réglage global (voir core/options.lua, expandtab=true), ces filetypes
-- ont besoin de vraies tabulations : normes de style C strictes sur l'indentation pour
-- C/H, syntaxe Make elle-même pour make (un Makefile indenté avec des espaces ne
-- fonctionne pas).
autocmd("FileType", {
	pattern = { "c", "h", "make" },
	callback = function()
		vim.opt_local.expandtab = false
		vim.opt_local.tabstop = 4
		vim.opt_local.shiftwidth = 4
	end,
})