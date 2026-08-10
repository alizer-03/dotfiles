-- Raccourcis liés au LSP (ici Lspsaga), définis uniquement sur les buffers où
-- un client LSP est réellement attaché — pas de raccourcis fantômes sur un
-- fichier texte quelconque où il n'y aurait rien à faire.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-keymaps", { clear = true }),
	callback = function(args)
		local bufnr = args.buf

		-- petit raccourci local pour éviter de répéter { buffer = bufnr, ... } à chaque ligne
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
		end

		map("n", "<leader>lo", "<cmd>Lspsaga outline<cr>", "Arbre des symboles")
		map("n", "<leader>lf", "<cmd>Lspsaga finder<cr>", "Références et définitions")
		map("n", "<leader>lc", "<cmd>Lspsaga code_action<cr>", "Actions de code")
		map("n", "<leader>lr", "<cmd>Lspsaga rename<cr>", "Renommer")
	end,
})